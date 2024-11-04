require 'spec_helper'

RSpec.describe SitemapGenerator::Builder::SitemapIndexUrl do
  let(:index) {
    SitemapGenerator::Builder::SitemapIndexFile.new(
      :sitemaps_path => 'sitemaps/',
      :host => 'http://test.com',
      :filename => 'sitemap_index.xml.gz'
    )
  }
  let(:url)  { SitemapGenerator::Builder::SitemapUrl.new(index) }

  it 'should return the correct url' do
    expect(url[:loc]).to eq('http://test.com/sitemaps/sitemap_index.xml.gz')
  end

  it 'should use the host from the index' do
    host = 'http://myexample.com'
    expect(index.location).to receive(:host).and_return(host)
    expect(url[:host]).to eq(host)
  end

  it 'should use the public path for the link' do
    path = '/path'
    expect(index.location).to receive(:path_in_public).and_return(path)
    expect(url[:loc]).to eq('http://test.com/path')
  end
end
