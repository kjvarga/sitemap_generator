# frozen_string_literal: true

require 'spec_helper'
require 'fog-aws'

RSpec.describe SitemapGenerator::S3Adapter do
  subject(:adapter) { described_class.new(options) }

  let(:location) do
    SitemapGenerator::SitemapLocation.new(
      namer: SitemapGenerator::SimpleNamer.new(:sitemap),
      public_path: 'tmp/',
      sitemaps_path: 'test/',
      host: 'http://example.com/'
    )
  end
  let(:directory) do
    double('directory',
           files: double('files', create: nil))
  end
  let(:directories) do
    double('directories',
           directories: double('directory class',
                               new: directory))
  end
  let(:options) do
    {
      aws_access_key_id: 'aws_access_key_id',
      aws_secret_access_key: 'aws_secret_access_key',
      aws_session_token: 'aws_session_token',
      fog_provider: 'fog_provider',
      fog_directory: 'fog_directory',
      fog_region: 'fog_region',
      fog_path_style: 'fog_path_style',
      fog_storage_options: {},
      fog_public: false
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
      option_ivar_mapping.each { |ivar, value| expect(adapter.instance_variable_get(ivar)).to eq(value) }
    end

    def option_ivar_mapping
      {
        :@aws_access_key_id => 'aws_access_key_id',
        :@aws_secret_access_key => 'aws_secret_access_key',
        :@aws_session_token => 'aws_session_token',
        :@fog_provider => 'fog_provider',
        :@fog_directory => 'fog_directory',
        :@fog_region => 'fog_region',
        :@fog_path_style => 'fog_path_style'
      }.merge(:@fog_storage_options => options[:fog_storage_options], :@fog_public => false)
    end

    context 'when fog_public is nil' do
      let(:options) do
        { fog_public: nil }
      end

      it 'defaults to true' do
        expect(adapter.instance_variable_get(:@fog_public)).to be(true)
      end
    end

    context 'when fog_public is a string value' do
      let(:options) do
        { fog_public: 'false' }
      end

      it 'converts to a boolean' do
        expect(adapter.instance_variable_get(:@fog_public)).to be(false)
      end
    end
  end

  describe 'write' do
    before { allow(Fog::Storage).to receive(:new).and_return(directories) }

    it 'creates the file in S3 with a single operation' do
      expect(directory.files).to receive(:create).with(single_operation_upload_attrs)
      adapter.write(location, 'payload')
    end

    def single_operation_upload_attrs
      {
        body: instance_of(File),
        key: 'test/sitemap.xml.gz',
        public: false,
        content_type: 'application/x-gzip'
      }
    end

    context 'when the path ends in .xml' do
      let(:location) do
        SitemapGenerator::SitemapLocation.new(
          namer: SitemapGenerator::SimpleNamer.new(:sitemap),
          public_path: 'tmp/',
          sitemaps_path: 'test/',
          host: 'http://example.com/',
          compress: false
        )
      end

      it 'sets content_type to application/xml' do
        expect(directory.files).to receive(:create).with(
          hash_including(content_type: 'application/xml')
        )
        adapter.write(location, 'payload')
      end
    end
  end
end
