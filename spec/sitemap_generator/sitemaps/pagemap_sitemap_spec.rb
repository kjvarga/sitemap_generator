# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SitemapGenerator' do
  let(:schema) { SitemapGenerator::SCHEMAS['pagemap'] }

  it 'adds the pagemap sitemap element' do
    expect_valid_pagemap_sitemap_element
  end

  def expect_valid_pagemap_sitemap_element
    doc = pagemap_sitemap_doc
    expect(doc.at_xpath('//url/loc').text).to eq('http://www.example.com/my_page.html')
    expect_valid_pagemap(doc.at_xpath('//pagemap:PageMap', 'pagemap' => schema))
  end

  def expect_valid_pagemap(pagemap)
    expect(pagemap.element_children.count).to eq(2)
    expect_valid_pagemap_dataobject(pagemap.at_xpath('//pagemap:DataObject'))
    expect_xml_fragment_to_validate_against_schema(pagemap, 'sitemap-pagemap', 'xmlns:pagemap' => schema)
  end

  # Nokogiri is a fickle beast.  We have to add the namespace and define
  # the prefix in order for XPath queries to work.  And then we have to
  # reingest because otherwise Nokogiri doesn't use it.
  def pagemap_sitemap_doc
    pagemap_xml_fragment = SitemapGenerator::Builder::SitemapUrl.new(
      'my_page.html', host: 'http://www.example.com', pagemap: pagemap_options
    ).to_xml
    doc = Nokogiri::XML.parse(pagemap_xml_fragment)
    doc.root.add_namespace_definition('pagemap', schema)
    Nokogiri::XML.parse(doc.to_xml)
  end

  def pagemap_options
    { dataobjects: [document_dataobject, stats_dataobject] }
  end

  def document_dataobject
    {
      type: 'document',
      id: 'hibachi',
      attributes: [
        { name: 'name', value: 'Dragon' },
        { name: 'review', value: 3.5 }
      ]
    }
  end

  def stats_dataobject
    {
      type: 'stats',
      attributes: [
        { name: 'installs', value: 2000 },
        { name: 'comments', value: 200 }
      ]
    }
  end

  def expect_valid_pagemap_dataobject(dataobject)
    expect(dataobject.attributes['type'].value).to eq('document')
    expect(dataobject.attributes['id'].value).to eq('hibachi')
    expect_valid_pagemap_dataobject_attributes(dataobject)
  end

  def expect_valid_pagemap_dataobject_attributes(dataobject)
    expect(dataobject.element_children.count).to eq(2)
    expect_valid_pagemap_attributes(dataobject.element_children.first, dataobject.element_children.last)
  end

  def expect_valid_pagemap_attributes(first_attribute, second_attribute)
    expect(first_attribute.text).to eq('Dragon')
    expect(first_attribute.attributes['name'].value).to eq('name')
    expect_valid_pagemap_second_attribute(second_attribute)
  end

  def expect_valid_pagemap_second_attribute(second_attribute)
    expect(second_attribute.text).to eq('3.5')
    expect(second_attribute.attributes['name'].value).to eq('review')
  end
end
