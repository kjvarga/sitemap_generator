# encoding: UTF-8
require 'spec_helper'
require 'fog-aws'

describe SitemapGenerator::S3Adapter do
  subject(:adapter) { described_class.new(options) }

  let(:location) do
    SitemapGenerator::SitemapLocation.new(
      :namer => SitemapGenerator::SimpleNamer.new(:sitemap),
      :public_path => 'tmp/',
      :sitemaps_path => 'test/',
      :host => 'http://example.com/')
  end
  let(:directory) do
    double('directory',
      :files => double('files', :create => nil)
    )
  end
  let(:directories) do
    double('directories',
      :directories =>
        double('directory class',
          :new => directory
        )
    )
  end
  let(:options) do
    {
      aws_access_key_id: 'aws_access_key_id',
      aws_secret_access_key: 'aws_secret_access_key',
      fog_provider: 'fog_provider',
      fog_directory: 'fog_directory',
      fog_region: 'fog_region',
      fog_path_style: 'fog_path_style',
      fog_storage_options: {},
      fog_public: false,
    }
  end

  context 'when Fog::Storage is not defined' do
    it 'raises a LoadError' do
      hide_const('Fog::Storage')
      expect do
        load File.expand_path('./lib/sitemap_generator/adapters/s3_adapter.rb')
      end.to raise_error(LoadError, /Error: `Fog::Storage` is not defined./)
    end
  end

  describe 'initialize' do
    it 'sets options on the instance' do
      expect(adapter.instance_variable_get(:@aws_access_key_id)).to eq('aws_access_key_id')
      expect(adapter.instance_variable_get(:@aws_secret_access_key)).to eq('aws_secret_access_key')
      expect(adapter.instance_variable_get(:@fog_provider)).to eq('fog_provider')
      expect(adapter.instance_variable_get(:@fog_directory)).to eq('fog_directory')
      expect(adapter.instance_variable_get(:@fog_region)).to eq('fog_region')
      expect(adapter.instance_variable_get(:@fog_path_style)).to eq('fog_path_style')
      expect(adapter.instance_variable_get(:@fog_storage_options)).to eq(options[:fog_storage_options])
      expect(adapter.instance_variable_get(:@fog_public)).to eq(false)
    end

    context 'fog_public' do
      let(:options) do
        { fog_public: nil }
      end

      it 'defaults to true' do
        expect(adapter.instance_variable_get(:@fog_public)).to eq(true)
      end

      context 'when a string value' do
        let(:options) do
          { fog_public: 'false' }
        end

        it 'converts to a boolean' do
          expect(adapter.instance_variable_get(:@fog_public)).to eq(false)
        end
      end
    end
  end

  describe 'write' do
    it 'creates the file in S3 with a single operation' do
      expect(Fog::Storage).to receive(:new).and_return(directories)
      expect(directory.files).to receive(:create).with(
        body: instance_of(File),
        key: 'test/sitemap.xml.gz',
        public: false,
      )
      adapter.write(location, 'payload')
    end
  end
end
