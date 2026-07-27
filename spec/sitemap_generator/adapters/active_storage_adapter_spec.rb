# frozen_string_literal: true

require 'spec_helper'
require 'sitemap_generator/adapters/active_storage_adapter'

RSpec.describe 'SitemapGenerator::ActiveStorageAdapter' do
  let(:location) { SitemapGenerator::SitemapLocation.new }
  let(:adapter)  { SitemapGenerator::ActiveStorageAdapter.new }
  let(:fake_scope_class) do
    Class.new do
      # rubocop:disable Naming/PredicateMethod -- mimics ActiveRecord::Relation's real method name
      def destroy_all
        true
      end
      # rubocop:enable Naming/PredicateMethod
    end
  end

  let(:fake_active_storage_blob) do
    scope_class = fake_scope_class
    Class.new do
      define_singleton_method(:transaction) { |&block| block.call }
      define_singleton_method(:where) { |*_args| scope_class.new }
      define_singleton_method(:create_and_upload!) { |**_kwargs| 'ActiveStorage::Blob' }
    end
  end

  before do
    stub_const('ActiveStorage::Blob', fake_active_storage_blob)
  end

  describe 'write' do
    it 'creates an ActiveStorage::Blob record', :aggregate_failures do
      expect(location).to receive(:filename).and_return('sitemap.xml.gz').at_least(:twice)
      expect(adapter.write(location, 'data')).to eq 'ActiveStorage::Blob'
    end
  end
end
