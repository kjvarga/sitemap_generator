# frozen_string_literal: true

require 'spec_helper'
require 'rake'
require 'sitemap_generator/tasks'

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe SitemapGenerator::Interpreter do
  # rubocop:enable RSpec/SpecFilePathFormat

  before do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
  end

  describe 'sitemap:create rake task' do
    context 'when Rake verbose is true and SitemapGenerator.verbose is false' do
      before do
        SitemapGenerator::Sitemap.verbose = false
        allow(Rake).to receive(:verbose).and_return(true)
        allow(described_class).to receive(:run)
      end

      after do
        SitemapGenerator::Sitemap.reset!
      end

      it 'does not pass verbose: to Interpreter.run' do
        Rake::Task['sitemap:create'].execute
        expect(described_class).to have_received(:run).with(hash_excluding(:verbose))
      end
    end
  end
end
