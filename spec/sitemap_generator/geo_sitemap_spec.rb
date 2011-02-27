require 'spec_helper'

describe "SitemapGenerator" do

  it "should add the geo sitemap element" do
    loc = 'http://www.example.com/geo_page.kml'
    format = 'kml'
    
    geo_xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('geo_page.kml', {
      :host => 'http://www.example.com',
      :geo => {
        :format => format
      }
    }).to_xml

    # Check that the options were parsed correctly
    doc = Nokogiri::XML.parse("<root xmlns:geo='http://www.google.com/geo/schemas/sitemap/1.0'>#{geo_xml_fragment}</root>")
    url = doc.at_xpath("//url")
    url.should_not be_nil
    url.at_xpath("loc").text.should == loc

    geo = url.at_xpath("geo:geo")
    geo.should_not be_nil
    geo.at_xpath("geo:format").text.should == format

    # Google's documentation and published schema don't match some valid elements may
    # not validate.
    xml_fragment_should_validate_against_schema(geo, 'http://www.google.com/geo/schemas/sitemap/1.0', 'sitemap-geo')
  end
end
