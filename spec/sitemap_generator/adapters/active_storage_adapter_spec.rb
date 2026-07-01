# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SitemapGenerator::ActiveStorageAdapter' do
  subject(:adapter) { SitemapGenerator::ActiveStorageAdapter.new }

  let!(:active_storage) do
    class_double('ActiveStorage::Blob', destroy_by: true, create_and_upload!: nil)
      .tap { |blob| allow(blob).to receive(:transaction).and_yield }
      .as_stubbed_const
  end

  describe 'write' do
    let(:location) do
      SitemapGenerator::SitemapLocation.new(
        filename: 'custom.xml',
        sitemaps_path: 'some_path'
      )
    end

    it 'creates an ActiveStorage::Blob record' do
      adapter.write(location, 'data')

      expect(active_storage).to have_received(:create_and_upload!)
    end

    it 'gets key and filename from the sitemap_location' do
      adapter.write(location, 'data')

      expect(active_storage).to have_received(:create_and_upload!)
        .with(include(key: 'some_path/custom.xml', filename: 'custom.xml'))
    end

    # Ideally, this would be driven by the location or namer collaborators,
    # but it's all rather murky at the moment. filename extension is what
    # drives compression in FileAdapter, so consistency wins
    context 'with a gzipped file' do
      let(:location) { SitemapGenerator::SitemapLocation.new(filename: 'custom.xml.gz') }

      specify do
        adapter.write(location, 'data')

        expect(active_storage).to have_received(:create_and_upload!)
          .with(include(content_type: 'application/gzip'))
      end
    end

    context 'with a non-gzipped file' do
      let(:location) { SitemapGenerator::SitemapLocation.new(filename: 'custom.xml') }

      specify do
        adapter.write(location, 'data')

        expect(active_storage).to have_received(:create_and_upload!)
          .with(include(content_type: 'application/xml'))
      end
    end

    context 'with a custom prefix for segmenting from other blobs' do
      subject(:adapter) { SitemapGenerator::ActiveStorageAdapter.new(prefix: 'sitemaps') }

      it 'prefixes only the key' do
        adapter.write(location, 'data')

        expect(active_storage).to have_received(:create_and_upload!)
          .with(include(key: 'sitemaps/some_path/custom.xml', filename: 'custom.xml'))
      end
    end
  end
end
