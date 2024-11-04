require 'spec_helper'

RSpec.describe 'SitemapGenerator::FileAdapter' do
  let(:location) { SitemapGenerator::SitemapLocation.new }
  let(:adapter)  { SitemapGenerator::FileAdapter.new }

  describe 'write' do
    it 'should gzip contents if filename ends in .gz' do
      expect(location).to receive(:filename).and_return('sitemap.xml.gz').twice
      expect(adapter).to receive(:gzip)
      adapter.write(location, 'data')
    end

    it 'should not gzip contents if filename does not end in .gz' do
      expect(location).to receive(:filename).and_return('sitemap.xml').twice
      expect(adapter).to receive(:plain)
      adapter.write(location, 'data')
    end
  end
end
