require 'spec_helper'

describe 'SitemapGenerator::Builder::SitemapFile' do
  before :each do
    FileUtils.rm_rf("tmp/test/")
    @loc = SitemapGenerator::SitemapLocation.new(:namer => SitemapGenerator::SitemapNamer.new(:sitemap), :public_path => 'tmp/', :sitemaps_path => 'test/', :host => 'http://example.com/')
    @s = SitemapGenerator::Builder::SitemapFile.new(@loc)
  end

  it "should have a default namer" do
    @s = SitemapGenerator::Builder::SitemapFile.new
    @s.location.filename.should == 'sitemap1.xml.gz'
  end

  it "should return the name of the sitemap file" do
    @s.location.filename.should == 'sitemap1.xml.gz'
  end

  it "should return the URL" do
    @s.location.url.should == 'http://example.com/test/sitemap1.xml.gz'
  end

  it "should return the path" do
    @s.location.path.should == File.expand_path('tmp/test/sitemap1.xml.gz')
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

  it "should increment the namer after finalizing" do
    @s.finalize!
    @s.location.filename.should_not == @s.location.namer.to_s
  end

  it "should raise if no default host is set" do
    lambda { SitemapGenerator::Builder::SitemapFile.new.location.url }.should raise_error(SitemapGenerator::SitemapError)
  end

  describe "new" do
    before :each do
      @orig_s = @s
      @s = @s.new
    end

    it "should inherit the same options" do
      # The name is the same because the original sitemap was not finalized
      @s.location.url.should == 'http://example.com/test/sitemap1.xml.gz'
      @s.location.path.should == File.expand_path('tmp/test/sitemap1.xml.gz')
    end

    it "should not share the same location instance" do
      @s.location.should_not be(@orig_s.location)
    end

    it "should inherit the same namer instance" do
      @s.location.namer.should == @orig_s.location.namer
    end
  end
end
