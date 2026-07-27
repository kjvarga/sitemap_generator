# frozen_string_literal: true

require 'spec_helper'
require 'google/cloud/storage'

RSpec.describe SitemapGenerator::GoogleStorageAdapter do
  subject(:adapter) { described_class.new(options) }

  let(:options) { { credentials: 'abc', project_id: 'project_id', bucket: 'bucket' } }

  shared_examples 'writes the raw data to a file and then uploads that file to Google Storage' do |acl|
    it 'writes the raw data to a file and then uploads that file to Google Storage' do
      expect_file_adapter_write(location)
      allow(location).to receive_messages(path_in_public: 'path_in_public', path: 'path')
      expect_google_storage_upload(acl)
      adapter.write(location, 'raw_data')
    end

    def expect_file_adapter_write(location)
      file_adapter = instance_double(SitemapGenerator::FileAdapter)
      allow(SitemapGenerator::FileAdapter).to receive(:new).and_return(file_adapter)
      expect(file_adapter).to receive(:write).with(location, 'raw_data')
    end

    def expect_google_storage_upload(acl)
      storage = instance_double(Google::Cloud::Storage::Project)
      allow(Google::Cloud::Storage).to receive(:new)
        .with(credentials: 'abc', project_id: 'project_id').and_return(storage)
      expect(Google::Cloud::Storage).to receive(:new).with(credentials: 'abc', project_id: 'project_id')
      expect_bucket_create_file(storage, acl)
    end

    def expect_bucket_create_file(storage, acl)
      bucket_resource = instance_double(Google::Cloud::Storage::Bucket)
      allow(storage).to receive(:bucket).with('bucket').and_return(bucket_resource)
      expect(storage).to receive(:bucket).with('bucket')
      expect_bucket_resource_create_file(bucket_resource, acl)
    end

    def expect_bucket_resource_create_file(bucket_resource, acl)
      allow(bucket_resource).to receive(:create_file).with('path', 'path_in_public', acl: acl).and_return(nil)
      expect(bucket_resource).to receive(:create_file).with('path', 'path_in_public', acl: acl)
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
