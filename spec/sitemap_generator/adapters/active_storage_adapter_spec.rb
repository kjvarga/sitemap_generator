require 'spec_helper'
require 'sitemap_generator/adapters/active_storage_adapter'

RSpec.describe 'SitemapGenerator::ActiveStorageAdapter' do
  let(:location) { SitemapGenerator::SitemapLocation.new }
  let(:adapter)  { SitemapGenerator::ActiveStorageAdapter.new }
  let(:fake_active_storage_blob) {
    Class.new do
      def self.transaction
        yield
      end

      def self.where(*args)
        FakeScope.new
      end

      def self.create_and_upload!(**kwargs)
        'ActiveStorage::Blob'
      end

      class FakeScope
        def destroy_all
          true
        end
      end
    end
  }

  before do
    stub_const('ActiveStorage::Blob', fake_active_storage_blob)
  end

  describe 'write' do
    it 'should create an ActiveStorage::Blob record' do
      expect(location).to receive(:filename).and_return('sitemap.xml.gz').at_least(2).times
      expect(adapter.write(location, 'data')).to eq 'ActiveStorage::Blob'
    end
  end
end
