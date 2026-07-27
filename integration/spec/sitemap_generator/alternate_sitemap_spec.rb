# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SitemapGenerator' do
  it 'does not include media element unless provided' do
    alternate = alternate_link_node(alternates: [{ lang: 'de',
                                                   href: 'http://www.example.de/link_with_alternate.html' }])
    attrs = [alternate.attribute('rel').value, alternate.attribute('hreflang').value, alternate.attribute('media')]
    expect(attrs).to eq(['alternate', 'de', nil])
  end

  it 'adds alternate links to sitemap' do
    alternate = alternate_link_node(alternates: [{
                                      lang: 'de', href: 'http://www.example.de/link_with_alternate.html',
                                      media: 'only screen and (max-width: 640px)'
                                    }])
    expect_valid_alternate_link(alternate, rel: 'alternate')
  end

  it 'adds alternate links to sitemap with rel nofollow' do
    alternate = alternate_link_node(alternates: [{
                                      lang: 'de', href: 'http://www.example.de/link_with_alternate.html',
                                      nofollow: true, media: 'only screen and (max-width: 640px)'
                                    }])
    expect_valid_alternate_link(alternate, rel: 'alternate nofollow')
  end

  it 'supports adding a single alternate link' do
    alternate = alternate_link_node(alternate: {
                                      lang: 'de', href: 'http://www.example.de/link_with_alternate.html', nofollow: true
                                    })
    expect_valid_single_alternate_link(alternate)
  end

  def expect_valid_single_alternate_link(alternate)
    expect(alternate.attribute('rel').value).to eq('alternate nofollow')
    expect(alternate.attribute('hreflang').value).to eq('de')
    expect(alternate.attribute('href').value).to eq('http://www.example.de/link_with_alternate.html')
  end

  def alternate_link_node(**url_options)
    xml_fragment = SitemapGenerator::Builder::SitemapUrl.new(
      'link_with_alternates.html', host: 'http://www.example.com', **url_options
    ).to_xml
    doc = alternate_sitemap_doc(xml_fragment)
    expect_valid_alternate_url(doc.css('url'))
    alternate = doc.css('url').at_xpath('xhtml:link')
    expect(alternate).not_to be_nil
    alternate
  end

  def alternate_sitemap_doc(xml_fragment)
    Nokogiri::XML.parse(
      "<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' " \
      "xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{xml_fragment}</root>"
    )
  end

  def expect_valid_alternate_url(url)
    expect(url).not_to be_nil
    expect(url.css('loc').text).to eq('http://www.example.com/link_with_alternates.html')
  end

  def expect_valid_alternate_link(alternate, rel:)
    expect(alternate.attribute('rel').value).to eq(rel)
    expect(alternate.attribute('hreflang').value).to eq('de')
    expect_valid_alternate_link_href_and_media(alternate)
  end

  def expect_valid_alternate_link_href_and_media(alternate)
    expect(alternate.attribute('href').value).to eq('http://www.example.de/link_with_alternate.html')
    expect(alternate.attribute('media').value).to eq('only screen and (max-width: 640px)')
  end
end
