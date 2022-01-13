require 'spec_helper'
require 'aws-sdk-core'
require 'aws-sdk-s3'

describe 'SitemapGenerator::AwsSdkAdapter' do
  let(:location) { SitemapGenerator::SitemapLocation.new(compress: compress) }
  let(:adapter)  { SitemapGenerator::AwsSdkAdapter.new('bucket', options) }
  let(:options) { {} }
  let(:compress) { nil }

  shared_examples 'it writes the raw data to a file and then uploads that file to S3' do
    it 'writes the raw data to a file and then uploads that file to S3' do
      s3_object = double(:s3_object)
      s3_resource = double(:s3_resource)
      s3_bucket_resource = double(:s3_bucket_resource)
      expect(adapter).to receive(:s3_resource).and_return(s3_resource)
      expect(s3_resource).to receive(:bucket).with('bucket').and_return(s3_bucket_resource)
      expect(s3_bucket_resource).to receive(:object).with('path_in_public').and_return(s3_object)
      expect(location).to receive(:path_in_public).and_return('path_in_public')
      expect(location).to receive(:path).and_return('path')
      expect(s3_object).to receive(:upload_file).with('path', hash_including(
        acl: 'public-read',
        cache_control: 'private, max-age=0, no-cache',
        content_type: content_type
      )).and_return(nil)
      expect_any_instance_of(SitemapGenerator::FileAdapter).to receive(:write).with(location, 'raw_data')
      adapter.write(location, 'raw_data')
    end
  end

  context 'when Aws::S3::Resource is not defined' do
    it 'raises a LoadError' do
      hide_const('Aws::S3::Resource')
      expect do
        load File.expand_path('./lib/sitemap_generator/adapters/aws_sdk_adapter.rb')
      end.to raise_error(LoadError, /Error: `Aws::S3::Resource` and\/or `Aws::Credentials` are not defined/)
    end
  end

  context 'when Aws::Credentials is not defined' do
    it 'raises a LoadError' do
      hide_const('Aws::Credentials')
      expect do
        load File.expand_path('./lib/sitemap_generator/adapters/aws_sdk_adapter.rb')
      end.to raise_error(LoadError, /Error: `Aws::S3::Resource` and\/or `Aws::Credentials` are not defined/)
    end
  end

  describe 'write' do
    context 'with no compress option' do
      let(:content_type) { 'application/xml' }

      it_behaves_like 'it writes the raw data to a file and then uploads that file to S3'
    end

    context 'with compress true' do
      let(:content_type) { 'application/x-gzip' }
      let(:compress) { true }

      it_behaves_like 'it writes the raw data to a file and then uploads that file to S3'
    end
  end

  describe 's3_resource' do
    it 'returns a new S3 resource' do
      s3_resource_options = double(:s3_resource_options)
      expect(adapter).to receive(:s3_resource_options).and_return(s3_resource_options)
      expect(Aws::S3::Resource).to receive(:new).with(s3_resource_options).and_return('resource')
      expect(adapter.send(:s3_resource)).to eql('resource')
    end
  end

  describe 's3_resource_options' do
    it 'does not include region' do
      expect(adapter.send(:s3_resource_options)[:region]).to be_nil
    end

    it 'does not include credentials' do
      expect(adapter.send(:s3_resource_options)[:credentials]).to be_nil
    end

    context 'with AWS region option' do
      let(:options) { { aws_region: 'region' } }

      it 'includes the region' do
        expect(adapter.send(:s3_resource_options)[:region]).to eql('region')
      end
    end

    it 'does not include endpoint' do
      expect(adapter.send(:s3_resource_options)[:endpoint]).to be_nil
    end

    context 'with AWS endpoint option' do
      let(:options) { { aws_endpoint: 'endpoint' } }

      it 'includes the endpoint' do
        expect(adapter.send(:s3_resource_options)[:endpoint]).to eql('endpoint')
      end
    end

    context 'with AWS access key id and secret access key options' do
      let(:options) do
        {
          aws_access_key_id: 'access_key_id',
          aws_secret_access_key: 'secret_access_key'
        }
      end

      it 'includes the credentials' do
        credentials = adapter.send(:s3_resource_options)[:credentials]
        expect(credentials).to be_a(Aws::Credentials)
        expect(credentials.access_key_id).to eql('access_key_id')
        expect(credentials.secret_access_key).to eql('secret_access_key')
      end
    end
  end
end
