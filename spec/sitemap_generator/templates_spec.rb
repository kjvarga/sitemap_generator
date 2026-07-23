# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::Templates do
  it 'provides method access to each template' do
    SitemapGenerator::Templates::FILES.each do |name, file|
      expect(SitemapGenerator.templates.send(name)).not_to be_nil
      expect(SitemapGenerator.templates.send(name)).to eq(File.read(File.join(SitemapGenerator.root, 'templates',
                                                                              file)))
    end
  end

  describe 'templates' do
    before do
      SitemapGenerator.templates.sitemap_sample = nil
    end

    it 'reads the template file only once' do
      expect(File).to receive(:read).and_return('read file').once
      SitemapGenerator.templates.sitemap_sample
      SitemapGenerator.templates.sitemap_sample
    end
  end
end
