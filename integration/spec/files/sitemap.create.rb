require File.expand_path('./spec/internal/db/schema.rb')
require File.expand_path('./spec/internal/db/seed.rb')

SitemapGenerator::Sitemap.default_host = "http://www.example.com"

SitemapGenerator::Sitemap.create do
  add contents_path, :priority => 0.7, :changefreq => 'daily'

  # add all individual articles
  Content.all.each do |c|
    add content_path(c), :lastmod => c.updated_at
  end

  add "/merchant_path", :host => "https://www.example.com"
end
