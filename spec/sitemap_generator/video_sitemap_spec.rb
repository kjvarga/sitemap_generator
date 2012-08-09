require 'spec_helper'

describe "SitemapGenerator" do
  let(:url_options) do
    {
      :host => 'http://example.com',
      :path => 'cool_video.html'
    }
  end

  let(:video_options) do
    {
      :thumbnail_loc => 'http://example.com/video1_thumbnail.png',
      :title => 'Cool Video',
      :content_loc => 'http://example.com/cool_video.mpg',
      :player_loc => 'http://example.com/cool_video_player.swf',
      :gallery_loc => 'http://example.com/cool_video_gallery',
      :gallery_title => 'Gallery Title',
      :allow_embed => true,
      :autoplay => 'id=123',
      :description => 'An new perspective in cool video technology',
      :tags => %w(tag1 tag2 tag3),
      :category => 'cat1',
      :uploader => 'sokrates',
      :uploader_info => 'http://sokrates.example.com',
      :expiration_date => Time.at(0),
      :publication_date => Time.at(0),
      :family_friendly => true,
      :view_count => 123,
      :duration => 456,
      :rating => 0.499999999
    }
  end

  # Return XML for the <URL> element.
  def video_xml(video_options)
    SitemapGenerator::Builder::SitemapUrl.new(url_options[:path], {
      :host => url_options[:host],
      :video => video_options
    }).to_xml
  end

  # Return a Nokogiri document from the XML.  The root of the document is the <URL> element.
  def video_doc(xml)
    Nokogiri::XML.parse("<root xmlns:video='http://www.google.com/schemas/sitemap-video/1.1'>#{xml}</root>")
  end

  # Validate the contents of the video element
  def validate_video_element(video_doc, video_options)
    video_doc.at_xpath('video:thumbnail_loc').text.should == video_options[:thumbnail_loc]
    video_doc.at_xpath("video:thumbnail_loc").text.should == video_options[:thumbnail_loc]
    video_doc.at_xpath("video:gallery_loc").text.should   == video_options[:gallery_loc]
    video_doc.at_xpath("video:gallery_loc").attribute('title').text.should == video_options[:gallery_title]
    video_doc.at_xpath("video:title").text.should         == video_options[:title]
    video_doc.at_xpath("video:view_count").text.should    == video_options[:view_count].to_s
    video_doc.at_xpath("video:duration").text.should      == video_options[:duration].to_s
    video_doc.at_xpath("video:rating").text.should        == ('%0.1f' % video_options[:rating])
    video_doc.at_xpath("video:content_loc").text.should   == video_options[:content_loc]
    video_doc.at_xpath("video:category").text.should      == video_options[:category]
    video_doc.xpath("video:tag").collect(&:text).should   == video_options[:tags]
    video_doc.at_xpath("video:expiration_date").text.should  == video_options[:expiration_date].iso8601
    video_doc.at_xpath("video:publication_date").text.should == video_options[:publication_date].iso8601
    video_doc.at_xpath("video:player_loc").text.should    == video_options[:player_loc]
    video_doc.at_xpath("video:player_loc").attribute('allow_embed').text.should == (video_options[:allow_embed] ? 'yes' : 'no')
    video_doc.at_xpath("video:player_loc").attribute('autoplay').text.should    == video_options[:autoplay]
    video_doc.at_xpath("video:uploader").text.should      == video_options[:uploader]
    video_doc.at_xpath("video:uploader").attribute("info").text.should == video_options[:uploader_info]
    xml_fragment_should_validate_against_schema(video_doc, 'http://www.google.com/schemas/sitemap-video/1.1', 'sitemap-video')
  end

  it "should add a valid video sitemap element" do
    xml = video_xml(video_options)
    doc = video_doc(xml)
    doc.at_xpath("//url/loc").text.should == File.join(url_options[:host], url_options[:path])
    validate_video_element(doc.at_xpath('//url/video:video'), video_options)
  end

  it "should support multiple video elements" do
    xml = video_xml([video_options, video_options])
    doc = video_doc(xml)
    doc.at_xpath("//url/loc").text.should == File.join(url_options[:host], url_options[:path])
    doc.xpath('//url/video:video').count.should == 2
    doc.xpath('//url/video:video').each do |video|
      validate_video_element(video, video_options)
    end
  end

  it "should default allow_embed to 'yes'" do
    xml = video_xml(video_options.merge(:allow_embed => nil))
    doc = video_doc(xml)
    doc.at_xpath("//url/video:video/video:player_loc").attribute('allow_embed').text.should == 'yes'
  end

  it "should not include optional elements if they are not passed" do
    optional = [:player_loc, :content_loc, :category, :tags, :tag, :uploader, :gallery_loc, :family_friendly, :publication_date, :expiration_date, :view_count, :rating, :duration]
    required_options = video_options.delete_if { |k,v| optional.include?(k) }
    xml = video_xml(required_options)
    doc = video_doc(xml)
    optional.each do |element|
      doc.at_xpath("//url/video:video/video:#{element}").should be_nil
    end
  end

  it "should not include autoplay param if blank" do
    xml = video_xml(video_options.tap {|v| v.delete(:autoplay) })
    doc = video_doc(xml)
    doc.at_xpath("//url/video:video/video:player_loc").attribute('autoplay').should be_nil
  end

end
