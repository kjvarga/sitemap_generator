# encoding: UTF-8
require 'spec_helper'
require 'fog-aws'

describe SitemapGenerator::S3Adapter do
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

  context 'when Fog::Storage is not defined' do
    it 'raises a LoadError' do
      hide_const('Fog::Storage')
      expect do
        load File.expand_path('./lib/sitemap_generator/adapters/s3_adapter.rb')
      end.to raise_error(LoadError, /Error: `Fog::Storage` is not defined./)
    end
  end

  describe 'write' do
    it 'creates the file in S3 with a single operation' do
      expect(Fog::Storage).to receive(:new).and_return(directories)
      subject.write(location, 'payload')
    end
  end
end
