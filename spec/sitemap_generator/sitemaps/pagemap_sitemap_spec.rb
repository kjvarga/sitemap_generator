require 'spec_helper'

RSpec.describe 'SitemapGenerator' do
  let(:schema) { SitemapGenerator::SCHEMAS['pagemap'] }

  it 'should add the pagemap sitemap element' do
    pagemap_xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('my_page.html', {
      :host => 'http://www.example.com',

      :pagemap => {
        :dataobjects => [
          {
            :type => 'document',
            :id => 'hibachi',
            :attributes => [
              {:name => 'name', :value => 'Dragon'},
              {:name => 'review', :value => 3.5},
            ]
          },
          {
            :type => 'stats',
            :attributes => [
              {:name => 'installs', :value => 2000},
              {:name => 'comments', :value => 200},
            ]
          }
        ]
      }
    }).to_xml

    # Nokogiri is a fickle beast.  We have to add the namespace and define
    # the prefix in order for XPath queries to work.  And then we have to
    # reingest because otherwise Nokogiri doesn't use it.
    doc = Nokogiri::XML.parse(pagemap_xml_fragment)
    doc.root.add_namespace_definition('pagemap', schema)
    doc = Nokogiri::XML.parse(doc.to_xml)

    url = doc.at_xpath('//url')
    loc = url.at_xpath('loc')
    expect(loc.text).to eq('http://www.example.com/my_page.html')

    pagemap =  doc.at_xpath('//pagemap:PageMap', 'pagemap' => schema)
    expect(pagemap.element_children.count).to eq(2)
    dataobject = pagemap.at_xpath('//pagemap:DataObject')
    expect(dataobject.attributes['type'].value).to eq('document')
    expect(dataobject.attributes['id'].value).to eq('hibachi')
    expect(dataobject.element_children.count).to eq(2)
    first_attribute = dataobject.element_children.first
    second_attribute = dataobject.element_children.last
    expect(first_attribute.text).to eq('Dragon')
    expect(first_attribute.attributes['name'].value).to eq('name')
    expect(second_attribute.text).to eq('3.5')
    expect(second_attribute.attributes['name'].value).to eq('review')

    xml_fragment_should_validate_against_schema(pagemap, 'sitemap-pagemap', 'xmlns:pagemap' => schema)
  end
end
