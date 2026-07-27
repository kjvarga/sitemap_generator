# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SitemapGenerator' do
  let(:news_options) do
    {
      publication_name: 'Example',
      publication_language: 'en',
      title: 'My Article',
      keywords: 'my article, articles about myself',
      stock_tickers: 'SAO:PETR3',
      publication_date: '2011-08-22',
      access: 'Subscription',
      genres: 'PressRelease'
    }
  end

  it 'adds the news sitemap element' do
    expect_valid_news_sitemap_element
  end

  def expect_valid_news_sitemap_element
    doc = news_sitemap_doc
    expect(doc.at_xpath('//url/loc').text).to eq('http://www.example.com/my_article.html')

    news = doc.at_xpath('//news:news')
    expect_valid_news_publication_info(news)
    expect_valid_news_content_fields(news)
    expect_xml_fragment_to_validate_against_schema(news, 'sitemap-news', 'xmlns:news' => SitemapGenerator::SCHEMAS['news'])
  end

  def news_sitemap_doc
    news_xml_fragment = SitemapGenerator::Builder::SitemapUrl.new(
      'my_article.html', host: 'http://www.example.com', news: news_options
    ).to_xml
    Nokogiri::XML.parse("<root xmlns:news='#{SitemapGenerator::SCHEMAS['news']}'>#{news_xml_fragment}</root>")
  end

  def expect_valid_news_publication_info(news)
    expect(news.at_xpath('//news:name').text).to eq(news_options[:publication_name])
    expect(news.at_xpath('//news:language').text).to eq(news_options[:publication_language])
  end

  def expect_valid_news_content_fields(news)
    expect_valid_news_title_and_keywords(news)
    expect_valid_news_stock_and_date(news)
    expect_valid_news_access_and_genres(news)
  end

  def expect_valid_news_title_and_keywords(news)
    expect(news.at_xpath('//news:title').text).to eq(news_options[:title])
    expect(news.at_xpath('//news:keywords').text).to eq(news_options[:keywords])
  end

  def expect_valid_news_stock_and_date(news)
    expect(news.at_xpath('//news:stock_tickers').text).to eq(news_options[:stock_tickers])
    expect(news.at_xpath('//news:publication_date').text).to eq(news_options[:publication_date])
  end

  def expect_valid_news_access_and_genres(news)
    expect(news.at_xpath('//news:access').text).to eq(news_options[:access])
    expect(news.at_xpath('//news:genres').text).to eq(news_options[:genres])
  end
end
