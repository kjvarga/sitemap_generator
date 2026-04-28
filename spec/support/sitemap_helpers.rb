module SitemapHelpers
  def with_max_links(num)
    original = SitemapGenerator::Sitemap.max_sitemap_links
    SitemapGenerator::Sitemap.max_sitemap_links = num
    yield
  ensure
    SitemapGenerator::Sitemap.max_sitemap_links = original
  end
end
