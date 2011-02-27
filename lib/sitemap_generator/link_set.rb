require 'builder'
require 'action_view'

# A LinkSet provisions a bunch of links to sitemap files.  It also writes the index file
# which lists all the sitemap files written.
module SitemapGenerator
  class LinkSet
    include ActionView::Helpers::NumberHelper  # for number_with_delimiter

    attr_reader :default_host, :public_path, :sitemaps_path, :filename
    attr_accessor :sitemap, :sitemap_index
    attr_accessor :verbose, :yahoo_app_id

    # Evaluate the sitemap config file and write all sitemaps.
    #
    # The Sitemap Interpreter includes the URL helpers and API methods
    # that the block argument to `add_links` is evaluted within.
    #
    # TODO: Refactor so that we can have multiple instances
    # of LinkSet.
    def create(&block)
      require 'sitemap_generator/interpreter'

      start_time = Time.now
      if self.sitemap_index.finalized?
        self.sitemap_index = SitemapGenerator::Builder::SitemapIndexFile.new(@public_path, sitemap_index_path)
        self.sitemap = SitemapGenerator::Builder::SitemapFile.new(@public_path, new_sitemap_path)
      end

      SitemapGenerator::Interpreter.new(self, &block)
      unless self.sitemap.finalized?
        self.sitemap_index.add(self.sitemap)
        puts self.sitemap.summary if verbose
      end
      self.sitemap_index.finalize!
      end_time = Time.now

      if verbose
        puts self.sitemap_index.summary
        puts "\nSitemap stats: #{number_with_delimiter(self.sitemap_index.total_link_count)} links / #{self.sitemap_index.sitemaps.size} sitemaps / " +
              ("%dm%02ds" % (end_time - start_time).divmod(60))
      end
    end

    # Constructor
    #
    # <tt>public_path</tt> (optional) full path to the directory to write sitemaps in.
    #   Defaults to your Rails <tt>public/</tt> directory.
    #
    # <tt>sitemaps_path</tt> (optional) path fragment within public to write sitemaps
    #   to e.g. 'en/'.  Sitemaps are written to <tt>public_path</tt> + <tt>sitemaps_path</tt>
    #
    # <tt>default_host</tt> hostname including protocol to use in all sitemap links
    #   e.g. http://en.google.ca
    #
    # <tt>filename</tt> used in the name of the file like "#{@filename}1.xml.gzip" and "#{@filename}_index.xml.gzip"
    #   Defaults to <tt>sitemap</tt>
    def initialize(public_path = nil, sitemaps_path = nil, default_host = nil, filename = 'sitemap')
      @default_host = default_host
      @public_path = public_path
      @sitemaps_path = sitemaps_path
      @filename = filename

      if @public_path.nil?
        @public_path = File.join(::Rails.root, 'public/') rescue 'public/'
      end

      # Default host is not set yet.  Set it on these objects when `add_links` is called
      self.sitemap_index = SitemapGenerator::Builder::SitemapIndexFile.new(@public_path, sitemap_index_path)
      self.sitemap = SitemapGenerator::Builder::SitemapFile.new(@public_path, new_sitemap_path)
    end

    # Entry point for users.
    #
    # Called within the user's eval'ed sitemap config file.  Add links to sitemap files
    # passing a block.
    #
    # TODO: Refactor.  The call chain is confusing and convoluted here.
    def add_links
      raise ArgumentError, "Default hostname not set" if default_host.blank?

      # Set default host on the sitemap objects and seed the sitemap with the default links
      self.sitemap.hostname = self.sitemap_index.hostname = default_host
      self.sitemap.add('/', :lastmod => Time.now, :changefreq => 'always', :priority => 1.0)
      self.sitemap.add(self.sitemap_index, :lastmod => Time.now, :changefreq => 'always', :priority => 1.0)

      yield self
    end

    # Add a link to a Sitemap.  If a new Sitemap is required, one will be created for
    # you.
    def add(link, options={})
      begin
        self.sitemap.add(link, options)
      rescue SitemapGenerator::SitemapError => e
        if e.is_a?(SitemapGenerator::SitemapFullError)
          self.sitemap_index.add(self.sitemap)
          puts self.sitemap.summary if verbose
        end
        self.sitemap = SitemapGenerator::Builder::SitemapFile.new(public_path, new_sitemap_path, default_host)
        retry
      end
    end

    # Ping search engines.
    #
    # @see http://en.wikipedia.org/wiki/Sitemap_index
    def ping_search_engines
      require 'open-uri'

      sitemap_index_url = CGI.escape(self.sitemap_index.full_url)
      search_engines = {
        :google         => "http://www.google.com/webmasters/sitemaps/ping?sitemap=#{sitemap_index_url}",
        :yahoo          => "http://search.yahooapis.com/SiteExplorerService/V1/ping?sitemap=#{sitemap_index_url}&appid=#{yahoo_app_id}",
        :ask            => "http://submissions.ask.com/ping?sitemap=#{sitemap_index_url}",
        :bing           => "http://www.bing.com/webmaster/ping.aspx?siteMap=#{sitemap_index_url}",
        :sitemap_writer => "http://www.sitemapwriter.com/notify.php?crawler=all&url=#{sitemap_index_url}"
      }

      puts "\n" if verbose
      search_engines.each do |engine, link|
        next if engine == :yahoo && !self.yahoo_app_id
        begin
          open(link)
          puts "Successful ping of #{engine.to_s.titleize}" if verbose
        rescue Timeout::Error, StandardError => e
          puts "Ping failed for #{engine.to_s.titleize}: #{e.inspect} (URL #{link})" if verbose
        end
      end

      if !self.yahoo_app_id && verbose
        puts "\n"
        puts <<-END.gsub(/^\s+/, '')
          To ping Yahoo you require a Yahoo AppID.  Add it to your config/sitemap.rb with:

          SitemapGenerator::Sitemap.yahoo_app_id = "my_app_id"

          For more information see http://developer.yahoo.com/search/siteexplorer/V1/updateNotification.html
        END
      end
    end

    def link_count
      self.sitemap_index.total_link_count
    end

    def default_host=(value)
      @default_host = value
      self.sitemap_index.hostname = value unless self.sitemap_index.finalized?
      self.sitemap.hostname = value unless self.sitemap.finalized?
    end

    def public_path=(value)
      @public_path = value
      self.sitemap_index.public_path = value unless self.sitemap_index.finalized?
      self.sitemap.public_path = value unless self.sitemap.finalized?
    end

    def sitemaps_path=(value)
      @sitemaps_path = value
      self.sitemap_index.sitemap_path = sitemap_index_path unless self.sitemap_index.finalized?
      self.sitemap.sitemap_path = new_sitemap_path unless self.sitemap.finalized?
    end
    
    def filename=(value)
      @filename = value
      self.sitemap_index.sitemap_path = sitemap_index_path unless self.sitemap_index.finalized?
      self.sitemap.sitemap_path = new_sitemap_path unless self.sitemap.finalized?
    end

    protected

    # Return the current sitemap filename with index.
    #
    # The index depends on the length of the <tt>sitemaps</tt> array.
    def new_sitemap_path
      File.join(self.sitemaps_path || '', "#{@filename}#{self.sitemap_index.sitemaps.length + 1}.xml.gz")
    end

    # Return the current sitemap index filename.
    #
    # At the moment we only support one index file which can link to
    # up to 50,000 sitemap files.
    def sitemap_index_path
      File.join(self.sitemaps_path || '', "#{@filename}_index.xml.gz")
    end
  end
end