require 'sitemap_generator/sitemap_namer'
require 'sitemap_generator/builder'
require 'sitemap_generator/link_set'
require 'sitemap_generator/templates'
require 'sitemap_generator/utilities'
require 'sitemap_generator/application'
require 'sitemap_generator/adapters'
require 'sitemap_generator/sitemap_location'
require 'active_support/core_ext/numeric'

module SitemapGenerator
  autoload(:Interpreter, 'sitemap_generator/interpreter')
  autoload(:FileAdapter, 'sitemap_generator/adapters/file_adapter')
  autoload(:WaveAdapter, 'sitemap_generator/adapters/wave_adapter')

  SitemapError = Class.new(StandardError)
  SitemapFullError = Class.new(SitemapError)
  SitemapFinalizedError = Class.new(SitemapError)

  silence_warnings do
    VERSION = File.read(File.dirname(__FILE__) + "/../VERSION").strip
    MAX_SITEMAP_FILES    = 50_000        # max sitemap links per index file
    MAX_SITEMAP_LINKS    = 50_000        # max links per sitemap
    MAX_SITEMAP_IMAGES   = 1_000         # max images per url
    MAX_SITEMAP_NEWS     = 1_000         # max news sitemap per index_file
    MAX_SITEMAP_FILESIZE = 10.megabytes  # bytes

    # Lazy-initialize the LinkSet instance
    Sitemap = (Class.new do
      def method_missing(*args, &block)
        (@link_set ||= reset!).send(*args, &block)
      end

      # Use a new LinkSet instance
      def reset!
        @link_set = LinkSet.new
      end
    end).new
  end

  class << self
    attr_accessor :root, :app, :templates
    attr_writer :yield_sitemap
  end

  # Returns true if we should yield the sitemap instance to the block, false otherwise.
  def self.yield_sitemap?
    !!@yeild_sitemap
  end

  self.root = File.expand_path(File.join(File.dirname(__FILE__), '../'))
  self.templates = SitemapGenerator::Templates.new(self.root)
  self.app = SitemapGenerator::Application.new
end

require 'sitemap_generator/railtie' if SitemapGenerator.app.rails3?
