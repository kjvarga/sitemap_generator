require 'spec_helper'

describe "SitemapGenerator" do

  it "should add the news sitemap element" do
    loc = 'http://www.example.com/my_article.html'

    news_xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('my_article.html', {
      :host => 'http://www.example.com',

      :news => {
        :publication_name => "Example",
        :publication_language => "en",
        :title => "My Article",
        :keywords => "my article, articles about myself",
        :stock_tickers => "SAO:PETR3",
        :publication_date => "2011-08-22",
        :access => "Subscription",
        :genres => "PressRelease"
      }
    }).to_xml

    doc = Nokogiri::XML.parse("<root xmlns:news='http://www.google.com/schemas/sitemap-news/0.9'>#{news_xml_fragment}</root>")

    url = doc.at_xpath("//url")
    loc = url.at_xpath("loc")
    loc.text.should == 'http://www.example.com/my_article.html'

    news = doc.at_xpath("//news:news")

    news.at_xpath('//news:title').text.should == "My Article"
    news.at_xpath("//news:keywords").text.should == "my article, articles about myself"
    news.at_xpath("//news:stock_tickers").text.should == "SAO:PETR3"
    news.at_xpath("//news:publication_date").text.should == "2011-08-22"
    news.at_xpath("//news:access").text.should == "Subscription"
    news.at_xpath("//news:genres").text.should == "PressRelease"
    news.at_xpath("//news:name").text.should == "Example"
    news.at_xpath("//news:language").text.should == "en"

    xml_fragment_should_validate_against_schema(news, 'http://www.google.com/schemas/sitemap-news/0.9', 'sitemap-news')
  end
end
