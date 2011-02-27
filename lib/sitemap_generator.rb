require 'sitemap_generator/builder'
require 'sitemap_generator/link_set'
require 'sitemap_generator/templates'
require 'sitemap_generator/utilities'
require 'sitemap_generator/railtie' if SitemapGenerator::Utilities.rails3?

require 'active_support/core_ext/numeric'

module SitemapGenerator
  class SitemapError <StandardError; end
  class SitemapFullError < SitemapError; end
  class SitemapFinalizedError < SitemapError; end
  
  silence_warnings do
    VERSION = File.read(File.dirname(__FILE__) + "/../VERSION").strip
    MAX_SITEMAP_FILES    = 50_000        # max sitemap links per index file
    MAX_SITEMAP_LINKS    = 50_000        # max links per sitemap
    MAX_SITEMAP_IMAGES   = 1_000         # max images per url
    MAX_SITEMAP_FILESIZE = 10.megabytes  # bytes

    Sitemap = LinkSet.new
  end

  class << self
    attr_accessor :root, :templates
  end

  self.root = File.expand_path(File.join(File.dirname(__FILE__), '../'))
  self.templates = SitemapGenerator::Templates.new(self.root)
  
end