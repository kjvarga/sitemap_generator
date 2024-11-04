require 'spec_helper'

RSpec.describe 'SitemapGenerator' do
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
      :rating => 0.499999999,
      :price => 123.45,
      :price_currency => 'CAD',
      :price_resolution => 'HD',
      :price_type => 'rent'
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
    Nokogiri::XML.parse("<root xmlns:video='#{SitemapGenerator::SCHEMAS['video']}'>#{xml}</root>")
  end

  # Validate the contents of the video element
  def validate_video_element(video_doc, video_options)
    expect(video_doc.at_xpath('video:thumbnail_loc').text).to eq(video_options[:thumbnail_loc])
    expect(video_doc.at_xpath('video:thumbnail_loc').text).to eq(video_options[:thumbnail_loc])
    expect(video_doc.at_xpath('video:gallery_loc').text).to   eq(video_options[:gallery_loc])
    expect(video_doc.at_xpath('video:gallery_loc').attribute('title').text).to eq(video_options[:gallery_title])
    expect(video_doc.at_xpath('video:title').text).to         eq(video_options[:title])
    expect(video_doc.at_xpath('video:view_count').text).to    eq(video_options[:view_count].to_s)
    expect(video_doc.at_xpath('video:duration').text).to      eq(video_options[:duration].to_s)
    expect(video_doc.at_xpath('video:rating').text).to        eq('%0.1f' % video_options[:rating])
    expect(video_doc.at_xpath('video:content_loc').text).to   eq(video_options[:content_loc])
    expect(video_doc.at_xpath('video:category').text).to      eq(video_options[:category])
    expect(video_doc.xpath('video:tag').collect(&:text)).to   eq(video_options[:tags])
    expect(video_doc.at_xpath('video:expiration_date').text).to  eq(video_options[:expiration_date].iso8601)
    expect(video_doc.at_xpath('video:publication_date').text).to eq(video_options[:publication_date].iso8601)
    expect(video_doc.at_xpath('video:player_loc').text).to    eq(video_options[:player_loc])
    expect(video_doc.at_xpath('video:player_loc').attribute('allow_embed').text).to eq(video_options[:allow_embed] ? 'yes' : 'no')
    expect(video_doc.at_xpath('video:player_loc').attribute('autoplay').text).to    eq(video_options[:autoplay])
    expect(video_doc.at_xpath('video:uploader').text).to      eq(video_options[:uploader])
    expect(video_doc.at_xpath('video:uploader').attribute('info').text).to eq(video_options[:uploader_info])
    expect(video_doc.at_xpath('video:price').text).to eq(video_options[:price].to_s)
    expect(video_doc.at_xpath('video:price').attribute('resolution').text).to eq(video_options[:price_resolution].to_s)
    expect(video_doc.at_xpath('video:price').attribute('type').text).to eq(video_options[:price_type].to_s)
    expect(video_doc.at_xpath('video:price').attribute('currency').text).to eq(video_options[:price_currency].to_s)
    xml_fragment_should_validate_against_schema(video_doc, 'sitemap-video', 'xmlns:video' => SitemapGenerator::SCHEMAS['video'])
  end

  it 'should add a valid video sitemap element' do
    xml = video_xml(video_options)
    doc = video_doc(xml)
    expect(doc.at_xpath('//url/loc').text).to eq(File.join(url_options[:host], url_options[:path]))
    validate_video_element(doc.at_xpath('//url/video:video'), video_options)
  end

  it 'should support multiple video elements' do
    xml = video_xml([video_options, video_options])
    doc = video_doc(xml)
    expect(doc.at_xpath('//url/loc').text).to eq(File.join(url_options[:host], url_options[:path]))
    expect(doc.xpath('//url/video:video').count).to eq(2)
    doc.xpath('//url/video:video').each do |video|
      validate_video_element(video, video_options)
    end
  end

  it 'should default allow_embed to \'yes\'' do
    xml = video_xml(video_options.merge(:allow_embed => nil))
    doc = video_doc(xml)
    expect(doc.at_xpath('//url/video:video/video:player_loc').attribute('allow_embed').text).to eq('yes')
  end

  it 'should not include optional elements if they are not passed' do
    optional = [:player_loc, :content_loc, :category, :tags, :tag, :uploader, :gallery_loc, :family_friendly, :publication_date, :expiration_date, :view_count, :rating, :duration]
    required_options = video_options.delete_if { |k,v| optional.include?(k) }
    xml = video_xml(required_options)
    doc = video_doc(xml)
    optional.each do |element|
      expect(doc.at_xpath("//url/video:video/video:#{element}")).to be_nil
    end
  end

  it 'should not include autoplay param if blank' do
    xml = video_xml(video_options.tap {|v| v.delete(:autoplay) })
    doc = video_doc(xml)
    expect(doc.at_xpath('//url/video:video/video:player_loc').attribute('autoplay')).to be_nil
  end
end
