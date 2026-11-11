# frozen_string_literal: true

require 'builder'
require 'uri'
require 'time'
require 'date'

module SitemapGenerator
  module Builder
    # A Hash-like class for holding information about a sitemap URL and
    # generating an XML <url> element suitable for sitemaps.
    class SitemapUrl < Hash # rubocop:disable Metrics/ClassLength
      VALID_OPTIONS = %i[
        priority changefreq lastmod expires host images video news videos mobile alternate alternates pagemap
      ].freeze
      DEFAULT_OPTIONS = { priority: 0.5, changefreq: 'weekly', mobile: false }.freeze
      LIST_OPTIONS = %i[images videos alternates].freeze # default to a new empty Array
      # Paths and queries made only of characters that URI never escapes or normalizes.
      SIMPLE_PATH_AND_QUERY = '(?:/(?:[A-Za-z0-9\\-._~]|%\\h\\h)*)+(?:\\?(?:[A-Za-z0-9\\-._~=&]|%\\h\\h)*)?'
      SIMPLE_ABSOLUTE_URL = %r{\Ahttps?://[a-z0-9-]+(?:\.[a-z0-9-]+)*(?:#{SIMPLE_PATH_AND_QUERY})?\z}.freeze
      SIMPLE_ABSOLUTE_PATH = %r{\A(?!//)#{SIMPLE_PATH_AND_QUERY}\z}.freeze # not a protocol-relative URL
      DOT_SEGMENT = %r{/\.\.?(?:/|\?|\z)}.freeze
      private_constant :VALID_OPTIONS, :DEFAULT_OPTIONS, :LIST_OPTIONS, :SIMPLE_PATH_AND_QUERY, :SIMPLE_ABSOLUTE_URL,
                       :SIMPLE_ABSOLUTE_PATH, :DOT_SEGMENT

      # Caches used by #join_url and #w3c_time. They are replaced, never modified, so they are thread-safe.
      @host_uri_cache = {}.freeze
      @w3c_time_cache = nil
      class << self
        attr_accessor :host_uri_cache, :w3c_time_cache # :nodoc:
      end

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
      # * +host+
      # * +priority+
      # * +changefreq+
      # * +lastmod+
      # * +images+
      # * +video+/+videos+
      # * +news+
      # * +mobile+
      # * +alternate+/+alternates+
      # * +pagemap+
      def initialize(path, options = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        super()
        options = SitemapGenerator::Utilities.symbolize_keys(options)
        if (sitemap = path.is_a?(SitemapGenerator::Builder::SitemapFile) && path)
          SitemapGenerator::Utilities.reverse_merge!(
            options,
            host: sitemap.location.host,
            lastmod: sitemap.lastmod
          )
          path = sitemap.location.path_in_public
        end

        SitemapGenerator::Utilities.assert_valid_keys(options, *VALID_OPTIONS)
        DEFAULT_OPTIONS.each { |key, value| options[key] = value unless options.key?(key) }
        LIST_OPTIONS.each { |key| options[key] = [] unless options.key?(key) }
        options[:news] = {} unless options.key?(:news)
        # Only look up the current time when it is needed.
        options[:lastmod] = SitemapGenerator::Utilities.current_time unless options.key?(:lastmod)
        raise 'Cannot generate a url without a host' unless SitemapGenerator::Utilities.present?(options[:host])

        # Build new arrays rather than appending to the caller's arrays, which may be reused across URLs.
        if (video = options.delete(:video))
          options[:videos] = options[:videos] + (video.is_a?(Array) ? video : [video])
        end
        if (alternate = options.delete(:alternate))
          options[:alternates] = options[:alternates] + (alternate.is_a?(Array) ? alternate : [alternate])
        end

        path = encode_non_ascii(remove_leading_slash(path.to_s))
        loc  = path.empty? ? options[:host] : "#{remove_trailing_slash(options[:host].to_s)}/#{path}"
        merge!(
          priority: options[:priority],
          changefreq: options[:changefreq],
          lastmod: options[:lastmod],
          expires: options[:expires],
          host: options[:host],
          loc: loc,
          images: prepare_images(options[:images], options[:host]),
          news: prepare_news(options[:news]),
          videos: options[:videos],
          mobile: options[:mobile],
          alternates: prepare_alternates(options[:alternates], options[:host]),
          pagemap: options[:pagemap]
        )
      end

      # Return the URL as XML
      def to_xml(builder = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        builder = ::Builder::XmlMarkup.new if builder.nil?
        builder.url do # rubocop:disable Metrics/BlockLength
          builder.loc        self[:loc]
          builder.lastmod    w3c_date(self[:lastmod])      if self[:lastmod]
          builder.expires    w3c_date(self[:expires])      if self[:expires]
          builder.changefreq self[:changefreq].to_s        if self[:changefreq]
          builder.priority   format_float(self[:priority]) if self[:priority]

          unless SitemapGenerator::Utilities.blank?(self[:news])
            news_data = self[:news]
            builder.news :news do
              builder.news :publication do
                builder.news :name, news_data[:publication_name].to_s if news_data[:publication_name]
                builder.news :language, news_data[:publication_language].to_s if news_data[:publication_language]
              end

              builder.news :access, news_data[:access].to_s if news_data[:access]
              builder.news :genres, news_data[:genres].to_s if news_data[:genres]
              builder.news :publication_date, w3c_date(news_data[:publication_date]) if news_data[:publication_date]
              builder.news :title, news_data[:title].to_s if news_data[:title]
              builder.news :keywords, news_data[:keywords].to_s if news_data[:keywords]
              builder.news :stock_tickers, news_data[:stock_tickers].to_s if news_data[:stock_tickers]
            end
          end

          self[:images].each do |image|
            builder.image :image do
              builder.image :loc, image[:loc]
              builder.image :caption, image[:caption].to_s             if image[:caption]
              builder.image :geo_location, image[:geo_location].to_s   if image[:geo_location]
              builder.image :title, image[:title].to_s                 if image[:title]
              builder.image :license, image[:license].to_s             if image[:license]
            end
          end

          self[:videos].each do |video| # rubocop:disable Metrics/BlockLength
            builder.video :video do # rubocop:disable Metrics/BlockLength
              builder.video :thumbnail_loc, video[:thumbnail_loc].to_s
              builder.video :title, video[:title].to_s
              builder.video :description, video[:description].to_s
              builder.video :content_loc, video[:content_loc].to_s if video[:content_loc]
              if video[:player_loc]
                loc_attributes = { allow_embed: yes_or_no_with_default(video[:allow_embed], true) }
                if SitemapGenerator::Utilities.present?(video[:autoplay])
                  loc_attributes[:autoplay] = video[:autoplay].to_s
                end
                builder.video :player_loc, video[:player_loc].to_s, loc_attributes
              end
              builder.video :duration, video[:duration].to_s if video[:duration]
              builder.video :expiration_date, w3c_date(video[:expiration_date]) if video[:expiration_date]
              builder.video :rating, format_float(video[:rating]) if video[:rating]
              builder.video :view_count, video[:view_count].to_s if video[:view_count]
              builder.video :publication_date, w3c_date(video[:publication_date]) if video[:publication_date]
              video[:tags]&.each { |tag| builder.video :tag, tag.to_s }
              builder.video :tag, video[:tag].to_s                           if video[:tag]
              builder.video :category, video[:category].to_s                 if video[:category]
              if video.key?(:family_friendly)
                builder.video :family_friendly,
                              yes_or_no_with_default(video[:family_friendly], true)
              end
              if video[:gallery_loc]
                builder.video :gallery_loc, video[:gallery_loc].to_s,
                              title: video[:gallery_title].to_s
              end
              if SitemapGenerator::Utilities.present?(video[:price])
                builder.video :price, video[:price].to_s, prepare_video_price_attribs(video)
              end
              if video[:uploader]
                builder.video :uploader, video[:uploader].to_s,
                              video[:uploader_info] ? { info: video[:uploader_info].to_s } : {}
              end
              builder.video :live, yes_or_no_with_default(video[:live], true) if video.key?(:live)
              if video.key?(:requires_subscription)
                builder.video :requires_subscription,
                              yes_or_no_with_default(video[:requires_subscription],
                                                     true)
              end
            end
          end

          self[:alternates].each do |alternate|
            rel = alternate[:nofollow] ? 'alternate nofollow' : 'alternate'
            attributes = { rel: rel, href: alternate[:href].to_s }
            attributes[:hreflang] = alternate[:lang].to_s if SitemapGenerator::Utilities.present?(alternate[:lang])
            attributes[:media] = alternate[:media].to_s if SitemapGenerator::Utilities.present?(alternate[:media])
            builder.xhtml :link, attributes
          end

          builder.mobile :mobile unless SitemapGenerator::Utilities.blank?(self[:mobile])

          unless SitemapGenerator::Utilities.blank?(self[:pagemap])
            builder.pagemap :PageMap do
              SitemapGenerator::Utilities.as_array(self[:pagemap][:dataobjects]).each do |dataobject|
                builder.pagemap :DataObject, type: dataobject[:type].to_s, id: dataobject[:id].to_s do
                  SitemapGenerator::Utilities.as_array(dataobject[:attributes]).each do |attribute|
                    builder.pagemap :Attribute, attribute[:value].to_s, name: attribute[:name].to_s
                  end
                end
              end
            end
          end
        end
        builder << '' # Force to string
      end

      def news?
        SitemapGenerator::Utilities.present?(self[:news])
      end

      protected

      def prepare_video_price_attribs(video)
        attribs = {}
        attribs[:currency] = video[:price_currency].to_s # required
        attribs[:type] = video[:price_type] if SitemapGenerator::Utilities.present?(video[:price_type])
        if SitemapGenerator::Utilities.present?(video[:price_resolution])
          attribs[:resolution] = video[:price_resolution]
        end
        attribs
      end

      def prepare_news(news)
        unless news.empty?
          SitemapGenerator::Utilities.assert_valid_keys(
            news,
            :publication_name, :publication_language, :publication_date,
            :genres, :access, :title, :keywords, :stock_tickers
          )
        end
        news
      end

      # Return an Array of alternate option Hashes with relative hrefs expanded to absolute URLs.
      def prepare_alternates(alternates, host)
        alternates.map do |alt|
          next alt unless alt.is_a?(Hash)

          href = alt[:href].to_s
          if href.start_with?('/')
            alt.merge(href: join_url(host, href))
          else
            alt
          end
        end
      end

      # Return an Array of image option Hashes suitable to be parsed by SitemapGenerator::Builder::SitemapFile
      #
      # The caller's images are not modified: they are often shared between URLs, and possibly
      # between groups with different hosts, so each image loc must be resolved against this URL's host.
      def prepare_images(images, host)
        images = images.reject { |image| image[:loc].nil? }
        images.each do |image|
          SitemapGenerator::Utilities.assert_valid_keys(image, :loc, :caption, :geo_location, :title, :license)
        end
        images.first(SitemapGenerator::MAX_SITEMAP_IMAGES).map do |image|
          image.merge(loc: join_url(host, image[:loc]))
        end
      end

      def w3c_date(date) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        if date.is_a?(String)
          date
        elsif date.respond_to?(:iso8601)
          # Time includes ActiveSupport::TimeWithZone
          date.is_a?(Time) ? w3c_time(date) : date.iso8601.sub(/Z$/i, '+00:00')
        elsif date.is_a?(Date) && !date.is_a?(DateTime)
          date.strftime('%Y-%m-%d')
        else
          zulutime =
            if date.is_a?(DateTime)
              date.new_offset(0)
            elsif date.respond_to?(:utc)
              date.utc
            elsif date.is_a?(Integer)
              Time.at(date).utc
            end

          if zulutime
            zulutime.strftime('%Y-%m-%dT%H:%M:%S+00:00')
          else
            zone = date.strftime('%z').insert(-3, ':')
            date.strftime('%Y-%m-%dT%H:%M:%S') + zone
          end
        end
      end

      # Accept a string or boolean and return 'yes' or 'no'.  If a string, the
      # value must be 'yes' or 'no'.  Pass the default value as a boolean using `default`.
      def yes_or_no(value)
        if value.is_a?(String)
          unless /^(yes|no)$/i.match?(value)
            raise ArgumentError, "Unrecognized value for yes/no field: #{value.inspect}"
          end

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
        value.is_a?(String) ? value : format('%0.1f', value)
      end

      private

      # Same as URI.join(host, url).to_s, but faster.
      #
      # Each host is parsed only once, and URLs made only of characters that URI never
      # escapes or normalizes (an absolute http(s) URL or an absolute path, without dot
      # segments) are joined without parsing them.
      def join_url(host, url)
        return URI.join(host, url).to_s unless host.is_a?(String)

        base, origin = host_uri(host)
        if url.is_a?(String) && !DOT_SEGMENT.match?(url)
          # A new UTF-8 String, like URI.join, not the caller's (nor a subclass or another encoding).
          return String.new(url, encoding: Encoding::UTF_8) if SIMPLE_ABSOLUTE_URL.match?(url)
          return origin + url if origin && SIMPLE_ABSOLUTE_PATH.match?(url)
        end
        base.merge(url).to_s
      end

      # Return the parsed host URI and its origin (the URI without path, query and fragment),
      # or nil for the origin if the host is not an absolute http(s) URI.
      def host_uri(host)
        cache = SitemapUrl.host_uri_cache
        cache[host] || begin
          base = URI.parse(host)
          entry = [base, uri_origin(base)].freeze
          # Copy-on-write so readers in other threads never see a Hash being modified.
          SitemapUrl.host_uri_cache = (cache.size < 100 ? cache : {}).merge(host.dup.freeze => entry).freeze
          entry
        end
      end

      def uri_origin(uri)
        # Other schemes (URI::FTP keeps a "/" path) go through URI#merge, as with URI.join.
        return unless uri.is_a?(URI::HTTP) && uri.host

        origin = uri.dup
        origin.path = ''
        origin.query = nil
        origin.fragment = nil
        origin.to_s
      end

      # Format a Time as W3C datetime, caching the last result. URLs often share a lastmod,
      # or get the current time by default, so consecutive URLs usually format the same second.
      def w3c_time(time)
        cached = SitemapUrl.w3c_time_cache
        # A copy for each caller, as when it was formatted each time: a caller may modify it.
        return cached[3].dup if w3c_time_cached?(cached, time)

        formatted = time.iso8601.sub(/Z$/i, '+00:00')
        SitemapUrl.w3c_time_cache = [time.to_i, time.utc_offset, time.class, formatted.dup].freeze
        formatted
      end

      def w3c_time_cached?(cached, time)
        cached && cached[0] == time.to_i && cached[1] == time.utc_offset && cached[2].equal?(time.class)
      end

      # Same as path.sub(%r{^/}, '') without a regexp in the common case.
      def remove_leading_slash(path)
        path.start_with?('/') ? path[1..] : path.sub(%r{^/}, '')
      end

      # Same as host.sub(%r{/$}, '') without a regexp in the common case (a host without newlines).
      def remove_trailing_slash(host)
        return host.sub(%r{/$}, '') if host.include?("\n")

        host.end_with?('/') ? host[0..-2] : host
      end

      # Percent-encode non-ASCII bytes in a path segment, leaving already-encoded %XX sequences untouched.
      # Applied to paths only — not the host — IDN hostnames require punycode, not percent-encoding.
      def encode_non_ascii(str)
        return str if str.ascii_only?

        str.gsub(/[^\x00-\x7F]/) { |c| c.bytes.map { |b| format('%%%02X', b) }.join }
      end
    end
  end
end
