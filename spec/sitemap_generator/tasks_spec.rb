# frozen_string_literal: true

require 'spec_helper'
require 'rake'
require 'sitemap_generator/tasks'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'Rake Tasks' do
  # rubocop:enable RSpec/DescribeClass
  before do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
  end

  describe 'sitemap:create rake task' do
    context 'when Rake verbose is true and SitemapGenerator.verbose is false' do
      before do
        SitemapGenerator::Sitemap.verbose = false
        allow(Rake).to receive(:verbose).and_return(true)
      end

      after do
        SitemapGenerator::Sitemap.reset!
      end

      it 'does not pass verbose: to Interpreter.run' do
        expect(SitemapGenerator::Interpreter).to receive(:run).with(hash_excluding(:verbose))
        Rake::Task['sitemap:create'].execute
      end
    end
  end
end
