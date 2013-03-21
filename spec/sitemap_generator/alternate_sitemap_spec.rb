require 'spec_helper'

describe "SitemapGenerator" do

  it "should add alternate links to sitemap" do
    xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('link_with_alternates.html',
      :host => 'http://www.example.com',
      :alternates => [
        {
          :lang => 'de',
          :href => 'http://www.example.de/link_with_alternate.html'
        }
      ]
    ).to_xml

    doc = Nokogiri::XML.parse("<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{xml_fragment}</root>")
    url = doc.css('url')
    url.should_not be_nil
    url.css('loc').text.should == 'http://www.example.com/link_with_alternates.html'

    alternate = url.at_xpath('xhtml:link')
    alternate.should_not be_nil
    alternate.attribute('rel').value.should == 'alternate'
    alternate.attribute('hreflang').value.should == 'de'
    alternate.attribute('href').value.should == 'http://www.example.de/link_with_alternate.html'
  end

  it "should add alternate links to sitemap with rel nofollow" do
    xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('link_with_alternates.html',
      :host => 'http://www.example.com',
      :alternates => [
        {
          :lang => 'de',
          :href => 'http://www.example.de/link_with_alternate.html',
          :nofollow => true
        }
      ]
    ).to_xml

    doc = Nokogiri::XML.parse("<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{xml_fragment}</root>")
    url = doc.css('url')
    url.should_not be_nil
    url.css('loc').text.should == 'http://www.example.com/link_with_alternates.html'

    alternate = url.at_xpath('xhtml:link')
    alternate.should_not be_nil
    alternate.attribute('rel').value.should == 'alternate nofollow'
    alternate.attribute('hreflang').value.should == 'de'
    alternate.attribute('href').value.should == 'http://www.example.de/link_with_alternate.html'
  end

end

