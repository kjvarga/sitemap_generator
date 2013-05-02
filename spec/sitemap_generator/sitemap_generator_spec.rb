require 'spec_helper'

class Holder
  class << self
    attr_accessor :executed
  end
end

def with_max_links(num)
  original = SitemapGenerator::MAX_SITEMAP_LINKS
  SitemapGenerator::Utilities.with_warnings(nil) do
    SitemapGenerator.const_set(:MAX_SITEMAP_LINKS, num)
  end
  yield
  SitemapGenerator::Utilities.with_warnings(nil) do
    SitemapGenerator.const_set(:MAX_SITEMAP_LINKS, original)
  end
end

describe "SitemapGenerator" do

  describe "reset!" do
    before :each do
      SitemapGenerator::Sitemap.default_host # Force initialization of the LinkSet
    end

    it "should set a new LinkSet instance" do
      first = SitemapGenerator::Sitemap.instance_variable_get(:@link_set)
      first.should be_a(SitemapGenerator::LinkSet)
      SitemapGenerator::Sitemap.reset!
      second = SitemapGenerator::Sitemap.instance_variable_get(:@link_set)
      second.should be_a(SitemapGenerator::LinkSet)
      first.should_not be(second)
    end
  end

  describe "root" do
    it "should be set to the root of the gem" do
      SitemapGenerator.root.should == File.expand_path('../../../' , __FILE__)
    end
  end

  [:deprecated, :create].each do |extension|
    describe "generate sitemap" do
      before :all do
        SitemapGenerator::Sitemap.reset!
        clean_sitemap_files_from_rails_app
        copy_sitemap_file_to_rails_app(extension)
        with_max_links(10) { execute_sitemap_config }
      end

      it "should create sitemaps" do
        file_should_exist(rails_path('public/sitemap_index.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_exist(rails_path('public/sitemap2.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap3.xml.gz'))
      end

      it "should have 13 links" do
        SitemapGenerator::Sitemap.link_count.should == 13
      end

      it "index XML should validate" do
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap_index.xml.gz'), 'siteindex'
      end

      it "sitemap XML should validate" do
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap1.xml.gz'), 'sitemap'
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap2.xml.gz'), 'sitemap'
      end

      it "index XML should not have excess whitespace" do
        gzipped_xml_file_should_have_minimal_whitespace rails_path('public/sitemap_index.xml.gz')
      end

      it "sitemap XML should not have excess whitespace" do
        gzipped_xml_file_should_have_minimal_whitespace rails_path('public/sitemap1.xml.gz')
      end
    end
  end

  describe "sitemap with groups" do
    before :all do
      SitemapGenerator::Sitemap.reset!
      clean_sitemap_files_from_rails_app
      copy_sitemap_file_to_rails_app(:groups)
      with_max_links(2) { execute_sitemap_config }
      @expected = %w[
        public/en/xxx1.xml.gz
        public/fr/abc3.xml.gz
        public/fr/abc4.xml.gz
        public/fr/new_sitemaps_index.xml.gz
        public/fr/new_sitemaps1.xml.gz
        public/fr/new_sitemaps2.xml.gz
        public/fr/new_sitemaps3.xml.gz
        public/fr/new_sitemaps4.xml.gz]
      @sitemaps = (@expected - %w[public/fr/new_sitemaps_index.xml.gz])
    end

    it "should create sitemaps" do
      @expected.each { |file| file_should_exist(rails_path(file)) }
      file_should_not_exist(rails_path('public/fr/new_sitemaps5.xml.gz'))
      file_should_not_exist(rails_path('public/en/xxx2.xml.gz'))
      file_should_not_exist(rails_path('public/fr/abc5.xml.gz'))
    end

    it "should have 13 links" do
      SitemapGenerator::Sitemap.link_count.should == 13
    end

    it "index XML should validate" do
      gzipped_xml_file_should_validate_against_schema rails_path('public/fr/new_sitemaps_index.xml.gz'), 'siteindex'
    end

    it "index XML should not have excess whitespace" do
      gzipped_xml_file_should_have_minimal_whitespace rails_path('public/fr/new_sitemaps_index.xml.gz')
    end

    it "sitemaps XML should validate" do
      @sitemaps.each { |file| gzipped_xml_file_should_validate_against_schema(rails_path(file), 'sitemap') }
    end

    it "sitemap XML should not have excess whitespace" do
      @sitemaps.each { |file| gzipped_xml_file_should_have_minimal_whitespace(rails_path(file)) }
    end
  end

  describe "sitemap path" do
    before :each do
      clean_sitemap_files_from_rails_app
      ::SitemapGenerator::Sitemap.reset!
      ::SitemapGenerator::Sitemap.default_host = 'http://test.local'
      ::SitemapGenerator::Sitemap.filename = 'sitemap'
    end

    it "should allow changing of the filename" do
      ::SitemapGenerator::Sitemap.create(:filename => :geo_sitemap) do
        add '/goerss', :geo => { :format => 'georss' }
        add '/kml', :geo => { :format => 'kml' }
      end
      file_should_exist(rails_path('public/geo_sitemap_index.xml.gz'))
      file_should_exist(rails_path('public/geo_sitemap1.xml.gz'))
    end

    it "should support setting a sitemap path" do
      directory_should_not_exist(rails_path('public/sitemaps/'))

      sm = ::SitemapGenerator::Sitemap
      sm.sitemaps_path = 'sitemaps/'
      sm.create do
        add '/'
        add '/another'
      end

      file_should_exist(rails_path('public/sitemaps/sitemap_index.xml.gz'))
      file_should_exist(rails_path('public/sitemaps/sitemap1.xml.gz'))
    end

    it "should support setting a deeply nested sitemap path" do
      directory_should_not_exist(rails_path('public/sitemaps/deep/directory'))

      sm = ::SitemapGenerator::Sitemap
      sm.sitemaps_path = 'sitemaps/deep/directory/'
      sm.create do
        add '/'
        add '/another'
        add '/yet-another'
      end

      file_should_exist(rails_path('public/sitemaps/deep/directory/sitemap_index.xml.gz'))
      file_should_exist(rails_path('public/sitemaps/deep/directory/sitemap1.xml.gz'))
    end
  end

  describe "external dependencies" do
    it "should work outside of Rails" do
      Object.stubs(:Rails => nil)
      lambda { ::SitemapGenerator::LinkSet.new }.should_not raise_exception
    end
  end

  describe "exclude" do
    before(:each) { ENV['EXCLUDE'] = SitemapGenerator.exclude = nil }
    after(:all)   { ENV['EXCLUDE'] = SitemapGenerator.exclude = nil }

    it "should be set via ENV['EXCLUDE']" do
      ENV['EXCLUDE'] = 'group_name'
      SitemapGenerator.exclude.should == [/group_name/]
    end

    it "should set SitemapGenerator.exclude to an empty array if given not set" do
      SitemapGenerator.exclude.should == []
    end

    it "should split on ',' and convert elements to Regex when given a String" do
      ENV['EXCLUDE'] = 'exclude_group_name1,exclude_group_name2'
      SitemapGenerator.exclude.should == [/exclude_group_name1/,/exclude_group_name2/]
    end
  end

  describe "only" do
    before(:each) { ENV['ONLY'] = SitemapGenerator.only = nil }
    after(:all)   { ENV['ONLY'] = SitemapGenerator.only = nil }

    it "should be set via ENV['ONLY']" do
      ENV['ONLY'] = 'group_name'
      SitemapGenerator.only.should == [/group_name/]
    end

    it "should set SitemapGenerator.only to an empty array if given not set" do
      SitemapGenerator.only.should == []
    end

    it "should split on ',' and convert elements to Regex when given a String" do
      ENV['ONLY'] = 'only_group_name1,only_group_name2'
      SitemapGenerator.only.should == [/only_group_name1/,/only_group_name2/]
    end
  end

  describe "verbose" do
    it "should be set via ENV['VERBOSE']" do
      original = SitemapGenerator.verbose
      SitemapGenerator.verbose = nil
      ENV['VERBOSE'] = 'true'
      SitemapGenerator.verbose.should be_true
      SitemapGenerator.verbose = nil
      ENV['VERBOSE'] = 'false'
      SitemapGenerator.verbose.should be_false
      SitemapGenerator.verbose = original
    end
  end

  describe "yield_sitemap" do
    it "should set the yield_sitemap flag" do
      SitemapGenerator.yield_sitemap = false
      SitemapGenerator.yield_sitemap?.should be_false
      SitemapGenerator.yield_sitemap = true
      SitemapGenerator.yield_sitemap?.should be_true
      SitemapGenerator.yield_sitemap = false
    end
  end

  describe "create_index" do

    before :each do
      clean_sitemap_files_from_rails_app
    end

    describe "when true" do
      let(:ls) { SitemapGenerator::LinkSet.new(:include_root => false, :default_host => 'http://example.com', :create_index => true) }

      it "should always create index" do
        ls.create { }
        file_should_exist(rails_path('public/sitemap_index.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap2.xml.gz'))
      end

      it "should always create index" do
        with_max_links(1) do
          ls.create { add('/one') }
        end
        file_should_exist(rails_path('public/sitemap_index.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap2.xml.gz'))
      end

      it "should always create index" do
        with_max_links(1) do
          ls.create { add('/one'); add('/two') }
        end
        file_should_exist(rails_path('public/sitemap_index.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_exist(rails_path('public/sitemap2.xml.gz'))
      end
    end

    describe "when false" do
      let(:ls) { SitemapGenerator::LinkSet.new(:include_root => false, :default_host => 'http://example.com', :create_index => false) }

      it "should never create index" do
        ls.create { }
        file_should_not_exist(rails_path('public/sitemap_index.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap2.xml.gz'))
      end

      it "should never create index" do
        with_max_links(1) do
          ls.create { add('/one') }
        end
        file_should_not_exist(rails_path('public/sitemap_index.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap2.xml.gz'))
      end

      it "should never create index" do
        with_max_links(1) do
          ls.create { add('/one'); add('/two') }
        end
        file_should_not_exist(rails_path('public/sitemap_index.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_exist(rails_path('public/sitemap2.xml.gz'))
      end
    end

    describe "when :auto" do
      let(:ls) { SitemapGenerator::LinkSet.new(:include_root => false, :default_host => 'http://example.com', :create_index => :auto) }

      it "should not create index if one sitemap file" do
        ls.create { }
        file_should_not_exist(rails_path('public/sitemap_index.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap2.xml.gz'))
      end

      it "should not create index if one sitemap file" do
        with_max_links(1) do
          ls.create { add('/one') }
        end
        file_should_not_exist(rails_path('public/sitemap_index.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap2.xml.gz'))
      end

      it "should create index if more than one sitemap file" do
        with_max_links(1) do
          ls.create { add('/one'); add('/two') }
        end
        file_should_exist(rails_path('public/sitemap_index.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_exist(rails_path('public/sitemap2.xml.gz'))
      end
    end
  end

  protected

  #
  # Helpers
  #

  def rails_path(file)
    SitemapGenerator.app.root + file
  end

  def copy_sitemap_file_to_rails_app(extension)
    FileUtils.cp(File.join(SitemapGenerator.root, "spec/files/sitemap.#{extension}.rb"), SitemapGenerator.app.root + 'config/sitemap.rb')
  end

  def delete_sitemap_file_from_rails_app
    FileUtils.remove(SitemapGenerator.app.root + 'config/sitemap.rb')
  rescue
    nil
  end

  def clean_sitemap_files_from_rails_app
    FileUtils.rm_rf(rails_path('public/'))
    FileUtils.mkdir_p(rails_path('public/'))
  end

  # Better would be to just invoke the environment task and use
  # the interpreter.
  def execute_sitemap_config(opts={})
   SitemapGenerator::Interpreter.run(opts)
  end
end
