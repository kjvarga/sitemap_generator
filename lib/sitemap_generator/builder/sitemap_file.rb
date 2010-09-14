require 'sitemap_generator/builder/helper'
require 'builder'
require 'zlib'

module SitemapGenerator
  module Builder
    class SitemapFile
      include SitemapGenerator::Builder::Helper

      attr_accessor :sitemap_path, :public_path, :filesize, :link_count, :hostname

      # <tt>public_path</tt> full path of the directory to write sitemaps in.
      #   Usually your Rails <tt>public/</tt> directory.
      #
      # <tt>sitemap_path</tt> relative path including filename of the sitemap
      #   file relative to <tt>public_path</tt>
      #
      # <tt>hostname</tt> hostname including protocol to use in all links
      #   e.g. http://en.google.ca
      def initialize(public_path, sitemap_path, hostname)
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

      # Add a link to the sitemap file and return a boolean indicating whether the
      # link was added.
      #
      # If a link cannot be added, the file is too large or the link limit has been reached.
      def add_link(link)
        xml = build_xml(::Builder::XmlMarkup.new, link)
        unless file_can_fit?(bytesize(xml))
          self.finalize!
          return false
        end

        @xml_content << xml
        self.filesize += bytesize(xml)
        self.link_count += 1
        true
      end
      alias_method :<<, :add_link

      # Return XML as a String
      def build_xml(builder, link)
        builder.url do
          builder.loc        link[:loc]
          builder.lastmod    w3c_date(link[:lastmod])   if link[:lastmod]
          builder.changefreq link[:changefreq]          if link[:changefreq]
          builder.priority   link[:priority]            if link[:priority]

          unless link[:images].blank?
            link[:images].each do |image|
              builder.image:image do
                builder.image :loc, image[:loc]
                builder.image :caption, image[:caption]             if image[:caption]
                builder.image :geo_location, image[:geo_location]   if image[:geo_location]
                builder.image :title, image[:title]                 if image[:title]
                builder.image :license, image[:license]             if image[:license]
              end
            end
          end

          unless link[:video].blank?
            video = link[:video]
            builder.video :video do
              # required elements
              builder.video :thumbnail_loc, video[:thumbnail_loc]
              builder.video :title, video[:title]
              builder.video :description, video[:description]

              builder.video :content_loc, video[:content_loc]           if video[:content_loc]
              if video[:player_loc]
                builder.video :player_loc, video[:player_loc], :allow_embed => (video[:allow_embed] ? 'yes' : 'no'), :autoplay => video[:autoplay]
              end

              builder.video :rating, video[:rating]                     if video[:rating]
              builder.video :view_count, video[:view_count]             if video[:view_count]
              builder.video :publication_date, video[:publication_date] if video[:publication_date]
              builder.video :expiration_date, video[:expiration_date]   if video[:expiration_date]
              builder.video :duration, video[:duration]                 if video[:duration]
              builder.video :family_friendly, (video[:family_friendly] ? 'yes' : 'no')  if video[:family_friendly]
              builder.video :duration, video[:duration]                 if video[:duration]
              video[:tags].each {|tag| builder.video :tag, tag }        if video[:tags]
              video[:categories].each {|category| builder.video :category, category} if video[:categories]
            end
          end
        end
        builder << ''
      end

      # Insert the content into the XML "wrapper" and write and close the file.
      #
      # All the xml content in the instance is cleared, but attributes like
      # <tt>filesize</tt> are still available.
      def finalize!
        return if self.frozen?

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

      # Return the bytesize length of the string
      def bytesize(string)
        string.respond_to?(:bytesize) ? string.bytesize : string.length
      end
    end
  end
end
