require 'zlib'
require 'action_view' # for number_to_human_size
require 'fileutils'

module SitemapGenerator
  module Builder
    #
    # General Usage:
    #
    #   sitemap = SitemapFile.new('public/', 'sitemap.xml', 'http://example.com')
    #   sitemap.add('/', { ... })    <- add a link to the sitemap
    #   sitemap.finalize!            <- creates a new sitemap file in directory public/
    #       and freezes the object to protect it from further modification
    #
    class SitemapFile
      include ActionView::Helpers::NumberHelper
      include ActionView::Helpers::TextHelper   # Rails 2.2.2 fails with missing 'pluralize' otherwise
      attr_accessor :sitemap_path, :public_path, :filesize, :link_count, :hostname

      # <tt>public_path</tt> full path of the directory to write sitemaps in.
      #   Usually your Rails <tt>public/</tt> directory.
      #
      # <tt>sitemap_path</tt> relative path including filename of the sitemap
      #   file relative to <tt>public_path</tt>
      #
      # <tt>hostname</tt> hostname including protocol to use in all links
      #   e.g. http://en.google.ca
      def initialize(public_path, sitemap_path, hostname='http://example.com')
        self.sitemap_path = sitemap_path
        self.public_path = public_path
        self.hostname = hostname
        self.link_count = 0

        @xml_content       = ''     # XML urlset content
        @xml_wrapper_start = <<-HTML
          <?xml version="1.0" encoding="UTF-8"?>
            <urlset
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"
              xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9
                http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"
              xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
              xmlns:video="http://www.google.com/schemas/sitemap-video/1.1"
              xmlns:geo="http://www.google.com/geo/schemas/sitemap/1.0"
            >
        HTML
        @xml_wrapper_start.gsub!(/\s+/, ' ').gsub!(/ *> */, '>').strip!
        @xml_wrapper_end   = %q[</urlset>]
        self.filesize = bytesize(@xml_wrapper_start) + bytesize(@xml_wrapper_end)
      end

      def lastmod
        File.mtime(self.full_path) rescue nil
      end

      def empty?
        self.link_count == 0
      end

      def full_url
        URI.join(self.hostname, self.sitemap_path).to_s
      end

      def full_path
        @full_path ||= File.join(self.public_path, self.sitemap_path)
      end

      # Return a boolean indicating whether the sitemap file can fit another link
      # of <tt>bytes</tt> bytes in size.
      def file_can_fit?(bytes)
        (self.filesize + bytes) < SitemapGenerator::MAX_SITEMAP_FILESIZE && self.link_count < SitemapGenerator::MAX_SITEMAP_LINKS
      end

      # Add a link to the sitemap file.
      #
      # If a link cannot be added, for example if the file is too large or the link
      # limit has been reached, a SitemapGenerator::SitemapFullError exception is raised.
      #
      # If the Sitemap has already been finalized a SitemapGenerator::SitemapFinalizedError
      # exception is raised.
      #
      # Call with:
      #   sitemap_url - a SitemapUrl instance
      #   sitemap, options - a Sitemap instance and options hash
      #   path, options - a path for the URL and options hash
      def add(link, options={})
        xml = if link.is_a?(SitemapGenerator::Builder::SitemapUrl)
          link.to_xml
        else
          SitemapGenerator::Builder::SitemapUrl.new(link, options).to_xml
        end

        if self.finalized?
          raise SitemapGenerator::SitemapFinalizedError
        elsif !file_can_fit?(bytesize(xml))
          raise SitemapGenerator::SitemapFullError
        end

        # Add the XML
        @xml_content << xml
        self.filesize += bytesize(xml)
        self.link_count += 1
        true
      end

      # Write out the Sitemap file and freeze this object.
      #
      # All the xml content in the instance is cleared, but attributes like
      # <tt>filesize</tt> are still available.
      #
      # A SitemapGenerator::SitemapFinalizedError exception is raised if the Sitemap
      # has already been finalized
      def finalize!
        raise SitemapGenerator::SitemapFinalizedError if self.finalized?

        # Ensure that the directory exists
        dir = File.dirname(self.full_path)
        if !File.exists?(dir)
          FileUtils.mkdir_p(dir)
        elsif !File.directory?(dir)
          raise SitemapError.new("#{dir} should be a directory!")
        end

        open(self.full_path, 'wb') do |file|
          gz = Zlib::GzipWriter.new(file)
          gz.write @xml_wrapper_start
          gz.write @xml_content
          gz.write @xml_wrapper_end
          gz.close
        end
        @xml_content = @xml_wrapper_start = @xml_wrapper_end = ''
        self.freeze
      end

      def finalized?
        return self.frozen?
      end

      # Return a summary string
      def summary
        uncompressed_size = number_to_human_size(filesize) rescue "#{filesize / 8} KB"
        compressed_size =   number_to_human_size(File.size?(full_path)) rescue "#{File.size?(full_path) / 8} KB"
        "+ #{'%-21s' % self.sitemap_path} #{'%13s' % self.link_count} links / #{'%10s' % uncompressed_size} / #{'%10s' % compressed_size} gzipped"
      end

      protected

      # Return the bytesize length of the string.  Ruby 1.8.6 compatible.
      def bytesize(string)
        string.respond_to?(:bytesize) ? string.bytesize : string.length
      end
    end
  end
end