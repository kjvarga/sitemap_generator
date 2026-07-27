# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SitemapGenerator' do
  it 'adds the mobile sitemap element' do
    expect_valid_mobile_sitemap_element('http://www.example.com/mobile_page.html')
  end

  def expect_valid_mobile_sitemap_element(loc)
    url = mobile_sitemap_url_node
    expect(url).not_to be_nil
    expect(url.at_xpath('loc').text).to eq(loc)

    mobile = url.at_xpath('mobile:mobile')
    expect(mobile).not_to be_nil
    # Google's documentation and published schema don't match, so some valid elements
    # may not validate.
    expect_xml_fragment_to_validate_against_schema(mobile, 'sitemap-mobile', 'xmlns:mobile' => SitemapGenerator::SCHEMAS['mobile'])
  end

  def mobile_sitemap_url_node
    mobile_xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('mobile_page.html',
                                                                    host: 'http://www.example.com',
                                                                    mobile: true).to_xml
    doc = Nokogiri::XML.parse("<root xmlns:mobile='#{SitemapGenerator::SCHEMAS['mobile']}'>#{mobile_xml_fragment}</root>")
    doc.at_xpath('//url')
  end
end
