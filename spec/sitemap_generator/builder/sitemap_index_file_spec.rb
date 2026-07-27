# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SitemapGenerator::Builder::SitemapIndexFile' do
  let(:location) do
    SitemapGenerator::SitemapLocation.new(filename: 'sitemap.xml.gz', public_path: '/public/',
                                          host: 'http://example.com/')
  end
  let(:index) { SitemapGenerator::Builder::SitemapIndexFile.new(location) }

  before do
    index.location[:sitemaps_path] = 'test/'
  end

  it 'returns the URL' do
    expect(index.location.url).to eq('http://example.com/test/sitemap.xml.gz')
  end

  it 'returns the path' do
    expect(index.location.path).to eq('/public/test/sitemap.xml.gz')
  end

  it 'is empty' do
    expect(index).to have_attributes(empty?: true, link_count: 0)
  end

  it 'does not have a last modification data' do
    expect(index.lastmod).to be_nil
  end

  it 'is not finalized' do
    expect(index.finalized?).to be(false)
  end

  it 'filename should be set' do
    expect(index.location.filename).to eq('sitemap.xml.gz')
  end

  it 'has a default namer' do
    index = SitemapGenerator::Builder::SitemapIndexFile.new
    expect(index.location.filename).to eq('sitemap.xml.gz')
  end

  describe 'link_count' do
    it 'returns the link count' do
      index.instance_variable_set(:@link_count, 10)
      expect(index.link_count).to eq(10)
    end
  end

  describe 'create_index?' do
    it 'returns false' do
      index.location[:create_index] = false
      before_link_count = index.create_index?
      index.instance_variable_set(:@link_count, 10)
      expect([before_link_count, index.create_index?]).to all(be(false))
    end

    it 'returns true' do
      index.location[:create_index] = true
      before_link_count = index.create_index?
      index.instance_variable_set(:@link_count, 1)
      expect([before_link_count, index.create_index?]).to all(be(true))
    end

    it 'when :auto, should be true if more than one link' do
      index.instance_variable_set(:@link_count, 1)
      index.location[:create_index] = :auto
      one_link = index.create_index?
      index.instance_variable_set(:@link_count, 2)
      expect([one_link, index.create_index?]).to eq([false, true])
    end
  end

  describe 'add' do
    it 'uses the host provided' do
      expect_sitemap_index_url_new('/one', 'http://newhost.com/', 'http://newhost.com')
      index.add '/one', host: 'http://newhost.com'
    end

    it 'uses the host from the location' do
      expect_sitemap_index_url_new('/one', 'http://example.com/', 'http://example.com/')
      index.add '/one'
    end

    def expect_sitemap_index_url_new(path, build_host, expected_host)
      url = SitemapGenerator::Builder::SitemapIndexUrl.new(path, host: build_host)
      allow(SitemapGenerator::Builder::SitemapIndexUrl).to receive(:new)
        .with(path, { host: expected_host }).and_return(url)
      expect(SitemapGenerator::Builder::SitemapIndexUrl).to receive(:new)
        .with(path, { host: expected_host })
    end

    describe 'when adding manually' do
      it 'reserves a name' do
        expect(index).to receive(:reserve_name)
        index.add '/link'
      end

      it 'creates index' do
        before_add = index.create_index?
        index.add '/one'
        expect([before_add, index.create_index?]).to eq([false, true])
      end
    end
  end

  describe 'index_url' do
    it 'when not creating an index, should be the first sitemap url' do
      index.instance_variable_set(:@create_index, false)
      index.instance_variable_set(:@first_sitemap_url, 'http://test.com/index.xml')
      expect(index).to have_attributes(create_index?: false, index_url: 'http://test.com/index.xml')
    end

    it 'if there\'s no first sitemap url, should default to the index location url' do
      index.instance_variable_set(:@create_index, false)
      index.instance_variable_set(:@first_sitemap_url, nil)
      expect(index).to have_attributes(create_index?: false, index_url: index.location.url)
    end

    it 'when creating an index, should be the index location url' do
      index.instance_variable_set(:@create_index, true)
      expect(index.index_url).to eq(index.location.url)
    end
  end
end
