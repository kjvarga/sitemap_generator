# require "sitemap_generator/core_ext/big_decimal/conversions"
require "sitemap_generator/utilities"

module SitemapGenerator
  # = SitemapGenerator Number Helpers
  module Helpers #:nodoc:

    # Provides methods for converting numbers into formatted strings.
    # Methods are provided for precision, positional notation and file size
    # and pretty printing.
    #
    # Most methods expect a +number+ argument, and will return it
    # unchanged if can't be converted into a valid number.
    module NumberHelper

      # Raised when argument +number+ param given to the helpers is invalid and
      # the option :raise is set to  +true+.
      class InvalidNumberError < StandardError
        attr_accessor :number
        def initialize(number)
          @number = number
        end
      end

      # Formats a +number+ with grouped thousands using +delimiter+ (e.g., 12,324). You can
      # customize the format in the +options+ hash.
      #
      # ==== Options
      # * <tt>:locale</tt>     - Sets the locale to be used for formatting (defaults to current locale).
      # * <tt>:delimiter</tt>  - Sets the thousands delimiter (defaults to ",").
      # * <tt>:separator</tt>  - Sets the separator between the fractional and integer digits (defaults to ".").
      #
      # ==== Examples
      #  number_with_delimiter(12345678)                        # => 12,345,678
      #  number_with_delimiter(12345678.05)                     # => 12,345,678.05
      #  number_with_delimiter(12345678, :delimiter => ".")     # => 12.345.678
      #  number_with_delimiter(12345678, :separator => ",")     # => 12,345,678
      #  number_with_delimiter(12345678.05, :locale => :fr)     # => 12 345 678,05
      #  number_with_delimiter(98765432.98, :delimiter => " ", :separator => ",")
      #  # => 98 765 432,98
      def number_with_delimiter(number, options = {})
        SitemapGenerator::Utilities.symbolize_keys!(options)

        begin
          Float(number)
        rescue ArgumentError, TypeError
          if options[:raise]
            raise InvalidNumberError, number
          else
            return number
          end
        end

        defaults = {
          :separator => ".",
          :delimiter => ",",
          :precision => 3,
          :significant => false,
          :strip_insignificant_zeros => false
        }
        options = SitemapGenerator::Utilities.reverse_merge(options, defaults)

        parts = number.to_s.to_str.split('.')
        parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")
        parts.join(options[:separator])
      end

      # Formats a +number+ with the specified level of <tt>:precision</tt> (e.g., 112.32 has a precision
      # of 2 if +:significant+ is +false+, and 5 if +:significant+ is +true+).
      # You can customize the format in the +options+ hash.
      #
      # ==== Options
      # * <tt>:locale</tt>     - Sets the locale to be used for formatting (defaults to current locale).
      # * <tt>:precision</tt>  - Sets the precision of the number (defaults to 3).
      # * <tt>:significant</tt>  - If +true+, precision will be the # of significant_digits. If +false+, the # of fractional digits (defaults to +false+)
      # * <tt>:separator</tt>  - Sets the separator between the fractional and integer digits (defaults to ".").
      # * <tt>:delimiter</tt>  - Sets the thousands delimiter (defaults to "").
      # * <tt>:strip_insignificant_zeros</tt>  - If +true+ removes insignificant zeros after the decimal separator (defaults to +false+)
      #
      # ==== Examples
      #  number_with_precision(111.2345)                                            # => 111.235
      #  number_with_precision(111.2345, :precision => 2)                           # => 111.23
      #  number_with_precision(13, :precision => 5)                                 # => 13.00000
      #  number_with_precision(389.32314, :precision => 0)                          # => 389
      #  number_with_precision(111.2345, :significant => true)                      # => 111
      #  number_with_precision(111.2345, :precision => 1, :significant => true)     # => 100
      #  number_with_precision(13, :precision => 5, :significant => true)           # => 13.000
      #  number_with_precision(111.234, :locale => :fr)                             # => 111,234
      #  number_with_precision(13, :precision => 5, :significant => true, strip_insignificant_zeros => true)
      #  # => 13
      #  number_with_precision(389.32314, :precision => 4, :significant => true)    # => 389.3
      #  number_with_precision(1111.2345, :precision => 2, :separator => ',', :delimiter => '.')
      #  # => 1.111,23
      def number_with_precision(number, options = {})
        SitemapGenerator::Utilities.symbolize_keys!(options)

        number = begin
          Float(number)
        rescue ArgumentError, TypeError
          if options[:raise]
            raise InvalidNumberError, number
          else
            return number
          end
        end

        defaults = {
          :separator => ".",
          :delimiter => ",",
          :precision => 3,
          :significant => false,
          :strip_insignificant_zeros => false
        }
        precision_defaults = {
          :delimiter => ""
        }
        defaults = defaults.merge(precision_defaults)

        options = SitemapGenerator::Utilities.reverse_merge(options, defaults)  # Allow the user to unset default values: Eg.: :significant => false
        precision = options.delete :precision
        significant = options.delete :significant
        strip_insignificant_zeros = options.delete :strip_insignificant_zeros

        if significant and precision > 0
          if number == 0
            digits, rounded_number = 1, 0
          else
            digits = (Math.log10(number.abs) + 1).floor
            rounded_number = (BigDecimal(number.to_s) / BigDecimal((10 ** (digits - precision)).to_f.to_s)).round.to_f * 10 ** (digits - precision)
            digits = (Math.log10(rounded_number.abs) + 1).floor # After rounding, the number of digits may have changed
          end
          precision = precision - digits
          precision = precision > 0 ? precision : 0  #don't let it be negative
        else
          rounded_number = SitemapGenerator::Utilities.round(BigDecimal(number.to_s), precision).to_f
        end
        formatted_number = number_with_delimiter("%01.#{precision}f" % rounded_number, options)
        if strip_insignificant_zeros
          escaped_separator = Regexp.escape(options[:separator])
          formatted_number.sub(/(#{escaped_separator})(\d*[1-9])?0+\z/, '\1\2').sub(/#{escaped_separator}\z/, '')
        else
          formatted_number
        end

      end

      STORAGE_UNITS = [:byte, :kb, :mb, :gb, :tb].freeze
      DECIMAL_UNITS = {0 => :unit, 1 => :ten, 2 => :hundred, 3 => :thousand, 6 => :million, 9 => :billion, 12 => :trillion, 15 => :quadrillion,
        -1 => :deci, -2 => :centi, -3 => :mili, -6 => :micro, -9 => :nano, -12 => :pico, -15 => :femto}.freeze

      # Formats the bytes in +number+ into a more understandable representation
      # (e.g., giving it 1500 yields 1.5 KB). This method is useful for
      # reporting file sizes to users. You can customize the
      # format in the +options+ hash.
      #
      # See <tt>number_to_human</tt> if you want to pretty-print a generic number.
      #
      # ==== Options
      # * <tt>:locale</tt>     - Sets the locale to be used for formatting (defaults to current locale).
      # * <tt>:precision</tt>  - Sets the precision of the number (defaults to 3).
      # * <tt>:significant</tt>  - If +true+, precision will be the # of significant_digits. If +false+, the # of fractional digits (defaults to +true+)
      # * <tt>:separator</tt>  - Sets the separator between the fractional and integer digits (defaults to ".").
      # * <tt>:delimiter</tt>  - Sets the thousands delimiter (defaults to "").
      # * <tt>:strip_insignificant_zeros</tt>  - If +true+ removes insignificant zeros after the decimal separator (defaults to +true+)
      # ==== Examples
      #  number_to_human_size(123)                                          # => 123 Bytes
      #  number_to_human_size(1234)                                         # => 1.21 KB
      #  number_to_human_size(12345)                                        # => 12.1 KB
      #  number_to_human_size(1234567)                                      # => 1.18 MB
      #  number_to_human_size(1234567890)                                   # => 1.15 GB
      #  number_to_human_size(1234567890123)                                # => 1.12 TB
      #  number_to_human_size(1234567, :precision => 2)                     # => 1.2 MB
      #  number_to_human_size(483989, :precision => 2)                      # => 470 KB
      #  number_to_human_size(1234567, :precision => 2, :separator => ',')  # => 1,2 MB
      #
      # Non-significant zeros after the fractional separator are stripped out by default (set
      # <tt>:strip_insignificant_zeros</tt> to +false+ to change that):
      #  number_to_human_size(1234567890123, :precision => 5)        # => "1.1229 TB"
      #  number_to_human_size(524288000, :precision=>5)              # => "500 MB"
      def number_to_human_size(number, options = {})
        SitemapGenerator::Utilities.symbolize_keys!(options)

        number = begin
          Float(number)
        rescue ArgumentError, TypeError
          if options[:raise]
            raise InvalidNumberError, number
          else
            return number
          end
        end

        defaults = {
          :separator => ".",
          :delimiter => ",",
          :precision => 3,
          :significant => false,
          :strip_insignificant_zeros => false
        }
        human = {
          :delimiter => "",
          :precision => 3,
          :significant => true,
          :strip_insignificant_zeros => true
        }
        defaults = defaults.merge(human)
        options = SitemapGenerator::Utilities.reverse_merge(options, defaults)
        #for backwards compatibility with those that didn't add strip_insignificant_zeros to their locale files
        options[:strip_insignificant_zeros] = true if not options.key?(:strip_insignificant_zeros)

        storage_units_format = "%n %u"

        if number.to_i < 1024
          unit = number.to_i > 1 || number.to_i == 0 ? 'Bytes' : 'Byte'
          storage_units_format.gsub(/%n/, number.to_i.to_s).gsub(/%u/, unit)
        else
          max_exp  = STORAGE_UNITS.size - 1
          exponent = (Math.log(number) / Math.log(1024)).to_i # Convert to base 1024
          exponent = max_exp if exponent > max_exp # we need this to avoid overflow for the highest unit
          number  /= 1024 ** exponent

          unit_key = STORAGE_UNITS[exponent]
          units = {
            :byte => "Bytes",
            :kb => "KB",
            :mb => "MB",
            :gb => "GB",
            :tb => "TB"
          }
          unit = units[unit_key]
          formatted_number = number_with_precision(number, options)
          storage_units_format.gsub(/%n/, formatted_number).gsub(/%u/, unit)
        end
      end
    end
  end
end
