require 'builder'
require 'uri'

module SitemapGenerator
  module Builder
    class SitemapUrl < Hash

      # Call with:
      #   sitemap - a Sitemap instance, or
      #   path, options - a path for the URL and options hash
      def initialize(path, options={})
        if path.is_a?(SitemapGenerator::Builder::SitemapFile)
          options.reverse_merge!(:host => path.hostname, :lastmod => path.lastmod)
          path = path.sitemap_path
        end

        options.assert_valid_keys(:priority, :changefreq, :lastmod, :host, :images, :video, :geo)
        options.reverse_merge!(:priority => 0.5, :changefreq => 'weekly', :lastmod => Time.now, :host => Sitemap.default_host, :images => [])
        self.merge!(
          :path => path,
          :priority => options[:priority],
          :changefreq => options[:changefreq],
          :lastmod => options[:lastmod],
          :host => options[:host],
          :loc => URI.join(options[:host], path).to_s,
          :images => prepare_images(options[:images], options[:host]),
          :video => options[:video],
          :geo => options[:geo]
        )
      end

      # Return the URL as XML
      def to_xml(builder=nil)
        builder = ::Builder::XmlMarkup.new if builder.nil?
        builder.url do
          builder.loc        self[:loc]
          builder.lastmod    w3c_date(self[:lastmod])   if self[:lastmod]
          builder.changefreq self[:changefreq]          if self[:changefreq]
          builder.priority   self[:priority]            if self[:priority]

          unless self[:images].blank?
            self[:images].each do |image|
              builder.image:image do
                builder.image :loc, image[:loc]
                builder.image :caption, image[:caption]             if image[:caption]
                builder.image :geo_location, image[:geo_location]   if image[:geo_location]
                builder.image :title, image[:title]                 if image[:title]
                builder.image :license, image[:license]             if image[:license]
              end
            end
          end

          unless self[:video].blank?
            video = self[:video]
            builder.video :video do
              builder.video :content_loc, video[:content_loc]           if video[:content_loc]
              if video[:player_loc]
                builder.video :player_loc, video[:player_loc], :allow_embed => (video[:allow_embed] ? 'yes' : 'no'), :autoplay => video[:autoplay]
              end
              builder.video :thumbnail_loc, video[:thumbnail_loc]
              builder.video :title, video[:title]
              builder.video :description, video[:description]

              builder.video :rating, video[:rating]                     if video[:rating]
              builder.video :view_count, video[:view_count]             if video[:view_count]
              builder.video :publication_date, video[:publication_date] if video[:publication_date]
              builder.video :expiration_date, video[:expiration_date]   if video[:expiration_date]
              builder.video :family_friendly, (video[:family_friendly] ? 'yes' : 'no')  if video[:family_friendly]
              builder.video :duration, video[:duration]                 if video[:duration]
              video[:tags].each {|tag| builder.video :tag, tag }        if video[:tags]
              builder.video :tag, video[:tag]                           if video[:tag]
              builder.video :category, video[:category]                 if video[:category]
              builder.video :gallery_loc, video[:gallery_loc]           if video[:gallery_loc]
            end
          end
          
          unless self[:geo].blank?
            geo = self[:geo]
            builder.geo :geo do
              builder.geo :format, geo[:format] if geo[:format]
            end
          end
        end
        builder << '' # Force to string
      end

      protected

      # Return an Array of image option Hashes suitable to be parsed by SitemapGenerator::Builder::SitemapFile
      def prepare_images(images, host)
        images.delete_if { |key,value| key[:loc] == nil }
        images.each do |r|
          r.assert_valid_keys(:loc, :caption, :geo_location, :title, :license)
          r[:loc] = URI.join(host, r[:loc]).to_s
        end
        images[0..(SitemapGenerator::MAX_SITEMAP_IMAGES-1)]
      end

      def w3c_date(date)
         date.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")
      end
    end
  end
end