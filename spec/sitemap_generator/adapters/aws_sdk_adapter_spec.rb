# frozen_string_literal: true

require 'spec_helper'
require 'aws-sdk-core'
require 'aws-sdk-s3'

RSpec.describe SitemapGenerator::AwsSdkAdapter do
  subject(:adapter) { described_class.new('bucket', **options) }

  let(:location) { SitemapGenerator::SitemapLocation.new(compress: compress) }
  let(:options) { {} }
  let(:compress) { nil }

  shared_examples 'writes and uploads the file to S3' do |acl, cache_control, content_type, path = 'path'|
    before do
      allow(location).to receive(:path).and_return(path)
    end

    if defined?(Aws::S3::TransferManager)
      it 'writes the raw data to a file and uploads using TransferManager' do
        expect_file_adapter_write(location)
        allow(location).to receive(:path_in_public).and_return('path_in_public')
        expect_transfer_manager_upload(path, acl, cache_control, content_type)
        adapter.write(location, 'raw_data')
      end
    else
      it 'writes the raw data to a file and uploads using S3 Resource' do
        expect_file_adapter_write(location)
        allow(location).to receive(:path_in_public).and_return('path_in_public')
        expect_s3_resource_upload(path, acl, cache_control, content_type)
        adapter.write(location, 'raw_data')
      end
    end

    def expect_file_adapter_write(location)
      file_adapter = instance_double(SitemapGenerator::FileAdapter)
      allow(SitemapGenerator::FileAdapter).to receive(:new).and_return(file_adapter)
      expect(file_adapter).to receive(:write).with(location, 'raw_data')
    end

    def expect_transfer_manager_upload(path, acl, cache_control, content_type)
      s3_client = instance_double(Aws::S3::Client)
      transfer_manager = instance_double(Aws::S3::TransferManager)
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(Aws::S3::TransferManager).to receive(:new).with(client: s3_client).and_return(transfer_manager)
      expect(Aws::S3::TransferManager).to receive(:new).with(client: s3_client)
      expect_transfer_manager_upload_file(transfer_manager, path, acl, cache_control, content_type)
    end

    def expect_transfer_manager_upload_file(transfer_manager, path, acl, cache_control, content_type)
      upload_args = hash_including(bucket: 'bucket', key: 'path_in_public', acl: acl,
                                   cache_control: cache_control, content_type: content_type)
      allow(transfer_manager).to receive(:upload_file).with(path, upload_args).and_return(nil)
      expect(transfer_manager).to receive(:upload_file).with(path, upload_args)
    end

    def expect_s3_resource_upload(path, acl, cache_control, content_type)
      s3_resource = instance_double(Aws::S3::Resource)
      s3_bucket = instance_double(Aws::S3::Bucket)
      allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
      allow(s3_resource).to receive(:bucket).with('bucket').and_return(s3_bucket)
      expect(s3_resource).to receive(:bucket).with('bucket')
      expect_s3_bucket_object_upload(s3_bucket, path, acl, cache_control, content_type)
    end

    def expect_s3_bucket_object_upload(s3_bucket, path, acl, cache_control, content_type)
      s3_object = instance_double(Aws::S3::Object)
      allow(s3_bucket).to receive(:object).with('path_in_public').and_return(s3_object)
      expect(s3_bucket).to receive(:object).with('path_in_public')
      expect_s3_object_upload_file(s3_object, path, acl, cache_control, content_type)
    end

    def expect_s3_object_upload_file(s3_object, path, acl, cache_control, content_type)
      upload_args = hash_including(acl: acl, cache_control: cache_control, content_type: content_type)
      allow(s3_object).to receive(:upload_file).with(path, upload_args).and_return(nil)
      expect(s3_object).to receive(:upload_file).with(path, upload_args)
    end
  end

  shared_examples 'deprecated option' do |deprecated_key, new_key|
    context 'when the deprecated option is set to a value' do
      let(:options) do
        { deprecated_key => 'value' }
      end

      it 'sets the option' do
        expect(adapter_options[new_key]).to eq('value')
      end

      context 'when the new option key is also set to a value' do
        let(:options) do
          { deprecated_key => 'value', new_key => 'new_endpoint' }
        end

        it 'does not override it' do
          expect(adapter_options[new_key]).to eq('new_endpoint')
        end
      end

      context 'when the new option key is explicitly nil' do
        let(:options) do
          { deprecated_key => 'value', new_key => nil }
        end

        it 'overrides it' do
          expect(adapter_options[new_key]).to eq('value')
        end
      end
    end

    context 'when the deprecated option is nil' do
      let(:options) do
        { deprecated_key => nil }
      end

      it 'does not set the option' do
        expect(adapter_options).not_to have_key(new_key)
      end
    end
  end

  context 'when Aws::S3::Resource is not defined' do
    it 'raises a LoadError' do
      hide_const('Aws::S3::Resource')
      expect do
        load File.expand_path('./lib/sitemap_generator/adapters/aws_sdk_adapter.rb')
      end.to raise_error(LoadError, %r{Error: `Aws::S3::Resource` and/or `Aws::Credentials` are not defined})
    end
  end

  context 'when Aws::Credentials is not defined' do
    it 'raises a LoadError' do
      hide_const('Aws::Credentials')
      expect do
        load File.expand_path('./lib/sitemap_generator/adapters/aws_sdk_adapter.rb')
      end.to raise_error(LoadError, %r{Error: `Aws::S3::Resource` and/or `Aws::Credentials` are not defined})
    end
  end

  describe '#write' do
    context 'with no compress option' do
      it_behaves_like 'writes and uploads the file to S3', 'public-read',
                      'private, max-age=0, no-cache', 'application/x-gzip', 'sitemap.xml.gz'
    end

    context 'with compress true' do
      let(:compress) { true }

      it_behaves_like 'writes and uploads the file to S3', 'public-read',
                      'private, max-age=0, no-cache', 'application/x-gzip', 'sitemap.xml.gz'
    end

    context 'when compress is :all_but_first and path does not end in .gz' do
      let(:compress) { :all_but_first }

      it_behaves_like 'writes and uploads the file to S3', 'public-read',
                      'private, max-age=0, no-cache', 'application/xml', 'sitemap.xml'
    end

    context 'with acl and cache control configured' do
      let(:options) do
        { acl: 'private', cache_control: 'public, max-age=3600' }
      end

      it_behaves_like 'writes and uploads the file to S3', 'private',
                      'public, max-age=3600', 'application/x-gzip', 'sitemap.xml.gz'
    end
  end

  describe '#initialize' do
    subject(:adapter_options) { adapter.instance_variable_get(:@options) }

    it_behaves_like 'deprecated option', :aws_endpoint, :endpoint
    it_behaves_like 'deprecated option', :aws_access_key_id, :access_key_id
    it_behaves_like 'deprecated option', :aws_secret_access_key, :secret_access_key
    it_behaves_like 'deprecated option', :aws_region, :region
  end
end
