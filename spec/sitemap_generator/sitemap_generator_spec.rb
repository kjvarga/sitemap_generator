# frozen_string_literal: true

require 'spec_helper'
require 'uri'

class Holder
  class << self
    attr_accessor :executed
  end
end

RSpec.describe 'SitemapGenerator' do
  include SitemapHelpers

  def expect_files(exist: [], not_exist: [])
    exist.each { |path| expect_file_to_exist(rails_path(path)) }
    not_exist.each { |path| expect_file_not_to_exist(rails_path(path)) }
  end

  def expect_schema_valid(mapping)
    mapping.each { |path, schema| expect_gzipped_xml_file_to_validate_against_schema(rails_path(path), schema) }
  end

  describe 'reset!' do
    before do
      SitemapGenerator::Sitemap.default_host # Force initialization of the LinkSet
    end

    # rubocop:disable RSpec/ExampleLength -- flowing before/after comparison, no extractable setup
    it 'sets a new LinkSet instance', :aggregate_failures do
      first = SitemapGenerator::Sitemap.instance_variable_get(:@link_set)
      expect(first).to be_a(SitemapGenerator::LinkSet)
      SitemapGenerator::Sitemap.reset!
      second = SitemapGenerator::Sitemap.instance_variable_get(:@link_set)
      expect(second).to be_a(SitemapGenerator::LinkSet)
      expect(first).not_to be(second)
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe 'root' do
    it 'is set to the root of the gem' do
      expect(SitemapGenerator.root).to eq(File.expand_path('../..', __dir__))
    end
  end

  describe 'generate sitemap with normal config' do
    before :all do
      SitemapGenerator::Sitemap.reset!
      clean_sitemap_files_from_rails_app
      copy_sitemap_file_to_rails_app(:create)
      with_max_links(10) { execute_sitemap_config }
    end

    after :all do
      delete_sitemap_file_from_rails_app
    end

    it 'creates sitemaps' do
      expect_files(exist: %w[public/sitemap.xml.gz public/sitemap1.xml.gz public/sitemap2.xml.gz],
                   not_exist: %w[public/sitemap3.xml.gz])
    end

    it 'has 13 links' do
      expect(SitemapGenerator::Sitemap.link_count).to eq(13)
    end

    it 'index XML should validate' do
      expect_gzipped_xml_file_to_validate_against_schema rails_path('public/sitemap.xml.gz'), 'siteindex'
    end

    it 'sitemap XML should validate' do
      expect_gzipped_xml_file_to_validate_against_schema rails_path('public/sitemap1.xml.gz'), 'sitemap'
      expect_gzipped_xml_file_to_validate_against_schema rails_path('public/sitemap2.xml.gz'), 'sitemap'
    end

    it 'index XML should not have excess whitespace' do
      expect_gzipped_xml_file_to_have_minimal_whitespace rails_path('public/sitemap.xml.gz')
    end

    it 'sitemap XML should not have excess whitespace' do
      expect_gzipped_xml_file_to_have_minimal_whitespace rails_path('public/sitemap1.xml.gz')
    end
  end

  describe 'sitemap with groups' do
    before :all do
      SitemapGenerator::Sitemap.reset!
      clean_sitemap_files_from_rails_app
      copy_sitemap_file_to_rails_app(:groups)
      with_max_links(2) { execute_sitemap_config }
      @expected = %w[
        public/en/xxx.xml.gz
        public/fr/abc3.xml.gz
        public/fr/abc4.xml.gz
        public/fr/def.xml.gz
        public/fr/new_sitemaps.xml.gz
        public/fr/new_sitemaps1.xml.gz
        public/fr/new_sitemaps2.xml.gz
        public/fr/new_sitemaps3.xml.gz
        public/fr/new_sitemaps4.xml.gz
      ]
      @sitemaps = (@expected - %w[public/fr/new_sitemaps.xml.gz])
    end

    after :all do
      delete_sitemap_file_from_rails_app
    end

    it 'creates sitemaps' do
      @expected.each { |file| expect_file_to_exist(rails_path(file)) }
      expect_files(not_exist: %w[public/fr/new_sitemaps5.xml.gz public/en/xxx1.xml.gz public/fr/abc5.xml.gz])
    end

    it 'has 16 links' do
      expect(SitemapGenerator::Sitemap.link_count).to eq(16)
    end

    it 'index XML should validate' do
      expect_gzipped_xml_file_to_validate_against_schema rails_path('public/fr/new_sitemaps.xml.gz'), 'siteindex'
    end

    it 'index XML should not have excess whitespace' do
      expect_gzipped_xml_file_to_have_minimal_whitespace rails_path('public/fr/new_sitemaps.xml.gz')
    end

    it 'sitemaps XML should validate' do
      @sitemaps.each { |file| expect_gzipped_xml_file_to_validate_against_schema(rails_path(file), 'sitemap') }
    end

    it 'sitemap XML should not have excess whitespace' do
      @sitemaps.each { |file| expect_gzipped_xml_file_to_have_minimal_whitespace(rails_path(file)) }
    end
  end

  describe 'links added manually with a custom starting index' do
    before do
      clean_sitemap_files_from_rails_app
      SitemapGenerator::Sitemap.reset!
      SitemapGenerator::Sitemap.default_host = 'http://www.example.com'
      SitemapGenerator::Sitemap.namer = SitemapGenerator::SimpleNamer.new(:sitemap, start: 4)
      SitemapGenerator::Sitemap.create do
        3.times do |i|
          add_to_index "sitemap#{i}.xml.gz"
        end
        add '/home'
      end
    end

    it 'creates the index and start the sitemap numbering from 4' do
      expect_files(exist: %w[public/sitemap.xml.gz public/sitemap4.xml.gz])
      expect_schema_valid('public/sitemap.xml.gz' => 'siteindex', 'public/sitemap4.xml.gz' => 'sitemap')
    end
  end

  describe 'create_index behavior with manually added links' do
    before do
      clean_sitemap_files_from_rails_app
      SitemapGenerator::Sitemap.reset!
      SitemapGenerator::Sitemap.default_host = 'http://www.example.com'
      SitemapGenerator::Sitemap.include_root = false
    end

    # rubocop:disable RSpec/ExampleLength -- the add/add_to_index call sequence is the scenario under test
    it 'creates the index when add_to_index is called before the sitemap links' do
      with_max_links(1) do
        SitemapGenerator::Sitemap.create do
          add_to_index 'customsitemap.xml.gz'
          add '/one'
          add '/two'
        end
      end
      expect_files(exist: %w[public/sitemap.xml.gz public/sitemap1.xml.gz public/sitemap2.xml.gz],
                   not_exist: %w[public/sitemap3.xml.gz])
      expect_schema_valid('public/sitemap.xml.gz' => 'siteindex')
    end

    it 'creates the index when add_to_index is called between the sitemap links' do
      with_max_links(1) do
        SitemapGenerator::Sitemap.create do
          add '/one'
          add_to_index 'customsitemap.xml.gz'
          add '/two'
        end
      end
      expect_files(exist: %w[public/sitemap.xml.gz public/sitemap1.xml.gz public/sitemap2.xml.gz],
                   not_exist: %w[public/sitemap3.xml.gz])
      expect_schema_valid('public/sitemap.xml.gz' => 'siteindex')
    end
    # rubocop:enable RSpec/ExampleLength

    it 'creates an index for a single manually added link' do
      with_max_links(1) do
        SitemapGenerator::Sitemap.create(create_index: :auto) { add_to_index 'customsitemap1.xml.gz' }
      end
      expect_files(exist: %w[public/sitemap.xml.gz], not_exist: %w[public/sitemap1.xml.gz])
      expect_schema_valid('public/sitemap.xml.gz' => 'siteindex')
    end

    # rubocop:disable RSpec/ExampleLength -- the 3 add_to_index calls are the scenario under test
    it 'creates an index for multiple manually added links' do
      with_max_links(1) do
        SitemapGenerator::Sitemap.create(create_index: :auto) do
          add_to_index 'customsitemap1.xml.gz'
          add_to_index 'customsitemap2.xml.gz'
          add_to_index 'customsitemap3.xml.gz'
        end
      end
      expect_files(exist: %w[public/sitemap.xml.gz], not_exist: %w[public/sitemap1.xml.gz])
      expect_schema_valid('public/sitemap.xml.gz' => 'siteindex')
    end

    it 'does not create an index or a sitemap when only manually added links exist' do
      # Create index is explicity turned off and no links added to sitemap,
      # respect the setting and don't create the index.  There is no sitemap file either.
      SitemapGenerator::Sitemap.create(create_index: false) do
        add_to_index 'customsitemap1.xml.gz'
        add_to_index 'customsitemap2.xml.gz'
        add_to_index 'customsitemap3.xml.gz'
      end
      expect_files(not_exist: %w[public/sitemap.xml.gz public/sitemap1.xml.gz])
    end
    # rubocop:enable RSpec/ExampleLength

    it 'does not create an index when a link is added normally' do
      SitemapGenerator::Sitemap.create(create_index: false) { add '/one' }
      expect_files(exist: %w[public/sitemap.xml.gz], not_exist: %w[public/sitemap1.xml.gz]) # the sitemap, not an index
      expect_schema_valid('public/sitemap.xml.gz' => 'sitemap')
    end
  end

  describe 'sitemap path' do
    before do
      clean_sitemap_files_from_rails_app
      SitemapGenerator::Sitemap.reset!
      SitemapGenerator::Sitemap.default_host = 'http://test.local'
      SitemapGenerator::Sitemap.filename = 'sitemap'
      SitemapGenerator::Sitemap.create_index = true
    end

    it 'allows changing of the filename' do
      SitemapGenerator::Sitemap.create(filename: :geo_sitemap) do
        add '/goerss'
        add '/kml'
      end
      expect_files(exist: %w[public/geo_sitemap.xml.gz public/geo_sitemap1.xml.gz])
    end

    it 'supports setting a sitemap path' do
      expect_directory_not_to_exist(rails_path('public/sitemaps/'))
      SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'
      create_sitemap_with_links('/', '/another')
      expect_files(exist: %w[public/sitemaps/sitemap.xml.gz public/sitemaps/sitemap1.xml.gz])
    end

    it 'supports setting a deeply nested sitemap path' do
      expect_directory_not_to_exist(rails_path('public/sitemaps/deep/directory'))
      SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/deep/directory/'
      create_sitemap_with_links('/', '/another', '/yet-another')
      expect_files(exist: %w[public/sitemaps/deep/directory/sitemap.xml.gz
                             public/sitemaps/deep/directory/sitemap1.xml.gz])
    end

    def create_sitemap_with_links(*paths)
      SitemapGenerator::Sitemap.create { paths.each { |path| add(path) } }
    end
  end

  describe 'external dependencies' do
    it 'works outside of Rails' do
      hide_const('Rails')
      expect { SitemapGenerator::LinkSet.new }.not_to raise_exception
    end
  end

  describe 'verbose' do
    it "is set via ENV['VERBOSE']" do
      original = SitemapGenerator.verbose
      expect_verbose_reflects_env('true', true)
      expect_verbose_reflects_env('false', false)
      SitemapGenerator.verbose = original
    end

    def expect_verbose_reflects_env(env_value, expected)
      SitemapGenerator.verbose = nil
      ENV['VERBOSE'] = env_value
      expect(SitemapGenerator.verbose).to be(expected)
    end
  end

  describe 'yield_sitemap' do
    it 'sets the yield_sitemap flag' do
      results = [false, true].map { |value| toggle_yield_sitemap?(value) }
      SitemapGenerator.yield_sitemap = false
      expect(results).to eq([false, true])
    end

    def toggle_yield_sitemap?(value)
      SitemapGenerator.yield_sitemap = value
      SitemapGenerator.yield_sitemap?
    end
  end

  describe 'create_index' do
    let(:ls) do
      SitemapGenerator::LinkSet.new(
        include_root: false,
        default_host: 'http://example.com',
        create_index: create_index,
        max_sitemap_links: 1
      )
    end

    let!(:request) do
      stub_request(:get, "http://google.com/?url=#{URI.encode_www_form_component('http://example.com/sitemap.xml.gz')}")
    end

    before do
      clean_sitemap_files_from_rails_app
    end

    def expect_index_url_pinged
      ls.search_engines = { google: 'http://google.com/?url=%s' }
      ls.ping_search_engines
      expect(request).to have_been_requested.once
    end

    describe 'when true' do
      let(:create_index) { true }

      # rubocop:disable RSpec/ExampleLength -- exercises creation, file layout, schema, and search engine ping together
      it 'always creates the index when there is only one sitemap' do
        ls.create { add('/one') }
        expect(ls.sitemap_index.link_count).to eq(1) # one sitemap
        expect_files(exist: %w[public/sitemap.xml.gz public/sitemap1.xml.gz],
                     not_exist: %w[public/sitemap2.xml.gz])
        expect_schema_valid('public/sitemap.xml.gz' => 'siteindex', 'public/sitemap1.xml.gz' => 'sitemap')
        expect_index_url_pinged
      end

      it 'always creates the index when there are multiple sitemaps' do
        ls.create do
          add('/one')
          add('/two')
        end
        expect(ls.sitemap_index.link_count).to eq(2) # two sitemaps
        expect_files(exist: %w[public/sitemap.xml.gz public/sitemap1.xml.gz public/sitemap2.xml.gz])
        expect_schema_valid('public/sitemap.xml.gz' => 'siteindex', 'public/sitemap1.xml.gz' => 'sitemap',
                            'public/sitemap2.xml.gz' => 'sitemap')
        expect_index_url_pinged
      end
      # rubocop:enable RSpec/ExampleLength
    end

    # Technically when there's no index, the first sitemap is the 'index'
    # regardless of how many sitemaps were created, or if create_index is false.
    describe 'when false' do
      let(:create_index) { false }

      it 'never creates the index when there is only one sitemap' do
        ls.create { add('/one') }
        expect(ls.sitemap_index.link_count).to eq(1) # one sitemap
        expect_files(exist: %w[public/sitemap.xml.gz], not_exist: %w[public/sitemap1.xml.gz])
        expect_schema_valid('public/sitemap.xml.gz' => 'sitemap')
        expect_index_url_pinged
      end

      # rubocop:disable RSpec/ExampleLength -- exercises creation, file layout, schema, and search engine ping together
      it 'never creates the index when there are multiple sitemaps' do
        ls.create do
          add('/one')
          add('/two')
        end
        expect(ls.sitemap_index.link_count).to eq(2) # two sitemaps
        expect_files(exist: %w[public/sitemap.xml.gz public/sitemap1.xml.gz],
                     not_exist: %w[public/sitemap2.xml.gz])
        expect_schema_valid('public/sitemap.xml.gz' => 'sitemap', 'public/sitemap1.xml.gz' => 'sitemap')
        expect_index_url_pinged
      end
      # rubocop:enable RSpec/ExampleLength
    end

    describe 'when :auto' do
      let(:create_index) { :auto }

      it 'does not create index if only one sitemap file' do
        ls.create { add('/one') }
        expect(ls.sitemap_index.link_count).to eq(1) # one sitemap
        expect_files(exist: %w[public/sitemap.xml.gz], not_exist: %w[public/sitemap1.xml.gz])
        expect_schema_valid('public/sitemap.xml.gz' => 'sitemap')
        expect_index_url_pinged
      end

      # rubocop:disable RSpec/ExampleLength -- exercises creation, file layout, schema, and search engine ping together
      it 'creates index if more than one sitemap file' do
        ls.create do
          add('/one')
          add('/two')
        end
        expect(ls.sitemap_index.link_count).to eq(2) # two sitemaps
        expect_files(exist: %w[public/sitemap.xml.gz public/sitemap1.xml.gz public/sitemap2.xml.gz],
                     not_exist: %w[public/sitemap3.xml.gz])
        expect_schema_valid('public/sitemap.xml.gz' => 'siteindex', 'public/sitemap1.xml.gz' => 'sitemap',
                            'public/sitemap2.xml.gz' => 'sitemap')
        expect_index_url_pinged
      end

      it 'creates index if more than one group' do
        ls.create do
          group(filename: :group1) { add('/one') }
          group(filename: :group2) { add('/two') }
        end
        expect(ls.sitemap_index.link_count).to eq(2) # two sitemaps
        expect_files(exist: %w[public/sitemap.xml.gz public/group1.xml.gz public/group2.xml.gz])
        expect_schema_valid('public/sitemap.xml.gz' => 'siteindex', 'public/group1.xml.gz' => 'sitemap',
                            'public/group2.xml.gz' => 'sitemap')
        expect_index_url_pinged
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end

  describe 'compress' do
    let(:ls) do
      SitemapGenerator::LinkSet.new(
        default_host: 'http://test.local',
        include_root: false,
        compress: compress,
        max_sitemap_links: 1
      )
    end

    before do
      clean_sitemap_files_from_rails_app
    end

    describe 'when false' do
      let(:compress) { false }

      # rubocop:disable RSpec/ExampleLength -- 2 top-level adds plus a group are the scenario under test
      it 'does not compress files' do
        ls.create do
          add('/one')
          add('/two')
          group(filename: :group) do
            add('/group1')
            add('/group2')
          end
        end
        expect_files(exist: %w[public/sitemap.xml public/sitemap1.xml public/group.xml public/group1.xml])
      end
      # rubocop:enable RSpec/ExampleLength
    end

    context 'when compress is :all_but_first' do
      let(:compress) { :all_but_first }

      # rubocop:disable RSpec/ExampleLength -- the 3 groups with differing compress settings are the scenario
      it 'does not compress first file' do
        ls.create do
          add('/one')
          add('/two')
          add('/three')
          group(filename: :group) do
            add('/group1')
            add('/group2')
          end
          group(filename: :group2, compress: true) do
            add('/group1')
            add('/group2')
          end
          group(filename: :group2, compress: false) do
            add('/group1')
            add('/group2')
          end
        end
        expect_files(exist: %w[
                       public/sitemap.xml public/sitemap1.xml.gz public/sitemap2.xml.gz
                       public/group.xml public/group1.xml.gz public/group2.xml.gz public/group21.xml.gz
                     ])
      end
      # rubocop:enable RSpec/ExampleLength
    end

    describe 'in groups' do
      let(:compress) { nil }

      # rubocop:disable RSpec/ExampleLength -- the 3 groups with differing compress settings are the scenario
      it 'respects passed in compress option' do
        ls.create do
          group(filename: :group1, compress: :all_but_first) do
            add('/group1')
            add('/group2')
          end
          group(filename: :group2, compress: true) do
            add('/group1')
            add('/group2')
          end
          group(filename: :group3, compress: false) do
            add('/group1')
            add('/group2')
          end
        end
        expect_files(exist: %w[
                       public/group1.xml public/group11.xml.gz public/group2.xml.gz
                       public/group21.xml.gz public/group3.xml public/group31.xml
                     ])
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end

  describe 'respond_to?' do
    it 'correctly identifies the methods that it responds to' do
      methods = %i[create adapter default_host invalid_func]
      expect(methods.map { |m| SitemapGenerator::Sitemap.respond_to?(m) }).to eq([true, true, true, false])
    end
  end
end
