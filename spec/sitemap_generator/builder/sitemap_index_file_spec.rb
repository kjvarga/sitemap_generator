require 'spec_helper'

describe 'SitemapGenerator::Builder::SitemapIndexFile' do
  before :each do
    FileUtils.rm_rf("/public/test/")
    @loc = SitemapGenerator::SitemapLocation.new(:filename => 'sitemap_index.xml.gz', :public_path => '/public/', :sitemaps_path => 'test/', :host => 'http://example.com/')
    @s = SitemapGenerator::Builder::SitemapIndexFile.new(@loc)
  end

  it "should return the URL" do
    @s.location.url.should == 'http://example.com/test/sitemap_index.xml.gz'
  end

  it "should return the path" do
    @s.location.path.should == '/public/test/sitemap_index.xml.gz'
  end

  it "should be empty" do
    @s.empty?.should be_true
    @s.link_count.should == 0
  end

  it "should not have a last modification data" do
    @s.lastmod.should be_nil
  end

  it "should not be finalized" do
    @s.finalized?.should be_false
  end

  it "filename should default to sitemap_index" do
    @s.location.filename.should == 'sitemap_index.xml.gz'
  end

  it "should have a default namer" do
    @s = SitemapGenerator::Builder::SitemapIndexFile.new
    @s.location.filename.should == 'sitemap_index.xml.gz'
  end

  describe "add" do
    before :each do
      @file = SitemapGenerator::Builder::SitemapFile.new(@loc)
    end

    it "should have lastmod value" do
      @s.add @file
      @file.lastmod.should_not be_nil
    end
  end
end
