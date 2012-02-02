require 'spec_helper'

describe 'SitemapGenerator::SitemapNamer' do

  it "should generate file names" do
    namer = SitemapGenerator::SitemapNamer.new(:sitemap)
    namer.to_s.should == "sitemap1.xml.gz"
    namer.next.to_s.should == "sitemap2.xml.gz"
    namer.next.to_s.should == "sitemap3.xml.gz"
  end

  it "should set the file extension" do
    namer = SitemapGenerator::SitemapNamer.new(:sitemap, :extension => '.xyz')
    namer.to_s.should == "sitemap1.xyz"
    namer.next.to_s.should == "sitemap2.xyz"
    namer.next.to_s.should == "sitemap3.xyz"
  end

  it "should set the starting index" do
    namer = SitemapGenerator::SitemapNamer.new(:sitemap, :start => 10)
    namer.to_s.should == "sitemap10.xml.gz"
    namer.next.to_s.should == "sitemap11.xml.gz"
    namer.next.to_s.should == "sitemap12.xml.gz"
  end

  it "should accept a string name" do
    namer = SitemapGenerator::SitemapNamer.new('abc-def')
    namer.to_s.should == "abc-def1.xml.gz"
    namer.next.to_s.should == "abc-def2.xml.gz"
    namer.next.to_s.should == "abc-def3.xml.gz"
  end

  it "should return previous name" do
    namer = SitemapGenerator::SitemapNamer.new(:sitemap)
    namer.to_s.should == "sitemap1.xml.gz"
    namer.next.to_s.should == "sitemap2.xml.gz"
    namer.previous.to_s.should == "sitemap1.xml.gz"
    namer.next.to_s.should == "sitemap2.xml.gz"
  end

  it "should raise if already at the start" do
    namer = SitemapGenerator::SitemapNamer.new(:sitemap)
    namer.to_s.should == "sitemap1.xml.gz"
    lambda { namer.previous }.should raise_error
  end

  it "should handle names with underscores" do
    namer = SitemapGenerator::SitemapNamer.new("sitemap1_")
    namer.to_s.should == "sitemap1_1.xml.gz"
  end

  it "should provide access to start value" do
    namer = SitemapGenerator::SitemapNamer.new(:sitemap, :start => 10)
    namer.start.should eql 10
  end

  it "should provide access to base name" do
    namer = SitemapGenerator::SitemapNamer.new('some-name')
    namer.base.should eql 'some-name'
  end
end

describe SitemapGenerator::SitemapIndexNamer do
  it "should always return the same name" do
    default = "sitemap_index.xml.gz"
    namer = SitemapGenerator::SitemapIndexNamer.new(:sitemap_index)
    namer.to_s.should == default
    namer.next.to_s.should == default
    namer.previous.to_s.should == default
  end
end
