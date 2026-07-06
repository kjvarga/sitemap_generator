require 'spec_helper'

RSpec.describe 'SitemapGenerator::Builder::SitemapFile' do
  let(:location) { SitemapGenerator::SitemapLocation.new(:namer => SitemapGenerator::SimpleNamer.new(:sitemap, :start => 2, :zero => 1), :public_path => 'tmp/', :sitemaps_path => 'test/', :host => 'http://example.com/') }
  let(:sitemap)  { SitemapGenerator::Builder::SitemapFile.new(location) }

  it 'should have a default namer' do
    sitemap = SitemapGenerator::Builder::SitemapFile.new
    expect(sitemap.location.filename).to eq('sitemap1.xml.gz')
  end

  it 'should return the name of the sitemap file' do
    expect(sitemap.location.filename).to eq('sitemap1.xml.gz')
  end

  it 'should return the URL' do
    expect(sitemap.location.url).to eq('http://example.com/test/sitemap1.xml.gz')
  end

  it 'should return the path' do
    expect(sitemap.location.path).to eq(File.expand_path('tmp/test/sitemap1.xml.gz'))
  end

  it 'should be empty' do
    expect(sitemap.empty?).to be(true)
    expect(sitemap.link_count).to eq(0)
  end

  it 'should not be finalized' do
    expect(sitemap.finalized?).to be(false)
  end

  it 'should raise if no default host is set' do
    expect { SitemapGenerator::Builder::SitemapFile.new.location.url }.to raise_error(SitemapGenerator::SitemapError)
  end

  describe 'lastmod' do
    it 'returns nil before the file has been written' do
      sitemap.location.reserve_name
      expect(sitemap.lastmod).to be_nil
    end

    it 'returns nil when the location has not reserved a name' do
      expect(sitemap.lastmod).to be_nil
    end

    context 'when the file has been written' do
      let(:frozen_time) { Time.at(1_000_000).utc }

      before do
        allow(SitemapGenerator::Utilities).to receive(:current_time).and_return(frozen_time)
        allow(sitemap.location).to receive(:write)
        allow(FileUtils).to receive(:mkdir_p)
      end

      it 'calls Utilities.current_time during write and uses the result as lastmod' do
        expect(SitemapGenerator::Utilities).to receive(:current_time).and_return(frozen_time)
        sitemap.write
        expect(sitemap.lastmod).to eq(frozen_time)
      end
    end
  end

  describe 'new' do
    let(:original_sitemap) { sitemap }
    let(:new_sitemap)      { sitemap.new }

    before do
      original_sitemap
      new_sitemap
    end

    it 'should inherit the same options' do
      # The name is the same because the original sitemap was not finalized
      expect(new_sitemap.location.url).to eq('http://example.com/test/sitemap1.xml.gz')
      expect(new_sitemap.location.path).to eq(File.expand_path('tmp/test/sitemap1.xml.gz'))
    end

    it 'should not share the same location instance' do
      expect(new_sitemap.location).not_to be(original_sitemap.location)
    end

    it 'should inherit the same namer instance' do
      expect(new_sitemap.location.namer).to eq(original_sitemap.location.namer)
    end
  end

  describe 'reserve_name' do
    it 'should reserve the name from the location' do
      expect(sitemap.reserved_name?).to be(false)
      expect(sitemap.location).to receive(:reserve_name).and_return('name')
      sitemap.reserve_name
      expect(sitemap.reserved_name?).to be(true)
      expect(sitemap.instance_variable_get(:@reserved_name)).to eq('name')
    end

    it 'should be safe to call multiple times' do
      expect(sitemap.location).to receive(:reserve_name).and_return('name').once
      sitemap.reserve_name
      sitemap.reserve_name
    end
  end

  describe 'add' do
    it 'should use the host provided' do
      url = SitemapGenerator::Builder::SitemapUrl.new('/one', :host => 'http://newhost.com/')
      expect(SitemapGenerator::Builder::SitemapUrl).to receive(:new).with('/one', { :host => 'http://newhost.com' }).and_return(url)
      sitemap.add '/one', :host => 'http://newhost.com'
    end

    it 'should use the host from the location' do
      url = SitemapGenerator::Builder::SitemapUrl.new('/one', :host => 'http://example.com/')
      expect(SitemapGenerator::Builder::SitemapUrl).to receive(:new).with('/one', { :host => 'http://example.com/' }).and_return(url)
      sitemap.add '/one'
    end
  end

  describe 'file_can_fit?' do
    let(:link_count) { 10 }

    before do
      expect(sitemap).to receive(:max_sitemap_links).and_return(max_sitemap_links)
      sitemap.instance_variable_set(:@link_count, link_count)
    end

    context 'when link count is less than max' do
      let(:max_sitemap_links) { link_count + 1 }

      it 'returns true' do
        expect(sitemap.file_can_fit?(1)).to be(true)
      end
    end

    context 'when link count is at max' do
      let(:max_sitemap_links) { link_count }

      it 'returns true' do
        expect(sitemap.file_can_fit?(1)).to be(false)
      end
    end
  end

  describe 'max_sitemap_links' do
    context 'when not present in the location' do
      it 'returns SitemapGenerator::MAX_SITEMAP_LINKS' do
        expect(sitemap.max_sitemap_links).to eq(SitemapGenerator::MAX_SITEMAP_LINKS)
      end
    end

    context 'when present in the location' do
      before do
        expect(sitemap.location).to receive(:[]).with(:max_sitemap_links).and_return(10)
      end

      it 'returns the value from the location' do
        expect(sitemap.max_sitemap_links).to eq(10)
      end
    end
  end
end
