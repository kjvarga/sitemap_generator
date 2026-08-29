# frozen_string_literal: true

require 'spec_helper'
require 'rake'
require 'sitemap_generator/tasks'

# Regression coverage for the verbose precedence of the `sitemap:create` task.
#
# Verbose is resolved from, highest precedence first: an explicit rake flag
# (-v/--verbose, -s/--silent, -q/--quiet), ENV['VERBOSE'], the value set in
# application code, and finally the default of +true+.  Signals from outside the
# application win so that output can be turned on or off for a single run
# without editing `config/sitemap.rb`.
#
# The regression these guard against: rake's verbose flag defaults to a truthy
# sentinel object rather than to +true+/+false+.  Forwarding it unconditionally
# makes `SitemapGenerator.verbose = false` unusable, and not reading it at all
# makes `rake -s` unable to silence the output.
# rubocop:disable RSpec/DescribeClass
RSpec.describe 'sitemap:create rake task' do
  # rubocop:enable RSpec/DescribeClass
  around do |example|
    original_flag = Rake::FileUtilsExt.verbose_flag
    original_env = ENV.fetch('VERBOSE', nil)
    original_verbose = SitemapGenerator.configured_verbose
    example.run
  ensure
    Rake::FileUtilsExt.verbose_flag = original_flag
    ENV['VERBOSE'] = original_env
    SitemapGenerator.verbose = original_verbose
    SitemapGenerator.verbose_override = nil
    SitemapGenerator::Sitemap.reset!
  end

  before do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    allow(SitemapGenerator::Interpreter).to receive(:run)
    # Start every example from a completely unconfigured state.
    Rake::FileUtilsExt.verbose_flag = Rake::FileUtilsExt::DEFAULT
    ENV['VERBOSE'] = nil
    SitemapGenerator.verbose = nil
    SitemapGenerator.verbose_override = nil
    SitemapGenerator::Sitemap.reset!
  end

  # Resolved verbose as the generator would see it when writing its summary.
  def resolved_verbose
    Rake::Task['sitemap:create'].execute
    SitemapGenerator::Sitemap.verbose
  end

  # Simulates `config/sitemap.rb`, which is evaluated *after* the task body runs.
  def config_file_sets_verbose(value)
    allow(SitemapGenerator::Interpreter).to receive(:run) do
      SitemapGenerator::Sitemap.verbose = value
    end
  end

  describe 'the options passed to the interpreter' do
    it 'omits verbose, so the task cannot clobber the config file' do
      expect(SitemapGenerator::Interpreter).to receive(:run).with(hash_excluding(:verbose))
      Rake::Task['sitemap:create'].execute
    end
  end

  # Invoking the task programmatically -- from a test suite, `rails runner`, or a
  # background job -- never parses a command line, so rake's verbose flag is left
  # at its truthy sentinel default.  Issue #332 was reported from exactly this
  # setup: the sentinel was forwarded as the verbose value and `SitemapGenerator
  # .verbose = false` appeared to do nothing.
  context 'when no rake flag is given' do
    it 'leaves the override unset' do
      Rake::Task['sitemap:create'].execute
      expect(SitemapGenerator.verbose_override).to be_nil
    end

    it 'never resolves verbose to rake\'s sentinel object' do
      expect(resolved_verbose).to be(true).or be(false)
    end

    context 'when nothing is configured' do
      it 'defaults to verbose' do
        expect(resolved_verbose).to be(true)
      end
    end

    context 'when SitemapGenerator.verbose is false' do
      before { SitemapGenerator.verbose = false }

      it 'is silent without needing the Rake::FileUtilsExt.verbose workaround' do
        expect(resolved_verbose).to be(false)
      end
    end

    context 'when silenced with the Rake::FileUtilsExt.verbose(false) workaround' do
      before { Rake::FileUtilsExt.verbose(false) }

      it 'is still silent, so the documented workaround keeps working' do
        expect(resolved_verbose).to be(false)
      end
    end

    context 'when the config file sets verbose to false' do
      before { config_file_sets_verbose(false) }

      it 'is not verbose' do
        expect(resolved_verbose).to be(false)
      end
    end
  end

  context 'when -s/-q is given' do
    before { Rake.verbose(false) }

    context 'when nothing else is configured' do
      it 'silences the output' do
        expect(resolved_verbose).to be(false)
      end
    end

    context 'when the config file asked for verbose' do
      before { config_file_sets_verbose(true) }

      it 'silences the output' do
        expect(resolved_verbose).to be(false)
      end
    end

    context 'when ENV asked for verbose' do
      before { ENV['VERBOSE'] = 'true' }

      it 'silences the output' do
        expect(resolved_verbose).to be(false)
      end
    end
  end

  context 'when -v is given' do
    before { Rake.verbose(true) }

    context 'when SitemapGenerator.verbose is false' do
      before { SitemapGenerator.verbose = false }

      it 'enables the output' do
        expect(resolved_verbose).to be(true)
      end
    end

    context 'when the config file set verbose to false' do
      before { config_file_sets_verbose(false) }

      it 'enables the output' do
        expect(resolved_verbose).to be(true)
      end
    end

    context 'when ENV asked for silence' do
      before { ENV['VERBOSE'] = 'false' }

      it 'enables the output' do
        expect(resolved_verbose).to be(true)
      end
    end
  end

  context "when ENV['VERBOSE'] is set and no rake flag is given" do
    context 'when the config file also sets verbose' do
      before do
        ENV['VERBOSE'] = 'true'
        config_file_sets_verbose(false)
      end

      it 'takes precedence over the config file' do
        expect(resolved_verbose).to be(true)
      end
    end

    context 'when SitemapGenerator.verbose is also set' do
      before do
        ENV['VERBOSE'] = 'false'
        SitemapGenerator.verbose = true
      end

      it 'takes precedence over the value set in code' do
        expect(resolved_verbose).to be(false)
      end
    end

    context 'when it holds a value which is neither truthy nor falsy' do
      before do
        ENV['VERBOSE'] = 'maybe'
        SitemapGenerator.verbose = false
      end

      it 'is ignored in favour of the value set in code' do
        expect(resolved_verbose).to be(false)
      end
    end
  end
end
