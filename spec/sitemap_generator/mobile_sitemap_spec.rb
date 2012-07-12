require 'spec_helper'

describe "SitemapGenerator" do

  it "should add the mobile sitemap element" do
    loc = 'http://www.example.com/mobile_page.html'
    format = 'html'

    mobile_xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('mobile_page.html',
      :host => 'http://www.example.com',
      :mobile => true
    ).to_xml

    # Check that the options were parsed correctly
    doc = Nokogiri::XML.parse("<root xmlns:mobile='http://www.google.com/schemas/sitemap-mobile/1.0'>#{mobile_xml_fragment}</root>")
    url = doc.at_xpath("//url")
    url.should_not be_nil
    url.at_xpath("loc").text.should == loc

    mobile = url.at_xpath("mobile:mobile")
    mobile.should_not be_nil

    # Google's documentation and published schema don't match some valid elements may
    # not validate.
    xml_fragment_should_validate_against_schema(mobile, 'http://www.google.com/schemas/sitemap-mobile/1.0', 'sitemap-mobile')
  end
end
