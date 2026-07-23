# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::Sitemap do
  subject(:sitemap) { described_class }

  it 'has a class name' do
    expect(sitemap.class.name).to match 'SitemapGenerator::'
  end

  describe 'method missing' do
    it 'is not public' do
      expect(sitemap.methods).not_to include :method_missing
    end

    it 'responds properly' do
      expect(sitemap.method(:default_host)).to be_a Method
    end

    it 'respects inheritance' do
      sitemap.class.include(Module.new do
        def method_missing(*_args)
          :inherited
        end

        def respond_to_missing?(name, *)
          name == :something_inherited
        end
      end)

      expect(sitemap).to respond_to :something_inherited
      expect(sitemap.linkset_doesnt_know).to be :inherited
    end

    it 'unconventionally delegates private (and protected) methods' do
      expect { sitemap.options_for_group({}) }.not_to raise_error
    end
  end
end
