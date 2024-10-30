require 'spec_helper'

RSpec.describe SitemapGenerator::Application do
  before do
    stub_const('Rails::VERSION', '1')
    @app = SitemapGenerator::Application.new
  end

  describe 'is_at_least_rails3?' do
    tests = {
      :nil => false,
      '2.3.11' => false,
      '3.0.1' => true,
      '3.0.11' => true
    }

    it 'should identify the rails version correctly' do
      tests.each do |version, result|
        expect(Rails).to receive(:version).and_return(version)
        expect(@app.is_at_least_rails3?).to eq(result)
      end
    end
  end

  describe 'with Rails' do
    before do
      @root = '/test'
      expect(Rails).to receive(:root).and_return(@root).at_least(:once)
    end

    it 'should use the Rails.root' do
      expect(@app.root).to be_a(Pathname)
      expect(@app.root.to_s).to eq(@root)
      expect((@app.root + 'public/').to_s).to eq(File.join(@root, 'public/'))
    end
  end

  describe 'with no Rails' do
    before do
      hide_const('Rails')
    end

    it 'should not be Rails' do
      expect(@app.is_rails?).to be(false)
    end

    it 'should use the current working directory' do
      expect(@app.root).to be_a(Pathname)
      expect(@app.root.to_s).to eq(Dir.getwd)
      expect((@app.root + 'public/').to_s).to eq(File.join(Dir.getwd, 'public/'))
    end
  end
end
