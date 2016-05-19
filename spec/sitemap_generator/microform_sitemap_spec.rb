require 'spec_helper'

describe "SitemapGenerator" do

  it "should add the microform sitemap element" do

    microform_xml_fragment = SitemapGenerator::Builder::SitemapUrl.new('my_element.html',
       :host => 'http://www.example.com',
       :microform =>
           {
               :title => "Example",
               :href => "http://www.example.com/my_elemenent_microform.html",
               :type => "text/html; ext=microforms.org; vocab=schema.org"
           }
    ).to_xml

    doc = Nokogiri::XML.parse("<root>#{microform_xml_fragment}</root>")

    url = doc.at_xpath("//url")
    loc = url.at_xpath("loc")
    loc.text.should == 'http://www.example.com/my_element.html'

    xhtml_must_be_present = false
    url.xpath("./*").each do |elm|
      if elm.name == "xhtml:link"
        xhtml_must_be_present = true
        elm.attribute('rel').text.should == "alternate"
        elm.attribute('title').text.should == "Example"
        elm.attribute('href').text.should == "http://www.example.com/my_elemenent_microform.html"
        elm.attribute('type').text.should == "text/html; ext=microforms.org; vocab=schema.org"
      end
    end

    xhtml_must_be_present.should be_true
  end
end
