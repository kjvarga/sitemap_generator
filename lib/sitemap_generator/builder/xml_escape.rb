# frozen_string_literal: true

require 'builder'

module SitemapGenerator
  module Builder
    # Fast XML escaping that produces exactly the same output as Builder::XmlMarkup.
    #
    # Most sitemap values (URLs, dates, numbers) are plain ASCII with nothing to escape,
    # so they are returned as-is. Anything else goes through Builder's own encoder so
    # that CP1252 fix-ups, invalid character replacement and re-encoding stay identical.
    module XmlEscape
      # ASCII characters that Builder escapes or replaces in text nodes.
      TEXT_UNSAFE = /[&<>\x00-\x08\x0B\x0C\x0E-\x1F]/.freeze
      # ASCII characters that Builder escapes or replaces in attribute values.
      ATTRIBUTE_UNSAFE = /[&<>"\x00-\x1F]/.freeze

      module_function

      # Escape a value for use as XML text content.
      def escape_text(value)
        string = value.to_s
        return string if string.ascii_only? && !TEXT_UNSAFE.match?(string)

        encode(string)
      end

      # Escape a value for use as a double-quoted XML attribute value.
      # Symbols are not escaped, matching Builder::XmlMarkup.
      def escape_attribute(value)
        return value.to_s if value.is_a?(Symbol)

        string = value.to_s
        return string if string.ascii_only? && !ATTRIBUTE_UNSAFE.match?(string)

        encode(string).gsub("\n", '&#10;').gsub("\r", '&#13;').gsub('"', '&quot;')
      end

      # Same as Builder::XmlBase#_escape with the default UTF-8 encoding.
      def encode(string)
        ::Builder::XChar.encode(string).encode(Encoding::UTF_8)
      end
    end
  end
end
