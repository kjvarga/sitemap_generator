require 'sitemap_generator/helpers/number_helper'

module SitemapGenerator
  # A class for determining the exact location at which to write sitemap data.
  # Handles reserving filenames from namers, constructing paths and sending
  # data to the adapter to be written out.
  class SitemapLocation < Hash
    include SitemapGenerator::Helpers::NumberHelper

    PATH_OUTPUT_WIDTH = 47 # Character width of the path in the summary lines

    def assert_value(key)
      raise SitemapGenerator::SitemapError, "No value set for #{key}" unless self[key]
    end

    def assert_slash(key)
      SitemapGenerator::Utilities.append_slash(self[key])
    end

    def adapter
      assert_value(:adapter)
      self[:adapter]
    end

    def host
      assert_value(:host)
      assert_slash(:host)
    end

    [:public_path, :sitemaps_path].each do |method|
      define_method(method) do
        Pathname.new(assert_slash(method))
      end
    end

    # If no +filename+ or +namer+ is provided, the default namer is used, which
    # generates names like <tt>sitemap.xml.gz</tt>, <tt>sitemap1.xml.gz</tt>, <tt>sitemap2.xml.gz</tt> and so on.
    #
    # === Options
    # * <tt>:adapter</tt> - SitemapGenerator::Adapter subclass
    # * <tt>:filename</tt> - full name of the file e.g. <tt>'sitemap1.xml.gz'<tt>
    # * <tt>:host</tt> - host name for URLs.  The full URL to the file is then constructed from
    #   the <tt>host</tt>, <tt>sitemaps_path</tt> and <tt>filename</tt>
    # * <tt>:namer</tt> - a SitemapGenerator::SimpleNamer instance for generating file names.
    #   Should be passed if no +filename+ is provided.
    # * <tt>:public_path</tt> - path to the "public" directory, or the directory you want to
    #   write sitemaps in.  Default is a directory <tt>public/</tt>
    #   in the current working directory, or relative to the Rails root
    #   directory if running under Rails.
    # * <tt>:sitemaps_path</tt> - gives the path relative to the <tt>public_path</tt> in which to
    #   write sitemaps e.g. <tt>sitemaps/</tt>.
    # * <tt>:verbose</tt> - whether to output summary into to STDOUT.  Default +false+.
    # * <tt>:create_index</tt> - whether to create a sitemap index.  Default `:auto`.  See <tt>LinkSet::create_index=</tt>
    #   for possible values. Only applies to the SitemapIndexLocation object.
    # * <tt>compress</tt> - The LinkSet compress setting.  Default: +true+.  If `false` any `.gz` extension is
    #   stripped from the filename.  If `:all_but_first`, only the `.gz` extension of the first
    #   filename is stripped off.  If `true` the extensions are left unchanged.
    def initialize(opts={})
      SitemapGenerator::Utilities.assert_valid_keys(opts, [:adapter, :public_path, :sitemaps_path, :host, :filename, :namer, :verbose, :create_index, :compress])
      opts[:adapter] ||= SitemapGenerator::FileAdapter.new
      opts[:public_path] ||= SitemapGenerator.app.root + 'public/'
      # This is a bit of a hack to make the SimpleNamer act like the old SitemapNamer.
      # It doesn't really make sense to create a default namer like this because the
      # namer instance should be shared by the location objects of the sitemaps and
      # sitemap index files.  However, this greatly eases testing, so I'm leaving it in
      # for now.
      if !opts[:filename] && !opts[:namer]
        opts[:namer] = SitemapGenerator::SimpleNamer.new(:sitemap, :start => 2, :zero => 1)
      end
      opts[:verbose] = !!opts[:verbose]
      self.merge!(opts)
    end

    # Return a new Location instance with the given options merged in
    def with(opts={})
      self.merge(opts)
    end

    # Full path to the directory of the file.
    def directory
      (public_path + sitemaps_path).expand_path.to_s
    end

    # Full path of the file including the filename.
    def path
      (public_path + sitemaps_path + filename).expand_path.to_s
    end

    # Relative path of the file (including the filename) relative to <tt>public_path</tt>
    def path_in_public
      (sitemaps_path + filename).to_s
    end

    # Full URL of the file.
    def url
      URI.join(host, sitemaps_path.to_s, filename.to_s).to_s
    end

    # Return the size of the file at <tt>path</tt>
    def filesize
      File.size?(path)
    end

    # Return the filename.  Raises an exception if no filename or namer is set.
    # If using a namer once the filename has been retrieved from the namer its
    # value is locked so that it is unaffected by further changes to the namer.
    def filename
      raise SitemapGenerator::SitemapError, "No filename or namer set" unless self[:filename] || self[:namer]
      unless self[:filename]
        self.send(:[]=, :filename, self[:namer].to_s, :super => true)

        # Post-process the filename for our compression settings.
        # Strip the `.gz` from the extension if we aren't compressing this file.
        # If you're setting the filename manually, :all_but_first won't work as
        # expected.  Ultimately I should force using a namer in all circumstances.
        # Changing the filename here will affect how the FileAdapter writes out the file.
        if self[:compress] == false ||
           (self[:namer] && self[:namer].start? && self[:compress] == :all_but_first)
          self[:filename].gsub!(/\.gz$/, '')
        end
      end
      self[:filename]
    end

    # If a namer is set, reserve the filename and increment the namer.
    # Returns the reserved name.
    def reserve_name
      if self[:namer]
        filename
        self[:namer].next
      end
      self[:filename]
    end

    # Return true if this location has a fixed filename.  If no name has been
    # reserved from the namer, for instance, returns false.
    def reserved_name?
      !!self[:filename]
    end

    def namer
      self[:namer]
    end

    def verbose?
      self[:verbose]
    end

    # If you set the filename, clear the namer and vice versa.
    def []=(key, value, opts={})
      if !opts[:super]
        case key
        when :namer
          super(:filename, nil)
        when :filename
          super(:namer, nil)
        end
      end
      super(key, value)
    end

    # Write `data` out to a file.
    # Output a summary line if verbose is true.
    def write(data, link_count)
      adapter.write(self, data)
      puts summary(link_count) if verbose?
    end

    # Return a summary string
    def summary(link_count)
      filesize = number_to_human_size(self.filesize)
      width = self.class::PATH_OUTPUT_WIDTH
      path = SitemapGenerator::Utilities.ellipsis(self.path_in_public, width)
      "+ #{('%-'+width.to_s+'s') % path} #{'%10s' % link_count} links / #{'%10s' % filesize}"
    end
  end

  class SitemapIndexLocation < SitemapLocation
    def initialize(opts={})
      if !opts[:filename] && !opts[:namer]
        opts[:namer] = SitemapGenerator::SimpleNamer.new(:sitemap)
      end
      super(opts)
    end

    # Whether to create a sitemap index.  Default `:auto`.  See <tt>LinkSet::create_index=</tt>
    # for possible values.
    #
    # A placeholder for an option which should really go into some
    # kind of options class.
    def create_index
      self[:create_index]
    end

    # Return a summary string
    def summary(link_count)
      filesize = number_to_human_size(self.filesize)
      width = self.class::PATH_OUTPUT_WIDTH - 3
      path = SitemapGenerator::Utilities.ellipsis(self.path_in_public, width)
      "+ #{('%-'+width.to_s+'s') % path} #{'%10s' % link_count} sitemaps / #{'%10s' % filesize}"
    end
  end
end
