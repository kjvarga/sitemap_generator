require 'spec_helper'

describe "SitemapGenerator" do
  it "should not include media element unless provided" do
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
    expect(url).not_to be_nil
    expect(url.css('loc').text).to eq('http://www.example.com/link_with_alternates.html')

    alternate = url.at_xpath('xhtml:link')
    expect(alternate).not_to be_nil
    expect(alternate.attribute('rel').value).to eq('alternate')
    expect(alternate.attribute('hreflang').value).to eq('de')
    expect(alternate.attribute('media')).to be_nil
  end

  it "should add alternate links to sitemap" do
    xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('link_with_alternates.html',
      :host => 'http://www.example.com',
      :alternates => [
        {
          :lang => 'de',
          :href => 'http://www.example.de/link_with_alternate.html',
          :media => 'only screen and (max-width: 640px)'
        }
      ]
    ).to_xml

    doc = Nokogiri::XML.parse("<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{xml_fragment}</root>")
    url = doc.css('url')
    expect(url).not_to be_nil
    expect(url.css('loc').text).to eq('http://www.example.com/link_with_alternates.html')

    alternate = url.at_xpath('xhtml:link')
    expect(alternate).not_to be_nil
    expect(alternate.attribute('rel').value).to eq('alternate')
    expect(alternate.attribute('hreflang').value).to eq('de')
    expect(alternate.attribute('href').value).to eq('http://www.example.de/link_with_alternate.html')
    expect(alternate.attribute('media').value).to eq('only screen and (max-width: 640px)')
  end

  it "should add alternate links to sitemap with rel nofollow" do
    xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('link_with_alternates.html',
      :host => 'http://www.example.com',
      :alternates => [
        {
          :lang => 'de',
          :href => 'http://www.example.de/link_with_alternate.html',
          :nofollow => true,
          :media => 'only screen and (max-width: 640px)'
        }
      ]
    ).to_xml

    doc = Nokogiri::XML.parse("<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{xml_fragment}</root>")
    url = doc.css('url')
    expect(url).not_to be_nil
    expect(url.css('loc').text).to eq('http://www.example.com/link_with_alternates.html')

    alternate = url.at_xpath('xhtml:link')
    expect(alternate).not_to be_nil
    expect(alternate.attribute('rel').value).to eq('alternate nofollow')
    expect(alternate.attribute('hreflang').value).to eq('de')
    expect(alternate.attribute('href').value).to eq('http://www.example.de/link_with_alternate.html')
    expect(alternate.attribute('media').value).to eq('only screen and (max-width: 640px)')
  end

  it "should support adding a single alternate link" do
    xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('link_with_alternates.html',
      :host => 'http://www.example.com',
      :alternate =>
        {
          :lang => 'de',
          :href => 'http://www.example.de/link_with_alternate.html',
          :nofollow => true
        }
    ).to_xml

    doc = Nokogiri::XML.parse("<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{xml_fragment}</root>")
    url = doc.css('url')
    expect(url).not_to be_nil
    expect(url.css('loc').text).to eq('http://www.example.com/link_with_alternates.html')

    alternate = url.at_xpath('xhtml:link')
    expect(alternate).not_to be_nil
    expect(alternate.attribute('rel').value).to eq('alternate nofollow')
    expect(alternate.attribute('hreflang').value).to eq('de')
    expect(alternate.attribute('href').value).to eq('http://www.example.de/link_with_alternate.html')
  end
end

