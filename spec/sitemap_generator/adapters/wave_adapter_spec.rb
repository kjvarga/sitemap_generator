# encoding: UTF-8
require 'spec_helper'

describe 'SitemapGenerator::WaveAdapter' do
  context 'when CarrierWave::Uploader::Base is not defined' do
    it 'raises a LoadError' do
      hide_const('CarrierWave::Uploader::Base')
      expect do
        load File.expand_path('./lib/sitemap_generator/adapters/wave_adapter.rb')
      end.to raise_error(LoadError, /Error: `CarrierWave::Uploader::Base` is not defined./)
    end
  end
end
