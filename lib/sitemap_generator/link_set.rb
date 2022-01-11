require 'builder'

# A LinkSet provisions a bunch of links to sitemap files.  It also writes the index file
# which lists all the sitemap files written.
module SitemapGenerator
  class LinkSet
    @@requires_finalization_opts = [:filename, :sitemaps_path, :sitemaps_host, :namer]
    @@new_location_opts = [:filename, :sitemaps_path, :namer]

    attr_reader :default_host, :sitemaps_path, :filename, :create_index
    attr_accessor :include_root, :include_index, :adapter, :yield_sitemap, :max_sitemap_links
    attr_writer :verbose

    # Create a new sitemap index and sitemap files.  Pass a block with calls to the following
    # methods:
    # * +add+   - Add a link to the current sitemap
    # * +group+ - Start a new group of sitemaps
    #
    # == Options
    #
    # Any option supported by +new+ can be passed.  The options will be
    # set on the instance using the accessor methods.  This is provided mostly
    # as a convenience.
    #
    # In addition to the options to +new+, the following options are supported:
    # * <tt>:finalize</tt> - The sitemaps are written as they get full and at the end
    # of the block.  Pass +false+ as the value to prevent the sitemap or sitemap index
    # from being finalized.  Default is +true+.
    #
    # If you are calling +create+ more than once in your sitemap configuration file,
    # make sure that you set a different +sitemaps_path+ or +filename+ for each call otherwise
    # the sitemaps may be overwritten.
    def create(opts={}, &block)
      reset!
      set_options(opts)
      if verbose
        start_time = Time.now
        puts "In '#{sitemap_index.location.public_path}':"
      end
      interpreter.eval(:yield_sitemap => yield_sitemap?, &block)
      finalize!
      end_time = Time.now if verbose
      output(sitemap_index.stats_summary(:time_taken => end_time - start_time)) if verbose
      self
    end

    # Constructor
    #
    # == Options:
    # * <tt>:adapter</tt> - instance of a class with a write method which takes a SitemapGenerator::Location
    #   and raw XML data and persists it.  The default adapter is a SitemapGenerator::FileAdapter
    #   which simply writes files to the filesystem.  You can use a SitemapGenerator::WaveAdapter
    #   for uploading sitemaps to remote servers - useful for read-only hosts such as Heroku.  Or
    #   you can provide an instance of your own class to provide custom behavior.
    #
    # * <tt>:default_host</tt> - host including protocol to use in all sitemap links
    #   e.g. http://en.google.ca
    #
    # * <tt>:public_path</tt> - Full or relative path to the directory to write sitemaps into.
    #   Defaults to the <tt>public/</tt> directory in your application root directory or
    #   the current working directory.
    #
    # * <tt>:sitemaps_host</tt> - String.  <b>Host including protocol</b> to use when generating
    #   a link to a sitemap file i.e. the hostname of the server where the sitemaps are hosted.
    #   The value will differ from the hostname in your sitemap links.
    #   For example: `'http://amazon.aws.com/'`.
    #
    #   Note that `include_index` is automatically turned off when the `sitemaps_host` does
    #   not match `default_host`.  Because the link to the sitemap index file that would
    #   otherwise be added would point to a different host than the rest of the links in
    #   the sitemap.  Something that the sitemap rules forbid.
    #
    # * <tt>:sitemaps_path</tt> - path fragment within public to write sitemaps
    #   to e.g. 'en/'.  Sitemaps are written to <tt>public_path</tt> + <tt>sitemaps_path</tt>
    #
    # * <tt>:filename</tt> - symbol giving the base name for files (default <tt>:sitemap</tt>).
    #   The names are generated like "#{filename}.xml.gz", "#{filename}1.xml.gz", "#{filename}2.xml.gz"
    #   with the first file being the index if you have more than one sitemap file.
    #
    # * <tt>:include_index</tt> - Boolean.  Whether to <b>add a link pointing to the sitemap index<b>
    #   to the current sitemap.  This points search engines to your Sitemap Index to
    #   include it in the indexing of your site.  Default is `false`.  Turned off when
    #  `sitemaps_host` is set or within a `group()` block.  Turned off because Google can complain
    #   about nested indexing and because if a robot is already reading your sitemap, they
    #   probably know about the index.
    #
    # * <tt>:include_root</tt> - Boolean.  Whether to **add the root** url i.e. '/' to the
    #   current sitemap.  Default is `true`.  Turned off within a `group()` block.
    #
    # * <tt>:search_engines</tt> - Hash.  A hash of search engine names mapped to
    #   ping URLs.  See ping_search_engines.
    #
    # * <tt>:verbose</tt> - If +true+, output a summary line for each sitemap and sitemap
    #   index that is created.  Default is +false+.
    #
    # * <tt>:create_index</tt> - Supported values: `true`, `false`, `:auto`.  Default: `:auto`.
    #   Whether to create a sitemap index file.  If `true` an index file is always created,
    #   regardless of how many links are in your sitemap.  If `false` an index file is never
    #   created.  If `:auto` an index file is created only if your sitemap has more than
    #   one sitemap file.
    #
    # * <tt>:namer</tt> - A <tt>SitemapGenerator::SimpleNamer</tt> instance for generating the sitemap
    #   and index file names.  See <tt>:filename</tt> if you don't need to do anything fancy, and can
    #   accept the default naming conventions.
    #
    # * <tt>:compress</tt> - Specifies which files to compress with gzip.  Default is `true`. Accepted values:
    #     * `true` - Boolean; compress all files.
    #     * `false` - Boolean; write out only uncompressed files.
    #     * `:all_but_first` - Symbol; leave the first file uncompressed but compress any remaining files.
    #
    #   The compression setting applies to groups too.  So :all_but_first will have the same effect (the first
    #   file in the group will not be compressed, the rest will).  So if you require different behaviour for your
    #   groups, pass in a `:compress` option e.g. <tt>group(:compress => false) { add('/link') }</tt>
    #
    # * <tt>:max_sitemap_links</tt> - The maximum number of links to put in each sitemap.
    #   Default is `SitemapGenerator::MAX_SITEMAPS_LINKS`, or 50,000.
    #
    # Note: When adding a new option be sure to include it in `options_for_group()` if
    # the option should be inherited by groups.
    def initialize(options={})
      @default_host, @sitemaps_host, @yield_sitemap, @sitemaps_path, @adapter, @verbose, @protect_index, @sitemap_index, @added_default_links, @created_group, @sitemap = nil

      options = SitemapGenerator::Utilities.reverse_merge(options,
        :include_root => true,
        :include_index => false,
        :filename => :sitemap,
        :search_engines => {
          :google         => "http://www.google.com/webmasters/tools/ping?sitemap=%s",
          :bing           => "http://www.bing.com/webmaster/ping.aspx?sitemap=%s"
        },
        :create_index => :auto,
        :compress => true,
        :max_sitemap_links => SitemapGenerator::MAX_SITEMAP_LINKS
      )
      options.each_pair { |k, v| instance_variable_set("@#{k}".to_sym, v) }

      # If an index is passed in, protect it from modification.
      # Sitemaps can be added to the index but nothing else can be changed.
      if options[:sitemap_index]
        @protect_index = true
      end
    end

    # Add a link to a Sitemap.  If a new Sitemap is required, one will be created for
    # you.
    #
    # link - string link e.g. '/merchant', '/article/1' or whatever.
    # options - see README.
    #   host - host for the link, defaults to your <tt>default_host</tt>.
    def add(link, options={})
      add_default_links if !@added_default_links
      sitemap.add(link, SitemapGenerator::Utilities.reverse_merge(options, :host => @default_host))
    rescue SitemapGenerator::SitemapFullError
      finalize_sitemap!
      retry
    rescue SitemapGenerator::SitemapFinalizedError
      @sitemap = sitemap.new
      retry
    end

    # Add a link to the Sitemap Index.
    # * link - A string link e.g. '/sitemaps/sitemap1.xml.gz' or a SitemapFile instance.
    # * options - A hash of options including `:lastmod`, ':priority`, ':changefreq` and `:host`
    #
    # The `:host` option defaults to the value of `sitemaps_host` which is the host where your
    # sitemaps reside.  If no `sitemaps_host` is set, the `default_host` is used.
    def add_to_index(link, options={})
      sitemap_index.add(link, SitemapGenerator::Utilities.reverse_merge(options, :host => sitemaps_host))
    end

    # Create a new group of sitemap files.
    #
    # Returns a new LinkSet instance with the options passed in set on it.  All groups
    # share the sitemap index, which is not affected by any of the options passed here.
    #
    # === Options
    # Any of the options to LinkSet.new.  Except for <tt>:public_path</tt> which is shared
    # by all groups.
    #
    # The current options are inherited by the new group of sitemaps.  The only exceptions
    # being <tt>:include_index</tt> and <tt>:include_root</tt> which default to +false+.
    #
    # Pass a block to add links to the new LinkSet.  If you pass a block the sitemaps will
    # be finalized when the block returns.
    #
    # If you are not changing any of the location settings like <tt>filename<tt>,
    # <tt>sitemaps_path</tt>, <tt>sitemaps_host</tt> or <tt>namer</tt>,
    # links you add within the group will be added to the current sitemap.
    # Otherwise the current sitemap file is finalized and a new sitemap file started,
    # using the options you specified.
    #
    # Most commonly, you'll want to give the group's files a distinct name using
    # the <tt>filename</tt> option.
    #
    # Options like <tt>:default_host</tt> can be used and it will only affect the links
    # within the group.  Links added outside of the group will revert to the previous
    # +default_host+.
    def group(opts={}, &block)
      @created_group = true
      original_opts = opts.dup

      if (@@requires_finalization_opts & original_opts.keys).empty?
        # If no new filename or path is specified reuse the default sitemap file.
        # A new location object will be set on it for the duration of the group.
        original_opts[:sitemap] = sitemap
      elsif original_opts.key?(:sitemaps_host) && (@@new_location_opts & original_opts.keys).empty?
        # If no location options are provided we are creating the next sitemap in the
        # current series, so finalize and inherit the namer.
        finalize_sitemap!
        original_opts[:namer] = namer
      end

      opts = options_for_group(original_opts)
      @group = SitemapGenerator::LinkSet.new(opts)
      if opts.key?(:sitemap)
        # If the group is sharing the current sitemap, set the
        # new location options on the location object.
        @original_location = @sitemap.location.dup
        @sitemap.location.merge!(@group.sitemap_location)
        if block_given?
          @group.interpreter.eval(:yield_sitemap => @yield_sitemap || SitemapGenerator.yield_sitemap?, &block)
          @group.finalize_sitemap!
          @sitemap.location.merge!(@original_location)
        end
      else
        # Handle the case where a user only has one group, and it's being written
        # to a new sitemap file.  They would expect there to be an index.  So force
        # index creation.  If there is more than one group, we would have an index anyways,
        # so it's safe to force index creation in these other cases.  In the case that
        # the groups reuse the current sitemap, don't force index creation because
        # we want the default behaviour i.e. only an index if more than one sitemap file.
        # Don't force index creation if the user specifically requested no index.  This
        # unfortunately means that if they set it to :auto they may be getting an index
        # when they didn't expect one, but you shouldn't be using groups if you only have
        # one sitemap and don't want an index.  Rather, just add the links directly in the create()
        # block.
        @group.send(:create_index=, true, true) if @group.create_index != false

        if block_given?
          @group.interpreter.eval(:yield_sitemap => @yield_sitemap || SitemapGenerator.yield_sitemap?, &block)
          @group.finalize_sitemap!
        end
      end
      @group
    end

    # Ping search engines to notify them of updated sitemaps.
    #
    # Search engines are already notified for you if you run `rake sitemap:refresh`.
    # If you want to ping search engines separately to your sitemap generation, run
    # `rake sitemap:refresh:no_ping` and then run a rake task or script
    # which calls this method as in the example below.
    #
    # == Arguments
    # * sitemap_index_url - The full URL to your sitemap index file.
    #   If not provided the location is based on the `host` you have
    #   set and any other options like your `sitemaps_path`.  The URL
    #   will be CGI escaped for you when included as part of the
    #   search engine ping URL.
    #
    # == Options
    # A hash of one or more search engines to ping in addition to the
    # default search engines.  The key is the name of the search engine
    # as a string or symbol and the value is the full URL to ping with
    # a string interpolation that will be replaced by the CGI escaped sitemap
    # index URL.  If you have any literal percent characters in your URL you
    # need to escape them with `%%`.  For example if your sitemap index URL
    # is `http://example.com/sitemap.xml.gz` and your
    # ping url is `http://example.com/100%%/ping?url=%s`
    # then the final URL that is pinged will be `http://example.com/100%/ping?url=http%3A%2F%2Fexample.com%2Fsitemap.xml.gz`
    #
    # == Examples
    #
    # Both of these examples will ping the default search engines in addition to `http://superengine.com/ping?url=http%3A%2F%2Fexample.com%2Fsitemap.xml.gz`
    #
    #   SitemapGenerator::Sitemap.host('http://example.com/')
    #   SitemapGenerator::Sitemap.ping_search_engines(:super_engine => 'http://superengine.com/ping?url=%s')
    #
    # Is equivalent to:
    #
    #   SitemapGenerator::Sitemap.ping_search_engines('http://example.com/sitemap.xml.gz', :super_engine => 'http://superengine.com/ping?url=%s')
    def ping_search_engines(*args)
      require 'cgi/session'
      require 'open-uri'
      require 'timeout'

      engines = args.last.is_a?(Hash) ? args.pop : {}
      unescaped_url = args.shift || sitemap_index_url
      index_url = CGI.escape(unescaped_url)

      output("\n")
      output("Pinging with URL '#{unescaped_url}':")
      search_engines.merge(engines).each do |engine, link|
        link = link % index_url
        name = Utilities.titleize(engine.to_s)
        begin
          Timeout::timeout(10) {
            if URI.respond_to?(:open) # Available since Ruby 2.5
              URI.open(link)
            else
              open(link) # using Kernel#open became deprecated since Ruby 2.7. See https://bugs.ruby-lang.org/issues/15893
            end
          }
          output("  Successful ping of #{name}")
        rescue Timeout::Error, StandardError => e
          output("Ping failed for #{name}: #{e.inspect} (URL #{link})")
        end
      end
    end

    # Return a count of the total number of links in all sitemaps
    def link_count
      sitemap_index.total_link_count
    end

    # Return the host to use in links to the sitemap files.  This defaults to your
    # +default_host+.
    def sitemaps_host
      @sitemaps_host || @default_host
    end

    # Lazy-initialize a sitemap instance and return it.
    def sitemap
      @sitemap ||= SitemapGenerator::Builder::SitemapFile.new(sitemap_location)
    end

    # Lazy-initialize a sitemap index instance and return it.
    def sitemap_index
      @sitemap_index ||= SitemapGenerator::Builder::SitemapIndexFile.new(sitemap_index_location)
    end

    # Return the full url to the sitemap index file.  When `create_index` is `false`
    # the first sitemap is technically the index, so this will be its URL.  It's important
    # to use this method to get the index url because `sitemap_index.location.url`  will
    # not be correct in such situations.
    #
    # KJV: This is somewhat confusing.
    def sitemap_index_url
      sitemap_index.index_url
    end

    # All done.  Write out remaining files.
    def finalize!
      finalize_sitemap!
      finalize_sitemap_index!
    end

    # Return a boolean indicating hether to add a link to the sitemap index file
    # to the current sitemap.  This points search engines to your Sitemap Index so
    # they include it in the indexing of your site, but is not strictly neccessary.
    # Default is `true`.  Turned off when `sitemaps_host` is set or within a `group()` block.
    def include_index?
      if default_host && sitemaps_host && sitemaps_host != default_host
        false
      else
        @include_index
      end
    end

    # Return a boolean indicating whether to automatically add the root url i.e. '/' to the
    # current sitemap.  Default is `true`.  Turned off within a `group()` block.
    def include_root?
      !!@include_root
    end

    # Set verbose on the instance or by setting ENV['VERBOSE'] to true or false.
    # By default verbose is true.  When running rake tasks, pass the <tt>-s</tt>
    # option to rake to turn verbose off.
    def verbose
      if @verbose.nil?
        @verbose = SitemapGenerator.verbose.nil? ? true : SitemapGenerator.verbose
      end
      @verbose
    end

    # Return a boolean indicating whether or not to yield the sitemap.
    def yield_sitemap?
      @yield_sitemap.nil? ? SitemapGenerator.yield_sitemap? : !!@yield_sitemap
    end

    protected

    # Set each option on this instance using accessor methods.  This will affect
    # both the sitemap and the sitemap index.
    #
    # If both `filename` and `namer` are passed, set filename first so it
    # doesn't override the latter.
    def set_options(opts={})
      opts = opts.dup
      %w(filename namer).each do |key|
        if value = opts.delete(key.to_sym)
          send("#{key}=", value)
        end
      end
      opts.each_pair do |key, value|
        send("#{key}=", value)
      end
    end

    # Given +opts+, modify it and return it prepped for creating a new group from this LinkSet.
    # If <tt>:public_path</tt> is present in +opts+ it is removed because groups cannot
    # change the public path.
    def options_for_group(opts)
      opts = SitemapGenerator::Utilities.reverse_merge(opts,
        :include_index => false,
        :include_root => false,
        :sitemap_index => sitemap_index
      )
      opts.delete(:public_path)

      # Reverse merge the current settings.
      #
      # This hash could be a problem because it needs to be maintained
      # when new options are added, but can easily be missed.  We really could
      # do with a separate SitemapOptions class.
      current_settings = [
        :include_root,
        :include_index,
        :sitemaps_path,
        :public_path,
        :sitemaps_host,
        :verbose,
        :default_host,
        :adapter,
        :create_index,
        :compress,
        :max_sitemap_links
      ].inject({}) do |hash, key|
        value = instance_variable_get(:"@#{key}")
        hash[key] = value unless value.nil?
        hash
      end
      SitemapGenerator::Utilities.reverse_merge!(opts, current_settings)
      opts
    end

    # Add default links if those options are turned on.  Record the fact that we have done so
    # in an instance variable.
    def add_default_links
      @added_default_links = true
      link_options = { :lastmod => Time.now, :priority => 1.0 }
      if include_root?
        add('/', link_options)
      end
      if include_index?
        add(sitemap_index, link_options)
      end
    end

    # Finalize a sitemap by including it in the index and outputting a summary line.
    # Do nothing if it has already been finalized.
    #
    # Don't finalize if the sitemap is empty.
    #
    # Add the default links if they have not been added yet and no groups have been created.
    # If the default links haven't been added we know that the sitemap is empty,
    # because they are added on the first call to add().  This ensure that if the
    # block passed to create() is empty the default links are still included in the
    # sitemap.
    def finalize_sitemap!
      return if sitemap.finalized? || sitemap.empty? && @created_group
      add_default_links if !@added_default_links && !@created_group
      # This will finalize it.  We add to the index even if not creating an index because
      # the index keeps track of how many links are in our sitemaps and we need this info
      # for the summary line.  Also the index determines which file gets the first name
      # so everything has to go via the index.
      add_to_index(sitemap) unless sitemap.empty?
    end

    # Finalize a sitemap index and output a summary line.  Do nothing if it has already
    # been finalized.
    def finalize_sitemap_index!
      return if @protect_index || sitemap_index.finalized?
      sitemap_index.finalize!
      sitemap_index.write
    end

    # Return the interpreter linked to this instance.
    def interpreter
      require 'sitemap_generator/interpreter'
      @interpreter ||= SitemapGenerator::Interpreter.new(:link_set => self)
    end

    # Reset this instance.  Keep the same options, but return to the same state
    # as before any sitemaps were created.
    def reset!
      @sitemap_index = nil if @sitemap_index && @sitemap_index.finalized? && !@protect_index
      @sitemap = nil if @sitemap && @sitemap.finalized?
      self.namer.reset
      @added_default_links = false
    end

    # Write the given string to STDOUT.  Used so that the sitemap config can be
    # evaluated and some info output to STDOUT in a lazy fasion.
    def output(string)
      return unless verbose
      puts string
    end

    module LocationHelpers
      public

      # Set the host name, including protocol, that will be used by default on each
      # of your sitemap links.  You can pass a different host in your options to `add`
      # if you need to change it on a per-link basis.
      def default_host=(value)
        @default_host = value
        update_location_info(:host, value)
      end

      # Set the public_path.  This path gives the location of your public directory.
      # The default is the public/ directory in your Rails root.  Or if Rails is not
      # found, it defaults to public/ in the current directory (of the process).
      #
      # Example: 'tmp/' if you don't want to generate in public for some reason.
      #
      # Set to nil to use the current directory.
      def public_path=(value)
        @public_path = Pathname.new(SitemapGenerator::Utilities.append_slash(value))
        if @public_path.relative?
          @public_path = SitemapGenerator.app.root + @public_path
        end
        update_location_info(:public_path, @public_path)
        @public_path
      end

      # Return a Pathname with the full path to the public directory
      def public_path
        @public_path ||= self.send(:public_path=, 'public/')
      end

      # Set the sitemaps_path.  This path gives the location to write sitemaps to
      # relative to your public_path.
      # Example: 'sitemaps/' to generate your sitemaps in 'public/sitemaps/'.
      def sitemaps_path=(value)
        @sitemaps_path = value
        update_location_info(:sitemaps_path, value)
      end

      # Set the host name, including protocol, that will be used on all links to your sitemap
      # files.  Useful when the server that hosts the sitemaps is not on the same host as
      # the links in the sitemap.
      #
      # Note that `include_index` will be turned off to avoid adding a link to a sitemap with
      # a different host than the other links.
      def sitemaps_host=(value)
        @sitemaps_host = value
        update_location_info(:host, value)
      end

      # Set the filename base to use when generating sitemaps (and the sitemap index).
      #
      # === Example
      # <tt>filename = :sitemap</tt>
      #
      # === Generates
      # <tt>sitemap.xml.gz, sitemap1.xml.gz, sitemap2.xml.gz, ...</tt>
      def filename=(value)
        @filename = value
        self.namer = SitemapGenerator::SimpleNamer.new(@filename)
      end

      # Set the search engines hash to a new hash of search engine names mapped to
      # ping URLs (see ping_search_engines).  If the value is nil it is converted
      # to an empty hash.
      # === Example
      # <tt>search_engines = { :google => "http://www.google.com/webmasters/sitemaps/ping?sitemap=%s" }</tt>
      def search_engines=(value)
        @search_engines = value || {}
      end

      # Return the hash of search engines.
      def search_engines
        @search_engines || {}
      end

      # Return a new +SitemapLocation+ instance with the current options included
      def sitemap_location
        SitemapGenerator::SitemapLocation.new(
          :host => sitemaps_host,
          :namer => namer,
          :public_path => public_path,
          :sitemaps_path => @sitemaps_path,
          :adapter => @adapter,
          :verbose => verbose,
          :compress => @compress,
          :max_sitemap_links => max_sitemap_links
        )
      end

      # Return a new +SitemapIndexLocation+ instance with the current options included
      def sitemap_index_location
        SitemapGenerator::SitemapLocation.new(
          :host => sitemaps_host,
          :namer => namer,
          :public_path => public_path,
          :sitemaps_path => @sitemaps_path,
          :adapter => @adapter,
          :verbose => verbose,
          :create_index => @create_index,
          :compress => @compress
        )
      end

      # Set the value of +create_index+ on the SitemapIndexLocation object of the
      # SitemapIndexFile.
      #
      # Whether to create a sitemap index file.  Supported values: `true`, `false`, `:auto`.
      # If `true` an index file is always created, regardless of how many links
      # are in your sitemap.  If `false` an index file is never created.
      # If `:auto` an index file is created only if your sitemap has more than
      # one sitemap file.
      def create_index=(value, force=false)
        @create_index = value
        # Allow overriding the protected status of the index when we are creating a group.
        # Because sometimes we need to force an index in that case.  But generally we don't
        # want to allow people to mess with this value if the index is protected.
        @sitemap_index.location[:create_index] = value if @sitemap_index && ((!@sitemap_index.finalized? && !@protect_index) || force)
      end

      # Set the namer to use to generate the sitemap (and index) file names.
      # This should be an instance of <tt>SitemapGenerator::SimpleNamer</tt>
      def namer=(value)
        @namer = value
        @sitemap.location[:namer] = value if @sitemap && !@sitemap.finalized?
        @sitemap_index.location[:namer] = value if @sitemap_index && !@sitemap_index.finalized? && !@protect_index
      end

      # Return the namer object.  If it is not set, looks for it on
      # the current sitemap and if there is no sitemap, creates a new one using
      # the current filename.
      def namer
        @namer ||= @sitemap && @sitemap.location.namer || SitemapGenerator::SimpleNamer.new(@filename)
      end

      # Set the value of the compress setting.
      #
      # Values:
      #   * `true` - Boolean; compress all files
      #   * `false` - Boolean; write out only uncompressed files
      #   * `:all_but_first` - Symbol; leave the first file uncompressed but compress any remaining files.
      #
      # The compression setting applies to groups too.  So :all_but_first will have the same effect (the first
      # file in the group will not be compressed, the rest will).  So if you require different behaviour for your
      # groups, pass in a `:compress` option e.g. <tt>group(:compress => false) { add('/link') }</tt>
      def compress=(value)
        @compress = value
        @sitemap_index.location[:compress] = @compress if @sitemap_index
        @sitemap.location[:compress] = @compress if @sitemap
      end

      # Return the current compression setting.  Its value determines which files will be gzip'ed.
      # See the setter for documentation of its values.
      def compress
        @compress
      end

      protected

      # Update the given attribute on the current sitemap index and sitemap file location objects.
      # But don't create the index or sitemap files yet if they are not already created.
      def update_location_info(attribute, value, opts={})
        opts = SitemapGenerator::Utilities.reverse_merge(opts, :include_index => !@protect_index)
        @sitemap_index.location[attribute] = value if opts[:include_index] && @sitemap_index && !@sitemap_index.finalized?
        @sitemap.location[attribute] = value if @sitemap && !@sitemap.finalized?
      end
    end
    include LocationHelpers
  end
end
