# frozen_string_literal: true

module SitemapGenerator
  module Builder
    # Wraps a sitemap file reference as a +<sitemap>+ XML entry for use in a sitemap index.
    class SitemapIndexUrl < SitemapUrl
      def initialize(path, options = {})
        if (index = path.is_a?(SitemapGenerator::Builder::SitemapIndexFile) && path)
          options = SitemapGenerator::Utilities.reverse_merge(options, host: index.location.host, lastmod: SitemapGenerator::Utilities.current_time,
                                                                       priority: 1.0)
          path = index.location.path_in_public
        end
        super
      end

      # Return the URL as an XML string. See SitemapUrl#to_xml.
      def to_xml(builder = nil)
        xml = +'<sitemap>'
        xml_tag(xml, 'loc', self[:loc])
        xml_tag(xml, 'lastmod', w3c_date(self[:lastmod])) if self[:lastmod]
        xml << '</sitemap>'
        builder.nil? ? xml : builder << xml
      end
    end
  end
end
