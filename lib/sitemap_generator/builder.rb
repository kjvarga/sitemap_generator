# frozen_string_literal: true

require 'sitemap_generator/builder/sitemap_file'
require 'sitemap_generator/builder/sitemap_index_file'
require 'sitemap_generator/builder/sitemap_url'
require 'sitemap_generator/builder/sitemap_index_url'

module SitemapGenerator::Builder
  LinkHolder = Struct.new(:link, :options)
end
