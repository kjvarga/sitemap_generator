require 'spec_helper'
require 'aws-sdk-core'
require 'aws-sdk-s3'

describe SitemapGenerator::AwsSdkAdapter do
  subject(:adapter)  { described_class.new('bucket', **options) }

  let(:location) { SitemapGenerator::SitemapLocation.new(compress: compress) }
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

  describe '#write' do
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

  describe '#initialize' do
    context 'with region option' do
      let(:options) { { region: 'region' } }

      it 'sets region in options' do
        expect(adapter.instance_variable_get(:@options)[:region]).to eql('region')
      end
    end

    context 'with deprecated aws_region option' do
      let(:options) { { aws_region: 'region' } }

      it 'sets region in options' do
        expect(adapter.instance_variable_get(:@options)[:region]).to eql('region')
      end
    end

    context 'with access_key_id option' do
      let(:options) do
        { access_key_id: 'access_key_id' }
      end

      it 'sets access_key_id in options' do
        expect(adapter.instance_variable_get(:@options)[:access_key_id]).to eq('access_key_id')
      end
    end

    context 'with deprecated aws_access_key_id option' do
      let(:options) do
        { aws_access_key_id: 'access_key_id' }
      end

      it 'sets access_key_id in options' do
        expect(adapter.instance_variable_get(:@options)[:access_key_id]).to eq('access_key_id')
      end
    end

    context 'with secret_access_key option' do
      let(:options) do
        { secret_access_key: 'secret_access_key' }
      end

      it 'sets secret_access_key in options' do
        expect(adapter.instance_variable_get(:@options)[:secret_access_key]).to eq('secret_access_key')
      end
    end

    context 'with deprecated aws_secret_access_key option' do
      let(:options) do
        { aws_secret_access_key: 'secret_access_key' }
      end

      it 'sets secret_access_key in options' do
        expect(adapter.instance_variable_get(:@options)[:secret_access_key]).to eq('secret_access_key')
      end
    end

    context 'with endpoint option' do
      let(:options) do
        { endpoint: 'endpoint' }
      end

      it 'sets endpoint in options' do
        expect(adapter.instance_variable_get(:@options)[:endpoint]).to eq('endpoint')
      end
    end

    context 'with deprecated aws_endpoint option' do
      let(:options) do
        { aws_endpoint: 'endpoint' }
      end

      it 'sets endpoint in options' do
        expect(adapter.instance_variable_get(:@options)[:endpoint]).to eq('endpoint')
      end

      context 'if option is nil' do
        let(:options) do
          { aws_endpoint: nil }
        end

        it 'does not set endpoint in options' do
          expect(adapter.instance_variable_get(:@options)).not_to have_key(:endpoint)
        end
      end
    end
  end
end
