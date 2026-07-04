# frozen_string_literal: true

require 'spec_helper'
module ActiveStorage; end unless defined?(ActiveStorage) # rubocop:disable Lint/EmptyModule
require 'sitemap_generator/adapters/active_storage_adapter'

RSpec.describe 'SitemapGenerator::ActiveStorageAdapter' do
  let(:location) do
    SitemapGenerator::SitemapLocation.new(
      namer: SitemapGenerator::SimpleNamer.new(:sitemap, start: 2, zero: 1),
      public_path: 'tmp/',
      sitemaps_path: 'sitemaps/',
      host: 'http://example.com/'
    )
  end
  let(:adapter) { SitemapGenerator::ActiveStorageAdapter.new }
  let(:fake_active_storage_blob) do
    Class.new do
      def self.transaction
        yield
      end

      def self.where(*_args)
        FakeScope.new
      end

      def self.create_and_upload!(**_kwargs)
        'ActiveStorage::Blob'
      end

      class FakeScope
        def destroy_all
          true
        end
      end
    end
  end

  before do
    stub_const('ActiveStorage::Blob', fake_active_storage_blob)
    allow(SitemapGenerator::FileAdapter).to receive_message_chain(:new, :write)
    allow(File).to receive(:open).and_yield(StringIO.new('data'))
  end

  describe 'write' do
    it 'uses location.path_in_public as the blob key' do
      expect(fake_active_storage_blob).to receive(:where).with(key: location.path_in_public).and_call_original
      adapter.write(location, 'data')
    end

    it 'uses location.filename as the blob filename' do
      captured = nil
      allow(fake_active_storage_blob).to receive(:create_and_upload!) { |**kwargs| captured = kwargs; 'blob' }
      adapter.write(location, 'data')
      expect(captured[:filename]).to eq(location.filename.to_s)
    end

    it 'uses location.content_type as the blob content_type' do
      captured = nil
      allow(fake_active_storage_blob).to receive(:create_and_upload!) { |**kwargs| captured = kwargs; 'blob' }
      adapter.write(location, 'data')
      expect(captured[:content_type]).to eq(location.content_type)
    end

    context 'when sitemaps are uncompressed' do
      let(:location) do
        SitemapGenerator::SitemapLocation.new(
          namer: SitemapGenerator::SimpleNamer.new(:sitemap, start: 2, zero: 1),
          public_path: 'tmp/',
          host: 'http://example.com/',
          compress: false
        )
      end

      it 'uses application/xml content_type' do
        captured = nil
        allow(fake_active_storage_blob).to receive(:create_and_upload!) { |**kwargs| captured = kwargs; 'blob' }
        adapter.write(location, 'data')
        expect(captured[:content_type]).to eq('application/xml')
      end
    end
  end
end
