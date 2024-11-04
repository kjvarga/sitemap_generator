require 'spec_helper'

RSpec.describe SitemapGenerator::SimpleNamer do
  it 'should generate file names' do
    namer = SitemapGenerator::SimpleNamer.new(:sitemap)
    expect(namer.to_s).to eq('sitemap.xml.gz')
    expect(namer.next.to_s).to eq('sitemap1.xml.gz')
    expect(namer.next.to_s).to eq('sitemap2.xml.gz')
  end

  it 'should set the file extension' do
    namer = SitemapGenerator::SimpleNamer.new(:sitemap, :extension => '.xyz')
    expect(namer.to_s).to eq('sitemap.xyz')
    expect(namer.next.to_s).to eq('sitemap1.xyz')
    expect(namer.next.to_s).to eq('sitemap2.xyz')
  end

  it 'should set the starting index' do
    namer = SitemapGenerator::SimpleNamer.new(:sitemap, :start => 10)
    expect(namer.to_s).to eq('sitemap.xml.gz')
    expect(namer.next.to_s).to eq('sitemap10.xml.gz')
    expect(namer.next.to_s).to eq('sitemap11.xml.gz')
  end

  it 'should accept a string name' do
    namer = SitemapGenerator::SimpleNamer.new('abc-def')
    expect(namer.to_s).to eq('abc-def.xml.gz')
    expect(namer.next.to_s).to eq('abc-def1.xml.gz')
    expect(namer.next.to_s).to eq('abc-def2.xml.gz')
  end

  it 'should return previous name' do
    namer = SitemapGenerator::SimpleNamer.new(:sitemap)
    expect(namer.to_s).to eq('sitemap.xml.gz')
    expect(namer.next.to_s).to eq('sitemap1.xml.gz')
    expect(namer.previous.to_s).to eq('sitemap.xml.gz')
    expect(namer.next.next.to_s).to eq('sitemap2.xml.gz')
    expect(namer.previous.to_s).to eq('sitemap1.xml.gz')
    expect(namer.next.next.to_s).to eq('sitemap3.xml.gz')
    expect(namer.previous.to_s).to eq('sitemap2.xml.gz')
  end

  it 'should raise if already at the start' do
    namer = SitemapGenerator::SimpleNamer.new(:sitemap)
    expect(namer.to_s).to eq('sitemap.xml.gz')
    # Use a regex because in Ruby 3.1 the error message includes newlines and the first line of backtrace
    expect { namer.previous }.to raise_error(NameError, /Already at the start of the series/)
  end

  it 'should handle names with underscores' do
    namer = SitemapGenerator::SimpleNamer.new('sitemap1_')
    expect(namer.to_s).to eq('sitemap1_.xml.gz')
    expect(namer.next.to_s).to eq('sitemap1_1.xml.gz')
  end

  it 'should reset the namer' do
    namer = SitemapGenerator::SimpleNamer.new(:sitemap)
    expect(namer.to_s).to eq('sitemap.xml.gz')
    expect(namer.next.to_s).to eq('sitemap1.xml.gz')
    namer.reset
    expect(namer.to_s).to eq('sitemap.xml.gz')
    expect(namer.next.to_s).to eq('sitemap1.xml.gz')
  end

  describe 'should handle the zero option' do
    it 'as a string' do
      namer = SitemapGenerator::SimpleNamer.new(:sitemap, :zero => 'string')
      expect(namer.to_s).to eq('sitemapstring.xml.gz')
      expect(namer.next.to_s).to eq('sitemap1.xml.gz')
    end

    it 'as an integer' do
      namer = SitemapGenerator::SimpleNamer.new(:sitemap, :zero => 0)
      expect(namer.to_s).to eq('sitemap0.xml.gz')
      expect(namer.next.to_s).to eq('sitemap1.xml.gz')
    end

    it 'as a string' do
      namer = SitemapGenerator::SimpleNamer.new(:sitemap, :zero => '_index')
      expect(namer.to_s).to eq('sitemap_index.xml.gz')
      expect(namer.next.to_s).to eq('sitemap1.xml.gz')
    end

    it 'as a symbol' do
      namer = SitemapGenerator::SimpleNamer.new(:sitemap, :zero => :index)
      expect(namer.to_s).to eq('sitemapindex.xml.gz')
      expect(namer.next.to_s).to eq('sitemap1.xml.gz')
    end

    it 'with a starting index' do
      namer = SitemapGenerator::SimpleNamer.new(:sitemap, :zero => 'abc', :start => 10)
      expect(namer.to_s).to eq('sitemapabc.xml.gz')
      expect(namer.next.to_s).to eq('sitemap10.xml.gz')
      expect(namer.next.to_s).to eq('sitemap11.xml.gz')
    end
  end
end
