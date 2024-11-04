require 'spec_helper'

RSpec.describe 'SitemapGenerator' do

  it 'should add the mobile sitemap element' do
    loc = 'http://www.example.com/mobile_page.html'
    format = 'html'

    mobile_xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('mobile_page.html',
      :host => 'http://www.example.com',
      :mobile => true
    ).to_xml

    # Check that the options were parsed correctly
    doc = Nokogiri::XML.parse("<root xmlns:mobile='#{SitemapGenerator::SCHEMAS['mobile']}'>#{mobile_xml_fragment}</root>")
    url = doc.at_xpath('//url')
    expect(url).not_to be_nil
    expect(url.at_xpath('loc').text).to eq(loc)

    mobile = url.at_xpath('mobile:mobile')
    expect(mobile).not_to be_nil

    # Google's documentation and published schema don't match some valid elements may
    # not validate.
    xml_fragment_should_validate_against_schema(mobile, 'sitemap-mobile', 'xmlns:mobile' => SitemapGenerator::SCHEMAS['mobile'])
  end
end
