require 'zlib'
require 'action_view' # for number_to_human_size
require 'fileutils'

module SitemapGenerator
  module Builder
    #
    # General Usage:
    #
    #   sitemap = SitemapFile.new(:location => SitemapLocation.new(...))
    #   sitemap.add('/', { ... })    <- add a link to the sitemap
    #   sitemap.finalize!            <- write the sitemap file and freeze the object to protect it from further modification
    #
    class SitemapFile
      include ActionView::Helpers::NumberHelper
      include ActionView::Helpers::TextHelper   # Rails 2.2.2 fails with missing 'pluralize' otherwise
      attr_reader :link_count, :filesize, :location, :news_count

      # === Options
      #
      # * <tt>location</tt> - a SitemapGenerator::SitemapLocation instance or a Hash of options
      #   from which a SitemapLocation will be created for you.
      def initialize(opts={})
        @location = opts.is_a?(Hash) ? SitemapGenerator::SitemapLocation.new(opts) : opts
        @link_count = 0
        @news_count = 0
        @xml_content = '' # XML urlset content
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
              xmlns:news="http://www.google.com/schemas/sitemap-news/0.9/"
            >
        HTML
        @xml_wrapper_start.gsub!(/\s+/, ' ').gsub!(/ *> */, '>').strip!
        @xml_wrapper_end   = %q[</urlset>]
        @filesize = bytesize(@xml_wrapper_start) + bytesize(@xml_wrapper_end)
      end

      def lastmod
        File.mtime(path) rescue nil
      end

      def empty?
        @link_count == 0
      end

      # Return a boolean indicating whether the sitemap file can fit another link
      # of <tt>bytes</tt> bytes in size.  You can also pass a string and the
      # bytesize will be calculated for you.
      def file_can_fit?(bytes)
        bytes = bytes.is_a?(String) ? bytesize(bytes) : bytes
        (@filesize + bytes) < SitemapGenerator::MAX_SITEMAP_FILESIZE && @link_count < SitemapGenerator::MAX_SITEMAP_LINKS && @news_count < SitemapGenerator::MAX_SITEMAP_NEWS
      end

      # Add a link to the sitemap file.
      #
      # If a link cannot be added, for example if the file is too large or the link
      # limit has been reached, a SitemapGenerator::SitemapFullError exception is raised
      # and the sitemap is finalized.
      #
      # If the Sitemap has already been finalized a SitemapGenerator::SitemapFinalizedError
      # exception is raised.
      #
      # Return the new link count.
      #
      # Call with:
      #   sitemap_url - a SitemapUrl instance
      #   sitemap, options - a Sitemap instance and options hash
      #   path, options - a path for the URL and options hash
      def add(link, options={})
        raise SitemapGenerator::SitemapFinalizedError if finalized?

        sitemap_url = (link.is_a?(SitemapUrl) ? link : SitemapUrl.new(link, options) )

        xml = sitemap_url.to_xml
        raise SitemapGenerator::SitemapFullError if !file_can_fit?(xml)

        if sitemap_url.news?
          @news_count += 1
        end

        # Add the XML to the sitemap
        @xml_content << xml
        @filesize += bytesize(xml)
        @link_count += 1
      end

      # Write out the Sitemap file and freeze this object.
      #
      # All the xml content in the instance is cleared, but attributes like
      # <tt>filesize</tt> are still available.
      #
      # A SitemapGenerator::SitemapFinalizedError exception is raised if the Sitemap
      # has already been finalized
      def finalize!
        raise SitemapGenerator::SitemapFinalizedError if finalized?

        @location.write(@xml_wrapper_start + @xml_content + @xml_wrapper_end)

        # Increment the namer (SitemapFile only)
        @location.namer.next if @location.namer

        # Cleanup and freeze the object
        @xml_content = @xml_wrapper_start = @xml_wrapper_end = ''
        freeze
      end

      def finalized?
        frozen?
      end

      # Return a new instance of the sitemap file with the same options, and the next name in the sequence.
      def new
        location = @location.dup
        location.delete(:filename) if location.namer
        self.class.new(location)
      end

      # Return a summary string
      def summary(opts={})
        uncompressed_size = number_to_human_size(@filesize) rescue "#{@filesize / 8} KB"
        compressed_size =   number_to_human_size(@location.filesize) rescue "#{@location.filesize / 8} KB"
        "+ #{'%-21s' % @location.path_in_public} #{'%13s' % @link_count} links / #{'%10s' % uncompressed_size} / #{'%10s' % compressed_size} gzipped"
      end

      protected

      # Return the bytesize length of the string.  Ruby 1.8.6 compatible.
      def bytesize(string)
        string.respond_to?(:bytesize) ? string.bytesize : string.length
      end
    end
  end
end
