# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::Builder::SitemapIndexUrl do
  let(:index) do
    SitemapGenerator::Builder::SitemapIndexFile.new(
      sitemaps_path: 'sitemaps/',
      host: 'http://test.com',
      filename: 'sitemap_index.xml.gz'
    )
  end
  let(:url) { described_class.new(index) }

  it 'returns the correct url' do
    expect(url[:loc]).to eq('http://test.com/sitemaps/sitemap_index.xml.gz')
  end

  it 'uses the host from the index' do
    host = 'http://myexample.com'
    expect(index.location).to receive(:host).and_return(host)
    expect(url[:host]).to eq(host)
  end

  it 'uses the public path for the link' do
    path = '/path'
    expect(index.location).to receive(:path_in_public).and_return(path)
    expect(url[:loc]).to eq('http://test.com/path')
  end

  describe '#initialize' do
    context 'when given a SitemapIndexFile' do
      let(:frozen_time) { Time.at(1_000_000).utc }

      before do
        allow(SitemapGenerator::Utilities).to receive(:current_time).and_return(frozen_time)
      end

      it 'defaults lastmod to Utilities.current_time' do
        expect(url[:lastmod]).to eq(frozen_time)
      end
    end
  end
end
