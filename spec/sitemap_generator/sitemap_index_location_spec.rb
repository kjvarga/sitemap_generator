# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::SitemapIndexLocation do
  subject(:location) { described_class.new }

  it 'has a default namer', :aggregate_failures do
    expect(location[:namer]).not_to be_nil
    expect(location[:filename]).to be_nil
    expect(location.filename).to eq('sitemap.xml.gz')
  end
end
