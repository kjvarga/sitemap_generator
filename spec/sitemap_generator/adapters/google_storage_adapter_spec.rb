# encoding: UTF-8
require 'spec_helper'
require 'google/cloud/storage'

RSpec.describe SitemapGenerator::GoogleStorageAdapter do
  subject(:adapter) { described_class.new(options) }

  let(:options) { { credentials: 'abc', project_id: 'project_id', bucket: 'bucket' } }

  shared_examples 'writes the raw data to a file and then uploads that file to Google Storage' do |acl|
    it 'writes the raw data to a file and then uploads that file to Google Storage' do
      bucket = double(:bucket)
      storage = double(:storage)
      bucket_resource = double(:bucket_resource)
      expect(Google::Cloud::Storage).to receive(:new).with(credentials: 'abc', project_id: 'project_id').and_return(storage)
      expect(storage).to receive(:bucket).with('bucket').and_return(bucket_resource)
      expect(location).to receive(:path_in_public).and_return('path_in_public')
      expect(location).to receive(:path).and_return('path')
      expect(bucket_resource).to receive(:create_file).with('path', 'path_in_public', acl: acl).and_return(nil)
      expect_any_instance_of(SitemapGenerator::FileAdapter).to receive(:write).with(location, 'raw_data')
      adapter.write(location, 'raw_data')
    end
  end

  context 'when Google::Cloud::Storage is not defined' do
    it 'raises a LoadError' do
      hide_const('Google::Cloud::Storage')
      expect do
        load File.expand_path('./lib/sitemap_generator/adapters/google_storage_adapter.rb')
      end.to raise_error(LoadError, /Error: `Google::Cloud::Storage` is not defined./)
    end
  end

  describe 'write' do
    let(:location) { SitemapGenerator::SitemapLocation.new }

    it_behaves_like 'writes the raw data to a file and then uploads that file to Google Storage', 'public'

    context 'when the acl option is set' do
      let(:options) do
        { credentials: 'abc', project_id: 'project_id', bucket: 'bucket', acl: 'private' }
      end

      it_behaves_like 'writes the raw data to a file and then uploads that file to Google Storage', 'private'
    end
  end

  describe '.new' do
    it "doesn't modify the original options" do
      adapter
      expect(options.size).to be(3)
    end
  end
end
