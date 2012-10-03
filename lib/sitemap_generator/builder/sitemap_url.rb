require 'builder'
require 'uri'
require 'time'
require 'date'

module SitemapGenerator
  module Builder
    # A Hash-like class for holding information about a sitemap URL and
    # generating an XML <url> element suitable for sitemaps.
    class SitemapUrl < Hash

      # Return a new instance with options configured on it.
      #
      # == Arguments
      # * sitemap - a Sitemap instance, or
      # * path, options - a path string and options hash
      #
      # == Options
      # Requires a host to be set.  If passing a sitemap, the sitemap must have a +default_host+
      # configured.  If calling with a path and options, you must include the <tt>:host</tt> option.
      #
      # * +priority+
      # * +changefreq+
      # * +lastmod+
      # * +images+
      # * +video+/+videos+
      # * +geo+
      # * +news+
      # * +mobile+
      # * +alternate+/+alternates+
      def initialize(path, options={})
        options = options.dup
        if sitemap = path.is_a?(SitemapGenerator::Builder::SitemapFile) && path
          SitemapGenerator::Utilities.reverse_merge!(options, :host => sitemap.location.host, :lastmod => sitemap.lastmod)
          path = sitemap.location.path_in_public
        end

        SitemapGenerator::Utilities.assert_valid_keys(options, :priority, :changefreq, :lastmod, :host, :images, :video, :geo, :news, :videos, :mobile, :alternate, :alternates)
        SitemapGenerator::Utilities.reverse_merge!(options, :priority => 0.5, :changefreq => 'weekly', :lastmod => Time.now, :images => [], :news => {}, :videos => [], :mobile => false, :alternates => [])
        raise "Cannot generate a url without a host" unless SitemapGenerator::Utilities.present?(options[:host])
        if video = options.delete(:video)
          options[:videos] = video.is_a?(Array) ? options[:videos].concat(video) : options[:videos] << video
        end
        if alternate = options.delete(:alternate)
          options[:alternates] = alternate.is_a?(Array) ? options[:alternates].concat(alternate) : options[:alternates] << alternate
        end

        path = path.to_s.sub(/^\//, '')
        loc  = path.empty? ? options[:host] : (options[:host].to_s.sub(/\/$/, '') + '/' + path)
        self.merge!(
          :priority   => options[:priority],
          :changefreq => options[:changefreq],
          :lastmod    => options[:lastmod],
          :host       => options[:host],
          :loc        => loc,
          :images     => prepare_images(options[:images], options[:host]),
          :news       => prepare_news(options[:news]),
          :videos     => options[:videos],
          :geo        => options[:geo],
          :mobile     => options[:mobile],
          :alternates => options[:alternates]
        )
      end

      # Return the URL as XML
      def to_xml(builder=nil)
        builder = ::Builder::XmlMarkup.new if builder.nil?
        builder.url do
          builder.loc        self[:loc]
          builder.lastmod    w3c_date(self[:lastmod])      if self[:lastmod]
          builder.changefreq self[:changefreq]             if self[:changefreq]
          builder.priority   format_float(self[:priority]) if self[:priority]

          unless SitemapGenerator::Utilities.blank?(self[:news])
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

          self[:images].each do |image|
            builder.image:image do
              builder.image :loc, image[:loc]
              builder.image :caption, image[:caption]             if image[:caption]
              builder.image :geo_location, image[:geo_location]   if image[:geo_location]
              builder.image :title, image[:title]                 if image[:title]
              builder.image :license, image[:license]             if image[:license]
            end
          end

          self[:videos].each do |video|
            builder.video :video do
              builder.video :thumbnail_loc, video[:thumbnail_loc]
              builder.video :title, video[:title]
              builder.video :description, video[:description]
              builder.video :content_loc, video[:content_loc]           if video[:content_loc]
              if video[:player_loc]
                loc_attributes = { :allow_embed => yes_or_no_with_default(video[:allow_embed], true) }
                loc_attributes[:autoplay] = video[:autoplay] if SitemapGenerator::Utilities.present?(video[:autoplay])
                builder.video :player_loc, video[:player_loc], loc_attributes
              end
              builder.video :duration, video[:duration]                 if video[:duration]
              builder.video :expiration_date,  w3c_date(video[:expiration_date])  if video[:expiration_date]
              builder.video :rating, format_float(video[:rating])       if video[:rating]
              builder.video :view_count, video[:view_count]             if video[:view_count]
              builder.video :publication_date, w3c_date(video[:publication_date]) if video[:publication_date]
              video[:tags].each {|tag| builder.video :tag, tag }        if video[:tags]
              builder.video :tag, video[:tag]                           if video[:tag]
              builder.video :category, video[:category]                 if video[:category]
              builder.video :family_friendly,  yes_or_no_with_default(video[:family_friendly], true) if video.has_key?(:family_friendly)
              builder.video :gallery_loc, video[:gallery_loc], :title => video[:gallery_title] if video[:gallery_loc]
              if video[:uploader]
                builder.video :uploader, video[:uploader], video[:uploader_info] ? { :info => video[:uploader_info] } : {}
              end
            end
          end

          self[:alternates].each do |alternate|
            builder.xhtml :link, :rel => 'alternate', :hreflang => alternate[:lang], :href => alternate[:href]
          end

          unless SitemapGenerator::Utilities.blank?(self[:geo])
            geo = self[:geo]
            builder.geo :geo do
              builder.geo :format, geo[:format] if geo[:format]
            end
          end

          unless SitemapGenerator::Utilities.blank?(self[:mobile])
            builder.mobile :mobile
          end
        end
        builder << '' # Force to string
      end

      def news?
        SitemapGenerator::Utilities.present?(self[:news])
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
        if date.is_a?(String)
          date
        elsif date.respond_to?(:iso8601)
          date.iso8601.sub(/Z$/i, '+00:00')
        elsif date.is_a?(Date) && !date.is_a?(DateTime)
          date.strftime("%Y-%m-%d")
        else
          zulutime = if date.is_a?(DateTime)
            date.new_offset(0)
          elsif date.respond_to?(:utc)
            date.utc
          else
            nil
          end

          if zulutime
            zulutime.strftime("%Y-%m-%dT%H:%M:%S+00:00")
          else
            zone = date.strftime('%z').insert(-3, ':')
            date.strftime("%Y-%m-%dT%H:%M:%S") + zone
          end
        end
      end

      # Accept a string or boolean and return 'yes' or 'no'.  If a string, the
      # value must be 'yes' or 'no'.  Pass the default value as a boolean using `default`.
      def yes_or_no(value)
        if value.is_a?(String)
          raise ArgumentError.new("Unrecognized value for yes/no field: #{value.inspect}") unless value =~ /^(yes|no)$/i
          value.downcase
        else
          value ? 'yes' : 'no'
        end
      end

      # If the value is nil, return `default` converted to either 'yes' or 'no'.
      # If the value is set, return its value converted to 'yes' or 'no'.
      def yes_or_no_with_default(value, default)
        yes_or_no(value.nil? ? default : value)
      end

      # Format a float to to one decimal precision.
      # TODO: Use rounding with precision once merged with framework_agnostic.
      def format_float(value)
        value.is_a?(String) ? value : ('%0.1f' % value)
      end
    end
  end
end
