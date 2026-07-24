# frozen_string_literal: true

require 'spec_helper'
require 'sitemap_generator/interpreter'

RSpec.describe SitemapGenerator::Interpreter do
  include SitemapHelpers

  let(:link_set)    { SitemapGenerator::LinkSet.new }
  let(:interpreter) { described_class.new(link_set: link_set) }

  before :all do
    SitemapGenerator::Sitemap.reset!
    clean_sitemap_files_from_rails_app
    copy_sitemap_file_to_rails_app(:create)
    with_max_links(10) { execute_sitemap_config }
  end

  # The interpreter doesn't have the URL helpers included for some reason, so it
  # fails when adding links.  That messes up later specs unless we reset the sitemap object.
  after :all do
    SitemapGenerator::Sitemap.reset!
    delete_sitemap_file_from_rails_app
  end

  it "finds the config file if Rails.root doesn't end in a slash" do
    stub_const('Rails', double('Rails', root: SitemapGenerator.app.root.to_s.sub(%r{/$}, '')))
    expect { described_class.run }.not_to raise_error
  end

  it 'sets the verbose option' do
    expect_any_instance_of(described_class).to receive(:instance_eval)
    interpreter = described_class.run(verbose: true)
    expect(interpreter.instance_variable_get(:@linkset).verbose).to be(true)
  end

  describe 'link_set' do
    it 'defaults to the default LinkSet' do
      expect(described_class.new.sitemap).to be(SitemapGenerator::Sitemap)
    end

    it 'allows setting the LinkSet as an option' do
      expect(interpreter.sitemap).to be(link_set)
    end
  end

  describe 'public interface' do
    describe 'add' do
      it 'adds a link to the sitemap' do
        expect(link_set).to receive(:add).with('test', { option: 'value' })
        interpreter.add('test', option: 'value')
      end
    end

    describe 'group' do
      it 'starts a new group' do
        expect(link_set).to receive(:group).with('test', { option: 'value' })
        interpreter.group('test', option: 'value')
      end
    end

    describe 'sitemap' do
      it 'returns the LinkSet' do
        expect(interpreter.sitemap).to be(link_set)
      end
    end

    describe 'add_to_index' do
      it 'adds a link to the sitemap index' do
        expect(link_set).to receive(:add_to_index).with('test', { option: 'value' })
        interpreter.add_to_index('test', option: 'value')
      end
    end
  end

  describe '#default_url_options' do
    context 'when ActionController::Base is not defined' do
      before { hide_const('ActionController::Base') }

      it 'returns an empty hash' do
        expect(interpreter.default_url_options).to eq({})
      end
    end

    context 'when ActionController::Base is defined' do
      let(:base_class) { double('ActionController::Base') }

      before { stub_const('ActionController::Base', base_class) }

      context 'when default_url_options has values' do
        before { allow(base_class).to receive(:default_url_options).and_return({ trailing_slash: true }) }

        it 'returns the configured options' do
          expect(interpreter.default_url_options).to eq({ trailing_slash: true })
        end
      end

      context 'when default_url_options returns nil' do
        before { allow(base_class).to receive(:default_url_options).and_return(nil) }

        it 'returns an empty hash' do
          expect(interpreter.default_url_options).to eq({})
        end
      end
    end
  end

  describe 'eval' do
    it 'yields the LinkSet to the block' do
      interpreter.eval(yield_sitemap: true) do |sitemap|
        expect(sitemap).to be(link_set)
      end
    end

    # rubocop:disable RSpec/NoExpectationExample -- explicit receiver (this.expect), cop only recognizes bare expect()
    it 'does not yield the LinkSet to the block' do
      # Assign self to a local variable so it is captured by the block
      this = self
      interpreter.eval(yield_sitemap: false) do
        this.expect(self).to this.be(this.interpreter)
      end
    end

    it 'does not yield the LinkSet to the block by default' do
      # Assign self to a local variable so it is captured by the block
      this = self
      interpreter.eval do
        this.expect(self).to this.be(this.interpreter)
      end
    end
    # rubocop:enable RSpec/NoExpectationExample
  end
end
