# encoding: UTF-8
require 'spec_helper'
require 'fog-aws'

RSpec.describe SitemapGenerator::FogAdapter do
  context 'when Fog::Storage is not defined' do
    it 'raises a LoadError' do
      hide_const('Fog::Storage')
      expect do
        load File.expand_path('./lib/sitemap_generator/adapters/fog_adapter.rb')
      end.to raise_error(LoadError, /Error: `Fog::Storage` is not defined./)
    end
  end
end
