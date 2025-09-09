# frozen_string_literal: true

module SitemapGenerator
  module Utilities
    extend self

    # Copy templates/sitemap.rb to config if not there yet.
    def install_sitemap_rb(verbose = false)
      if File.exist?(SitemapGenerator.app.root + 'config/sitemap.rb')
        puts 'already exists: config/sitemap.rb, file not copied' if verbose
      else
        FileUtils.cp(
          SitemapGenerator.templates.template_path(:sitemap_sample),
          SitemapGenerator.app.root + 'config/sitemap.rb')
        puts 'created: config/sitemap.rb' if verbose
      end
    end

    # Remove config/sitemap.rb if exists.
    def uninstall_sitemap_rb
      if File.exist?(SitemapGenerator.app.root + 'config/sitemap.rb')
        File.rm(SitemapGenerator.app.root + 'config/sitemap.rb')
      end
    end

    # Clean sitemap files in output directory.
    def clean_files
      FileUtils.rm(Dir[SitemapGenerator.app.root + 'public/sitemap*.xml.gz'])
    end

    # Validate all keys in a hash match *valid keys, raising ArgumentError on a
    # mismatch. Note that keys are NOT treated indifferently, meaning if you use
    # strings for keys but assert symbols as keys, this will fail.
    def assert_valid_keys(hash, *valid_keys)
      unknown_keys = hash.keys - [valid_keys].flatten
      raise(ArgumentError, "Unknown key(s): #{unknown_keys.join(', ')}") unless unknown_keys.empty?
    end

    # Return a new hash with all keys converted to symbols, as long as
    # they respond to +to_sym+.
    def symbolize_keys(hash)
      symbolize_keys!(hash.dup)
    end

    # Destructively convert all keys to symbols, as long as they respond
    # to +to_sym+.
    def symbolize_keys!(hash)
      hash.keys.each do |key|
        hash[(key.to_sym rescue key) || key] = hash.delete(key)
      end
      hash
    end

    # Make a list of `value` if it is not a list already.  If `value` is
    # nil, an empty list is returned.  If `value` is already a list, return it unchanged.
    def as_array(value)
      if value.nil?
        []
      elsif value.is_a?(Array)
        value
      else
        [value]
      end
    end

    # Rounds the float with the specified precision.
    #
    #   x = 1.337
    #   x.round    # => 1
    #   x.round(1) # => 1.3
    #   x.round(2) # => 1.34
    def round(float, precision = nil)
      if precision
        magnitude = 10.0**precision
        (float * magnitude).round / magnitude
      else
        float.round
      end
    end

    # Allows for reverse merging two hashes where the keys in the calling hash take precedence over those
    # in the <tt>other_hash</tt>. This is particularly useful for initializing an option hash with default values:
    #
    #   def setup(options = {})
    #     options.reverse_merge! :size => 25, :velocity => 10
    #   end
    #
    # Using <tt>merge</tt>, the above example would look as follows:
    #
    #   def setup(options = {})
    #     { :size => 25, :velocity => 10 }.merge(options)
    #   end
    #
    # The default <tt>:size</tt> and <tt>:velocity</tt> are only set if the +options+ hash passed in doesn't already
    # have the respective key.
    def reverse_merge(hash, other_hash)
      other_hash.merge(hash)
    end

    # Performs the opposite of <tt>merge</tt>, with the keys and values from the first hash taking precedence over the second.
    # Modifies the receiver in place.
    def reverse_merge!(hash, other_hash)
      hash.merge!(other_hash) { |k, o, n| o }
    end

    # An object is blank if it's false, empty, or a whitespace string.
    # For example, "", "   ", +nil+, [], and {} are blank.
    #
    # This simplifies:
    #
    #   if !address.nil? && !address.empty?
    #
    # ...to:
    #
    #   if !address.blank?
    def blank?(object) # rubocop:disable Metrics/MethodLength
      case object
      when NilClass, FalseClass
        true
      when TrueClass, Numeric
        false
      when String
        object !~ /\S/
      when Hash, Array
        object.empty?
      when Object
        object.respond_to?(:empty?) ? object.empty? : !object
      end
    end

    # An object is present if it's not blank.
    def present?(object)
      !blank?(object)
    end

    # Sets $VERBOSE for the duration of the block and back to its original value afterwards.
    def with_warnings(flag)
      old_verbose, $VERBOSE = $VERBOSE, flag # rubocop:disable Style/ParallelAssignment
      yield
    ensure
      $VERBOSE = old_verbose
    end

    def titleize(string)
      result = string.tr('_', ' ')
      result.gsub!(/\b\w/) { |match| match.upcase }
      result
    end

    def truthy?(value)
      ['1', 1, 't', 'true', true].include?(value)
    end

    def falsy?(value)
      ['0', 0, 'f', 'false', false].include?(value)
    end

    # Append a slash to `path` if it does not already end in a slash.
    # Returns a string.  Expects a string or Pathname object.
    def append_slash(path)
      strpath = path.to_s
      if !strpath[-1].nil? && strpath[-1].chr != '/'
        strpath + '/'
      else
        strpath
      end
    end

    # Replace the last 3 characters of string with ... if the string is as big
    # or bigger than max.
    def ellipsis(string, max)
      if string.size > max
        (string[0, max - 3] || '') + '...'
      else
        string
      end
    end

    # Return the bytesize length of the string.  Ruby 1.8.6 compatible.
    def bytesize(string)
      string.respond_to?(:bytesize) ? string.bytesize : string.length
    end
  end
end
