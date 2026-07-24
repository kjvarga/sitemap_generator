# frozen_string_literal: true

SitemapGenerator::Sitemap.default_host = 'http://www.example.com'

SitemapGenerator::Sitemap.create do
  add '/contents', priority: 0.7, changefreq: 'daily'

  # add all individual articles
  (1..10).each do |i|
    add "/content/#{i}"
  end

  add '/merchant_path', host: 'https://www.example.com'
end
