# frozen_string_literal: true

require 'spec_helper'

class Holder
  class << self
    attr_accessor :executed
  end
end

RSpec.describe 'SitemapGenerator' do
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

  describe 'app root' do
    it 'is set to the Rails root' do
      expect(SitemapGenerator.app.root.to_s).to eq(Rails.root.to_s)
    end
  end

  describe 'clean task' do
    before do
      SitemapGenerator::Sitemap.reset!
      FileUtils.mkdir_p(rails_path('public/'))
      FileUtils.touch(rails_path('public/sitemap.xml.gz'))
    end

    it 'deletes the sitemaps' do
      expect_file_to_exist(rails_path('public/sitemap.xml.gz'))
      Helpers.invoke_task('sitemap:clean')
      expect_file_not_to_exist(rails_path('public/sitemap.xml.gz'))
    end
  end

  describe 'fresh install' do
    before do
      delete_sitemap_file_from_rails_app
      Helpers.invoke_task('sitemap:install')
    end

    it 'creates config/sitemap.rb' do
      expect_file_to_exist(rails_path('config/sitemap.rb'))
    end

    it 'creates config/sitemap.rb matching template' do
      sitemap_template = SitemapGenerator.templates.template_path(:sitemap_sample)
      expect_files_to_be_identical(rails_path('config/sitemap.rb'), sitemap_template)
    end
  end

  describe 'install multiple times' do
    before do
      copy_sitemap_file_to_rails_app(:create)
      Helpers.invoke_task('sitemap:install')
    end

    it 'does not overwrite config/sitemap.rb' do
      sitemap_file = File.join(this_root, 'spec/files/sitemap.create.rb')
      expect_files_to_be_identical(sitemap_file, rails_path('config/sitemap.rb'))
    end
  end

  describe 'generate sitemap with normal config' do
    before :all do
      SitemapGenerator::Sitemap.reset!
      clean_sitemap_files_from_rails_app
      copy_sitemap_file_to_rails_app(:create)
      with_max_links(10) { execute_sitemap_config }
    end

    it 'creates sitemaps' do
      expect_file_to_exist(rails_path('public/sitemap.xml.gz'))
      expect_file_to_exist(rails_path('public/sitemap1.xml.gz'))
      expect_file_to_exist(rails_path('public/sitemap2.xml.gz'))
      expect_file_not_to_exist(rails_path('public/sitemap3.xml.gz'))
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
        public/fr/def1.xml.gz
        public/fr/new_sitemaps.xml.gz
        public/fr/new_sitemaps1.xml.gz
        public/fr/new_sitemaps2.xml.gz
        public/fr/new_sitemaps3.xml.gz
        public/fr/new_sitemaps4.xml.gz
      ]
      @sitemaps = (@expected - %w[public/fr/new_sitemaps.xml.gz])
    end

    it 'creates sitemaps' do
      @expected.each { |file| expect_file_to_exist(rails_path(file)) }
      unexpected_grouped_sitemap_files.each { |file| expect_file_not_to_exist(rails_path(file)) }
    end

    def unexpected_grouped_sitemap_files
      %w[
        public/fr/new_sitemaps5.xml.gz
        public/en/xxx1.xml.gz
        public/fr/abc2.xml.gz
        public/fr/abc5.xml.gz
        public/fr/def2.xml.gz
      ]
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

  describe 'sitemap path' do
    before do
      clean_sitemap_files_from_rails_app
      SitemapGenerator::Sitemap.reset!
      SitemapGenerator::Sitemap.default_host = 'http://test.local'
      SitemapGenerator::Sitemap.filename = 'sitemap'
    end

    it 'allows changing of the filename' do
      SitemapGenerator::Sitemap.create(filename: :geo_sitemap) do
        add '/goerss'
        add '/kml'
      end
      expect_file_created_but_not(rails_path('public/geo_sitemap.xml.gz'), rails_path('public/geo_sitemap1.xml.gz'))
    end

    it 'supports setting a sitemap path' do
      expect_directory_not_to_exist(rails_path('public/sitemaps/'))
      SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'
      create_sitemap_with_links('/', '/another')
      expect_file_created_but_not(rails_path('public/sitemaps/sitemap.xml.gz'),
                                  rails_path('public/sitemaps/sitemap1.xml.gz'))
    end

    it 'supports setting a deeply nested sitemap path' do
      expect_directory_not_to_exist(rails_path('public/sitemaps/deep/directory'))
      SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/deep/directory/'
      create_sitemap_with_links('/', '/another', '/yet-another')
      expect_file_created_but_not(rails_path('public/sitemaps/deep/directory/sitemap.xml.gz'),
                                  rails_path('public/sitemaps/deep/directory/sitemap1.xml.gz'))
    end

    def create_sitemap_with_links(*paths)
      SitemapGenerator::Sitemap.create { paths.each { |path| add(path) } }
    end

    def expect_file_created_but_not(created_path, not_created_path)
      expect_file_to_exist(created_path)
      expect_file_not_to_exist(not_created_path)
    end
  end

  describe 'default_url_options' do
    before do
      clean_sitemap_files_from_rails_app
      SitemapGenerator::Sitemap.reset!
      @original_default_url_options = ActionController::Base.default_url_options.dup
      ActionController::Base.default_url_options = { trailing_slash: true }
    end

    after do
      ActionController::Base.default_url_options = @original_default_url_options
    end

    it 'is applied when generating links via url helpers' do
      SitemapGenerator::Sitemap.create(default_host: 'http://test.local') { add contents_path }
      expect(gzipped_file_contents('public/sitemap.xml.gz')).to include('/contents/')
    end

    def gzipped_file_contents(path)
      Zlib::GzipReader.open(rails_path(path), &:read)
    end
  end

  describe 'external dependencies' do
    describe 'rails' do
      before { hide_const('Rails') }

      it 'works outside of Rails', :aggregate_failures do
        expect(defined?(Rails)).to be_nil
        expect { SitemapGenerator::LinkSet.new }.not_to raise_exception
      end
    end
  end

  protected

  # Better would be to just invoke the environment task and use
  # the interpreter.
  def execute_sitemap_config
    if Holder.executed
      SitemapGenerator::Interpreter.run
    else
      Holder.executed = true
      Helpers.invoke_task('sitemap:refresh:no_ping')
    end
  end
end
