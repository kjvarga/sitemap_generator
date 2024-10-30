require 'spec_helper'

RSpec.describe 'SitemapGenerator' do

  it 'should add the news sitemap element' do
    loc = 'http://www.example.com/my_article.html'

    news_xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('my_article.html', {
      :host => 'http://www.example.com',

      :news => {
        :publication_name => 'Example',
        :publication_language => 'en',
        :title => 'My Article',
        :keywords => 'my article, articles about myself',
        :stock_tickers => 'SAO:PETR3',
        :publication_date => '2011-08-22',
        :access => 'Subscription',
        :genres => 'PressRelease'
      }
    }).to_xml

    doc = Nokogiri::XML.parse("<root xmlns:news='#{SitemapGenerator::SCHEMAS['news']}'>#{news_xml_fragment}</root>")

    url = doc.at_xpath('//url')
    loc = url.at_xpath('loc')
    expect(loc.text).to eq('http://www.example.com/my_article.html')

    news = doc.at_xpath('//news:news')

    expect(news.at_xpath('//news:title').text).to eq('My Article')
    expect(news.at_xpath('//news:keywords').text).to eq('my article, articles about myself')
    expect(news.at_xpath('//news:stock_tickers').text).to eq('SAO:PETR3')
    expect(news.at_xpath('//news:publication_date').text).to eq('2011-08-22')
    expect(news.at_xpath('//news:access').text).to eq('Subscription')
    expect(news.at_xpath('//news:genres').text).to eq('PressRelease')
    expect(news.at_xpath('//news:name').text).to eq('Example')
    expect(news.at_xpath('//news:language').text).to eq('en')

    xml_fragment_should_validate_against_schema(news, 'sitemap-news', 'xmlns:news' => SitemapGenerator::SCHEMAS['news'])
  end
end
