require 'spec_helper'

RSpec.describe 'Templates class' do

  it 'should provide method access to each template' do
    SitemapGenerator::Templates::FILES.each do |name, file|
      expect(SitemapGenerator.templates.send(name)).not_to be(nil)
      expect(SitemapGenerator.templates.send(name)).to eq(File.read(File.join(SitemapGenerator.root, 'templates', file)))
    end
  end

  describe 'templates' do
    before do
      SitemapGenerator.templates.sitemap_sample = nil
      expect(File).to receive(:read).and_return('read file').once
    end

    it 'should only be read once' do
      SitemapGenerator.templates.sitemap_sample
      SitemapGenerator.templates.sitemap_sample
    end
  end
end
