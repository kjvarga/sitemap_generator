# frozen_string_literal: true

require 'sitemap_generator/builder/xml_escape'
require 'uri'
require 'time'
require 'date'

module SitemapGenerator
  module Builder
    # A Hash-like class for holding information about a sitemap URL and
    # generating an XML <url> element suitable for sitemaps.
    class SitemapUrl < Hash # rubocop:disable Metrics/ClassLength
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

        SitemapGenerator::Utilities.assert_valid_keys(
          options,
          :priority, :changefreq, :lastmod, :expires, :host,
          :images, :video, :news, :videos, :mobile,
          :alternate, :alternates, :pagemap
        )
        SitemapGenerator::Utilities.reverse_merge!(
          options,
          priority: 0.5,
          changefreq: 'weekly',
          lastmod: SitemapGenerator::Utilities.current_time,
          images: [],
          news: {},
          videos: [],
          mobile: false,
          alternates: []
        )
        raise 'Cannot generate a url without a host' unless SitemapGenerator::Utilities.present?(options[:host])

        if (video = options.delete(:video))
          options[:videos] = video.is_a?(Array) ? options[:videos].concat(video) : options[:videos] << video
        end
        if (alternate = options.delete(:alternate))
          options[:alternates] =
            alternate.is_a?(Array) ? options[:alternates].concat(alternate) : options[:alternates] << alternate
        end

        path = encode_non_ascii(path.to_s.sub(%r{^/}, ''))
        loc  = path.empty? ? options[:host] : "#{options[:host].to_s.sub(%r{/$}, '')}/#{path}"
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

      # Return the URL as an XML string.
      #
      # The XML is generated directly, without going through Builder::XmlMarkup, which is
      # much faster. The output is identical to what Builder::XmlMarkup 3.1+ produces with its default options.
      # If a +builder+ is given the XML is appended to it and its target is returned.
      def to_xml(builder = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        xml = +'<url>'
        xml_tag(xml, 'loc', self[:loc])
        xml_tag(xml, 'lastmod', w3c_date(self[:lastmod]))      if self[:lastmod]
        xml_tag(xml, 'expires', w3c_date(self[:expires]))      if self[:expires]
        xml_tag(xml, 'changefreq', self[:changefreq])          if self[:changefreq]
        xml_tag(xml, 'priority', format_float(self[:priority])) if self[:priority]
        news_xml(xml) unless SitemapGenerator::Utilities.blank?(self[:news])
        self[:images].each { |image| image_xml(xml, image) }
        self[:videos].each { |video| video_xml(xml, video) }
        self[:alternates].each { |alternate| alternate_xml(xml, alternate) }
        xml << '<mobile:mobile/>' unless SitemapGenerator::Utilities.blank?(self[:mobile])
        pagemap_xml(xml) unless SitemapGenerator::Utilities.blank?(self[:pagemap])
        xml << '</url>'
        builder.nil? ? xml : builder << xml
      end

      def news?
        SitemapGenerator::Utilities.present?(self[:news])
      end

      protected

      # Append <tt><name attrs>text</name></tt> to +xml+, escaping the text and attribute values.
      def xml_tag(xml, name, text, attributes = nil)
        xml << '<' << name
        xml_attributes(xml, attributes) if attributes
        xml << '>' << XmlEscape.escape_text(text) << '</' << name << '>'
      end

      def xml_attributes(xml, attributes)
        attributes.each do |key, value|
          xml << ' ' << key.to_s << '="' << XmlEscape.escape_attribute(value) << '"'
        end
        xml
      end

      def news_xml(xml) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        news = self[:news]
        xml << '<news:news><news:publication>'
        xml_tag(xml, 'news:name', news[:publication_name])         if news[:publication_name]
        xml_tag(xml, 'news:language', news[:publication_language]) if news[:publication_language]
        xml << '</news:publication>'
        xml_tag(xml, 'news:access', news[:access])                               if news[:access]
        xml_tag(xml, 'news:genres', news[:genres])                               if news[:genres]
        xml_tag(xml, 'news:publication_date', w3c_date(news[:publication_date])) if news[:publication_date]
        xml_tag(xml, 'news:title', news[:title])                                 if news[:title]
        xml_tag(xml, 'news:keywords', news[:keywords])                           if news[:keywords]
        xml_tag(xml, 'news:stock_tickers', news[:stock_tickers])                 if news[:stock_tickers]
        xml << '</news:news>'
      end

      def image_xml(xml, image)
        xml << '<image:image>'
        xml_tag(xml, 'image:loc', image[:loc])
        xml_tag(xml, 'image:caption', image[:caption])           if image[:caption]
        xml_tag(xml, 'image:geo_location', image[:geo_location]) if image[:geo_location]
        xml_tag(xml, 'image:title', image[:title])               if image[:title]
        xml_tag(xml, 'image:license', image[:license])           if image[:license]
        xml << '</image:image>'
      end

      def video_xml(xml, video) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        xml << '<video:video>'
        xml_tag(xml, 'video:thumbnail_loc', video[:thumbnail_loc])
        xml_tag(xml, 'video:title', video[:title])
        xml_tag(xml, 'video:description', video[:description])
        xml_tag(xml, 'video:content_loc', video[:content_loc]) if video[:content_loc]
        if video[:player_loc]
          loc_attributes = { allow_embed: yes_or_no_with_default(video[:allow_embed], true) }
          loc_attributes[:autoplay] = video[:autoplay].to_s if SitemapGenerator::Utilities.present?(video[:autoplay])
          xml_tag(xml, 'video:player_loc', video[:player_loc], loc_attributes)
        end
        xml_tag(xml, 'video:duration', video[:duration]) if video[:duration]
        xml_tag(xml, 'video:expiration_date', w3c_date(video[:expiration_date])) if video[:expiration_date]
        xml_tag(xml, 'video:rating', format_float(video[:rating])) if video[:rating]
        xml_tag(xml, 'video:view_count', video[:view_count]) if video[:view_count]
        xml_tag(xml, 'video:publication_date', w3c_date(video[:publication_date])) if video[:publication_date]
        video[:tags]&.each { |tag| xml_tag(xml, 'video:tag', tag) }
        xml_tag(xml, 'video:tag', video[:tag]) if video[:tag]
        xml_tag(xml, 'video:category', video[:category]) if video[:category]
        if video.key?(:family_friendly)
          xml_tag(xml, 'video:family_friendly', yes_or_no_with_default(video[:family_friendly], true))
        end
        xml_tag(xml, 'video:gallery_loc', video[:gallery_loc], title: video[:gallery_title].to_s) if video[:gallery_loc]
        if SitemapGenerator::Utilities.present?(video[:price])
          xml_tag(xml, 'video:price', video[:price], prepare_video_price_attribs(video))
        end
        if video[:uploader]
          xml_tag(xml, 'video:uploader', video[:uploader],
                  video[:uploader_info] ? { info: video[:uploader_info].to_s } : nil)
        end
        xml_tag(xml, 'video:live', yes_or_no_with_default(video[:live], true)) if video.key?(:live)
        if video.key?(:requires_subscription)
          xml_tag(xml, 'video:requires_subscription', yes_or_no_with_default(video[:requires_subscription], true))
        end
        xml << '</video:video>'
      end

      def alternate_xml(xml, alternate)
        attributes = { rel: alternate[:nofollow] ? 'alternate nofollow' : 'alternate', href: alternate[:href].to_s }
        attributes[:hreflang] = alternate[:lang].to_s if SitemapGenerator::Utilities.present?(alternate[:lang])
        attributes[:media] = alternate[:media].to_s if SitemapGenerator::Utilities.present?(alternate[:media])
        xml << '<xhtml:link'
        xml_attributes(xml, attributes)
        xml << '/>'
      end

      def pagemap_xml(xml) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        xml << '<pagemap:PageMap>'
        SitemapGenerator::Utilities.as_array(self[:pagemap][:dataobjects]).each do |dataobject|
          xml << '<pagemap:DataObject'
          xml_attributes(xml, type: dataobject[:type].to_s, id: dataobject[:id].to_s)
          xml << '>'
          SitemapGenerator::Utilities.as_array(dataobject[:attributes]).each do |attribute|
            xml_tag(xml, 'pagemap:Attribute', attribute[:value], name: attribute[:name].to_s)
          end
          xml << '</pagemap:DataObject>'
        end
        xml << '</pagemap:PageMap>'
      end

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
            alt.merge(href: URI.join(host, href).to_s)
          else
            alt
          end
        end
      end

      # Return an Array of image option Hashes suitable to be parsed by SitemapGenerator::Builder::SitemapFile
      def prepare_images(images, host)
        images.delete_if { |key, _value| key[:loc].nil? }
        images.each do |r|
          SitemapGenerator::Utilities.assert_valid_keys(r, :loc, :caption, :geo_location, :title, :license)
          r[:loc] = URI.join(host, r[:loc]).to_s
        end
        images[0..(SitemapGenerator::MAX_SITEMAP_IMAGES - 1)]
      end

      def w3c_date(date) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        if date.is_a?(String)
          date
        elsif date.respond_to?(:iso8601)
          date.iso8601.sub(/Z$/i, '+00:00')
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

      # Percent-encode non-ASCII bytes in a path segment, leaving already-encoded %XX sequences untouched.
      # Applied to paths only — not the host — IDN hostnames require punycode, not percent-encoding.
      def encode_non_ascii(str)
        str.gsub(/[^\x00-\x7F]/) { |c| c.bytes.map { |b| format('%%%02X', b) }.join }
      end
    end
  end
end
