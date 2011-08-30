require 'builder'
require 'uri'

module SitemapGenerator
  module Builder
    class SitemapUrl < Hash

      # Call with:
      #   sitemap - a Sitemap instance, or
      #   path, options - a path for the URL and options hash
      def initialize(path, options={})
        if sitemap = path.is_a?(SitemapGenerator::Builder::SitemapFile) && path
          options.reverse_merge!(:host => sitemap.location.host, :lastmod => sitemap.lastmod)
          path = sitemap.location.path_in_public
        end

        SitemapGenerator::Utilities.assert_valid_keys(options, :priority, :changefreq, :lastmod, :host, :images, :video, :geo, :news)
        options.reverse_merge!(:priority => 0.5, :changefreq => 'weekly', :lastmod => Time.now, :images => [], :news => {})
        self.merge!(
          :path => path,
          :priority => options[:priority],
          :changefreq => options[:changefreq],
          :lastmod => options[:lastmod],
          :host => options[:host],
          :loc => URI.join(options[:host], path).to_s,
          :images => prepare_images(options[:images], options[:host]),
          :news => prepare_news(options[:news]),
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

          unless self[:news].blank?
            news_data = self[:news]
            builder.news:news do
              builder.news:publication do
                builder.news :name, news_data[:publication_name] if news_data[:publication_name]
                builder.news :language, news_data[:publication_language] if news_data[:publication_language]
              end

              builder.news :access, news_data[:access] if news_data[:access]
              builder.news :genres, news_data[:genres] if news_data[:genres]
              builder.news :publication_date, news_data[:publication_date] if news_data[:publication_date]
              builder.news :title, news_data[:title] if news_data[:title]
              builder.news :keywords, news_data[:keywords] if news_data[:keywords]
              builder.news :stock_tickers, news_data[:stock_tickers] if news_data[:stock_tickers]
            end
          end


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
              builder.video :family_friendly, (video[:family_friendly] ? 'yes' : 'no')  if video[:family_friendly]
              builder.video :duration, video[:duration]                 if video[:duration]
              video[:tags].each {|tag| builder.video :tag, tag }        if video[:tags]
              builder.video :tag, video[:tag]                           if video[:tag]
              builder.video :category, video[:category]                 if video[:category]
              builder.video :gallery_loc, video[:gallery_loc]           if video[:gallery_loc]

              if video[:uploader]
                builder.video :uploader, video[:uploader], video[:uploader_info] ? { :info => video[:uploader_info] } : {}
              end
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

      def news?
        self[:news].present?
      end

      protected

      def prepare_news(news)
        SitemapGenerator::Utilities.assert_valid_keys(news, :publication_name, :publication_language, :publication_date, :genres, :access, :title, :keywords, :stock_tickers) unless news.empty?
        news
      end

      # Return an Array of image option Hashes suitable to be parsed by SitemapGenerator::Builder::SitemapFile
      def prepare_images(images, host)
        images.delete_if { |key,value| key[:loc] == nil }
        images.each do |r|
          SitemapGenerator::Utilities.assert_valid_keys(r, :loc, :caption, :geo_location, :title, :license)
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