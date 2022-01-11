require 'sitemap_generator/simple_namer'
require 'sitemap_generator/builder'
require 'sitemap_generator/link_set'
require 'sitemap_generator/templates'
require 'sitemap_generator/utilities'
require 'sitemap_generator/application'
require 'sitemap_generator/sitemap_location'

module SitemapGenerator
  autoload(:Interpreter,              'sitemap_generator/interpreter')
  autoload(:FileAdapter,              'sitemap_generator/adapters/file_adapter')
  autoload(:S3Adapter,                'sitemap_generator/adapters/s3_adapter')
  autoload(:AwsSdkAdapter,            'sitemap_generator/adapters/aws_sdk_adapter')
  autoload(:WaveAdapter,              'sitemap_generator/adapters/wave_adapter')
  autoload(:FogAdapter,               'sitemap_generator/adapters/fog_adapter')
  autoload(:GoogleStorageAdapter,     'sitemap_generator/adapters/google_storage_adapter')
  autoload(:BigDecimal,               'sitemap_generator/core_ext/big_decimal')
  autoload(:Numeric,                  'sitemap_generator/core_ext/numeric')

  SitemapError          = Class.new(StandardError)
  SitemapFullError      = Class.new(SitemapError)
  SitemapFinalizedError = Class.new(SitemapError)

  Utilities.with_warnings(nil) do
    VERSION = File.read(File.dirname(__FILE__) + "/../VERSION").strip
    MAX_SITEMAP_FILES    = 50_000        # max sitemap links per index file
    MAX_SITEMAP_LINKS    = 50_000        # max links per sitemap
    MAX_SITEMAP_IMAGES   = 1_000         # max images per url
    MAX_SITEMAP_NEWS     = 1_000         # max news sitemap per index_file
    MAX_SITEMAP_FILESIZE = 50_000_000    # bytes
    SCHEMAS = {
      'image'   => 'http://www.google.com/schemas/sitemap-image/1.1',
      'mobile'  => 'http://www.google.com/schemas/sitemap-mobile/1.0',
      'news'    => 'http://www.google.com/schemas/sitemap-news/0.9',
      'pagemap' => 'http://www.google.com/schemas/sitemap-pagemap/1.0',
      'video'   => 'http://www.google.com/schemas/sitemap-video/1.1'
    }

    # Lazy-initialize the LinkSet instance
    Sitemap = (Class.new do
      def method_missing(*args, &block)
        (@link_set ||= reset!).send(*args, &block)
      end

      def respond_to?(name, include_private = false)
        (@link_set ||= reset!).respond_to?(name, include_private)
      end

      # Use a new LinkSet instance
      def reset!
        @link_set = LinkSet.new
      end
    end).new
  end

  class << self
    attr_accessor :root, :app, :templates
    attr_writer :yield_sitemap, :verbose
  end
  @yield_sitemap = nil

  # Global default for the verbose setting.
  def self.verbose
    if @verbose.nil?
      @verbose = if SitemapGenerator::Utilities.truthy?(ENV['VERBOSE'])
        true
      elsif SitemapGenerator::Utilities.falsy?(ENV['VERBOSE'])
        false
      else
        nil
      end
    else
      @verbose
    end
  end

  # Returns true if we should yield the sitemap instance to the block, false otherwise.
  def self.yield_sitemap?
    !!@yield_sitemap
  end

  self.root      = File.expand_path(File.join(File.dirname(__FILE__), '../'))  # Root of the install dir, not the Rails app
  self.templates = SitemapGenerator::Templates.new(self.root)
  self.app       = SitemapGenerator::Application.new
end

require 'sitemap_generator/railtie' if SitemapGenerator.app.is_at_least_rails3?
