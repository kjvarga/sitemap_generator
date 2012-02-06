module SitemapGenerator
  # A class for generating sitemap names given the base for the filename.
  #
  # === Example
  # namer = SitemapNamer.new(:sitemap)
  # namer.to_s => 'sitemap1.xml.gz'
  # namer.next.to_s => 'sitemap2.xml.gz'
  class SitemapNamer
    NameError = Class.new(StandardError)

    attr_reader :base

    # Params:
    #   base - string or symbol that forms the base of the generated filename
    #
    # Options include:
    #   :extension - Default: '.xml.gz'. File extension to append.
    #   :start     - Default: 1. Index at which to start counting.
    def initialize(base, options={});
      @options = SitemapGenerator::Utilities.reverse_merge(options,
        :extension => '.xml.gz',
        :start => 1
      )
      @base = base
      reset
    end

    def to_s
      "#{@base}#{@count}#{@options[:extension]}"
    end

    # Increment count and return self
    def next
      @count += 1
      self
    end

    # Decrement count and return self
    def previous
      raise NameError, "Already at the start of the series" if start?
      @count -= 1
      self
    end

    def start
      @options[:start]
    end

    # Reset count to the starting index
    def reset
      @count = @options[:start]
    end

    def start?
      @count <= @options[:start]
    end
  end

  # A Namer for Sitemap Indexes.  The name never changes.
  class SitemapIndexNamer < SitemapNamer
    def to_s
      "#{@base}#{@options[:extension]}"
    end
  end
end
