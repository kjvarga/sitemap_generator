# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::Application do
  let(:app) { described_class.new }

  before do
    stub_const('Rails::VERSION', '1')
  end

  describe 'is_at_least_rails3?' do
    let(:tests) do
      {
        :nil => false,
        '2.3.11' => false,
        '3.0.1' => true,
        '3.0.11' => true
      }
    end

    it 'identifies the rails version correctly' do
      tests.each do |version, result|
        allow(Rails).to receive(:version).and_return(version)
        expect(app.is_at_least_rails3?).to eq(result)
      end
    end
  end

  describe 'with Rails' do
    let(:root) { '/test' }

    it 'uses the Rails.root', :aggregate_failures do
      expect(Rails).to receive(:root).and_return(root).at_least(:once)
      expect(app.root).to be_a(Pathname)
      expect(app.root.to_s).to eq(root)
      expect(app.root.join('public/').to_s).to eq(File.join(root, 'public/'))
    end
  end

  describe 'with no Rails' do
    before do
      hide_const('Rails')
    end

    it 'is not Rails' do
      expect(app.is_rails?).to be(false)
    end

    it 'uses the current working directory', :aggregate_failures do
      expect(app.root).to be_a(Pathname)
      expect(app.root.to_s).to eq(Dir.getwd)
      expect(app.root.join('public/').to_s).to eq(File.join(Dir.getwd, 'public/'))
    end
  end
end
