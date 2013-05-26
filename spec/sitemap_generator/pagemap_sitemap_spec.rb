require 'spec_helper'

describe "SitemapGenerator" do

  it "should add the pagemap sitemap element" do
    pagemap_xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('my_page.html', {
      :host => 'http://www.example.com',

      :pagemap => {
        :dataobjects => [
          {
            type: 'document',
            id: 'hibachi',
            attributes: [
              {name: 'name', value: 'Dragon'},
              {name: 'review', value: 3.5},
            ]
          },
          {
            type: 'stats',
            attributes: [
              {name: 'installs', value: 2000},
              {name: 'comments', value: 200},
            ]
          }
        ]
      }
    }).to_xml

    doc = Nokogiri::XML.parse(pagemap_xml_fragment)

    url = doc.at_xpath("//url")
    loc = url.at_xpath("loc")
    loc.text.should == 'http://www.example.com/my_page.html'

    pagemap = doc.at_xpath("//PageMap")

    pagemap.namespace_definitions.first.href.should == 'http://www.google.com/schemas/sitemap-pagemap/1.0'
    pagemap.children.count.should == 2
    pagemap.at_xpath('//DataObject').attributes['type'].value.should == 'document'
    pagemap.at_xpath('//DataObject').attributes['id'].value.should == 'hibachi'
    pagemap.at_xpath('//DataObject').children.count.should == 2
    first_attribute = pagemap.at_xpath('//DataObject').children.first
    second_attribute = pagemap.at_xpath('//DataObject').children.last
    first_attribute.text.should == 'Dragon'
    first_attribute.attributes['name'].value.should == 'name'
    second_attribute.text.should == '3.5'
    second_attribute.attributes['name'].value.should == 'review'

    xml_fragment_should_validate_against_schema(pagemap, 'http://www.google.com/schemas/sitemap-pagemap/1.0', 'sitemap-pagemap')
  end
end
