require 'zlib'
require 'fileutils'
require 'sitemap_generator/helpers/number_helper'

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
      include SitemapGenerator::Helpers::NumberHelper
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
              xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"
              xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
              xmlns:image="#{SitemapGenerator::SCHEMAS['image']}"
              xmlns:video="#{SitemapGenerator::SCHEMAS['video']}"
              xmlns:geo="#{SitemapGenerator::SCHEMAS['geo']}"
              xmlns:news="#{SitemapGenerator::SCHEMAS['news']}"
              xmlns:mobile="#{SitemapGenerator::SCHEMAS['mobile']}"
              xmlns:pagemap="#{SitemapGenerator::SCHEMAS['pagemap']}"
              xmlns:xhtml="http://www.w3.org/1999/xhtml"
            >
        HTML
        @xml_wrapper_start.gsub!(/\s+/, ' ').gsub!(/ *> */, '>').strip!
        @xml_wrapper_end   = %q[</urlset>]
        @filesize = SitemapGenerator::Utilities.bytesize(@xml_wrapper_start) + SitemapGenerator::Utilities.bytesize(@xml_wrapper_end)
        @written = false
        @reserved_name = nil # holds the name reserved from the namer
        @frozen = false      # rather than actually freeze, use this boolean
      end

      # If a name has been reserved, use the last modified time from the file.
      # Otherwise return nil.  We don't want to prematurely assign a name
      # for this sitemap if one has not yet been reserved, because we may
      # mess up the name-assignment sequence.
      def lastmod
        File.mtime(location.path) if location.reserved_name?
      rescue
        nil
      end

      def empty?
        @link_count == 0
      end

      # Return a boolean indicating whether the sitemap file can fit another link
      # of <tt>bytes</tt> bytes in size.  You can also pass a string and the
      # bytesize will be calculated for you.
      def file_can_fit?(bytes)
        bytes = bytes.is_a?(String) ? SitemapGenerator::Utilities.bytesize(bytes) : bytes
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
      #   path, options - a path for the URL and options hash.  For supported options
      #                   see the SitemapGenerator::Builder::SitemapUrl class.
      #
      # The link added to the sitemap will use the host from its location object
      # if no host has been specified.
      def add(link, options={})
        raise SitemapGenerator::SitemapFinalizedError if finalized?

        sitemap_url = if link.is_a?(SitemapUrl)
          link
        else
          options[:host] ||= @location.host
          SitemapUrl.new(link, options)
        end

        xml = sitemap_url.to_xml
        raise SitemapGenerator::SitemapFullError if !file_can_fit?(xml)

        if sitemap_url.news?
          @news_count += 1
        end

        # Add the XML to the sitemap
        @xml_content << xml
        @filesize += SitemapGenerator::Utilities.bytesize(xml)
        @link_count += 1
      end

      # "Freeze" this object.  Actually just flags it as frozen.
      #
      # A SitemapGenerator::SitemapFinalizedError exception is raised if the Sitemap
      # has already been finalized.
      def finalize!
        raise SitemapGenerator::SitemapFinalizedError if finalized?
        @frozen = true
      end

      def finalized?
        @frozen
      end

      # Write out the sitemap and free up memory.
      #
      # All the xml content in the instance is cleared, but attributes like
      # <tt>filesize</tt> are still available.
      #
      # A SitemapGenerator::SitemapError exception is raised if the file has
      # already been written.
      def write
        raise SitemapGenerator::SitemapError.new("Sitemap already written!") if written?
        finalize! unless finalized?
        reserve_name
        @location.write(@xml_wrapper_start + @xml_content + @xml_wrapper_end, link_count)
        @xml_content = @xml_wrapper_start = @xml_wrapper_end = ''
        @written = true
      end

      # Return true if this file has been written out to disk
      def written?
        @written
      end

      # Reserve a name from the namer unless one has already been reserved.
      # Safe to call more than once.
      def reserve_name
        @reserved_name ||= @location.reserve_name
      end

      # Return a boolean indicating whether a name has been reserved
      def reserved_name?
        !!@reserved_name
      end

      # Return a new instance of the sitemap file with the same options,
      # and the next name in the sequence.
      def new
        location = @location.dup
        location.delete(:filename) if location.namer
        self.class.new(location)
      end
    end
  end
end
