require 'spec_helper'

RSpec.describe 'SitemapGenerator' do

  it 'should generate sitemaps without blocks' do
    sitemap = SitemapGenerator::Sitemap.create(default_host: 'http://www.example.com', compress: false)

    sitemap.add('/home')

    blog_group = sitemap.group(filename: :blog, default_host: 'http://example.com/blog')
    blog_group.add('post1')
    blog_group.finalize!

    news_group = sitemap.group(filename: :news, default_host: 'http://example.com/news')
    news_group.add('news1')
    news_group.add('news2')
    news_group.finalize!

    sitemap.finalize!
  end
end
