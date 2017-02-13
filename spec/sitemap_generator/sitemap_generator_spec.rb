require 'spec_helper'
require 'cgi'

class Holder
  class << self
    attr_accessor :executed
  end
end

def with_max_links(num)
  original = SitemapGenerator::Sitemap.max_sitemap_links
  SitemapGenerator::Sitemap.max_sitemap_links = num

  begin
    yield
  ensure
    SitemapGenerator::Sitemap.max_sitemap_links = original
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

  describe "generate sitemap with normal config" do
    before :all do
      SitemapGenerator::Sitemap.reset!
      clean_sitemap_files_from_rails_app
      copy_sitemap_file_to_rails_app(:create)
      with_max_links(10) { execute_sitemap_config }
    end

    it "should create sitemaps" do
      file_should_exist(rails_path('public/sitemap.xml.gz'))
      file_should_exist(rails_path('public/sitemap1.xml.gz'))
      file_should_exist(rails_path('public/sitemap2.xml.gz'))
      file_should_not_exist(rails_path('public/sitemap3.xml.gz'))
    end

    it "should have 13 links" do
      SitemapGenerator::Sitemap.link_count.should == 13
    end

    it "index XML should validate" do
      gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'siteindex'
    end

    it "sitemap XML should validate" do
      gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap1.xml.gz'), 'sitemap'
      gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap2.xml.gz'), 'sitemap'
    end

    it "index XML should not have excess whitespace" do
      gzipped_xml_file_should_have_minimal_whitespace rails_path('public/sitemap.xml.gz')
    end

    it "sitemap XML should not have excess whitespace" do
      gzipped_xml_file_should_have_minimal_whitespace rails_path('public/sitemap1.xml.gz')
    end
  end

  describe "sitemap with groups" do
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
        public/fr/new_sitemaps4.xml.gz]
      @sitemaps = (@expected - %w[public/fr/new_sitemaps.xml.gz])
    end

    it "should create sitemaps" do
      @expected.each { |file| file_should_exist(rails_path(file)) }
      file_should_not_exist(rails_path('public/fr/new_sitemaps5.xml.gz'))
      file_should_not_exist(rails_path('public/en/xxx1.xml.gz'))
      file_should_not_exist(rails_path('public/fr/abc5.xml.gz'))
    end

    it "should have 16 links" do
      SitemapGenerator::Sitemap.link_count.should == 16
    end

    it "index XML should validate" do
      gzipped_xml_file_should_validate_against_schema rails_path('public/fr/new_sitemaps.xml.gz'), 'siteindex'
    end

    it "index XML should not have excess whitespace" do
      gzipped_xml_file_should_have_minimal_whitespace rails_path('public/fr/new_sitemaps.xml.gz')
    end

    it "sitemaps XML should validate" do
      @sitemaps.each { |file| gzipped_xml_file_should_validate_against_schema(rails_path(file), 'sitemap') }
    end

    it "sitemap XML should not have excess whitespace" do
      @sitemaps.each { |file| gzipped_xml_file_should_have_minimal_whitespace(rails_path(file)) }
    end
  end

  describe "should handle links added manually" do
    before :each do
      clean_sitemap_files_from_rails_app
      ::SitemapGenerator::Sitemap.reset!
      ::SitemapGenerator::Sitemap.default_host = "http://www.example.com"
      ::SitemapGenerator::Sitemap.namer = ::SitemapGenerator::SimpleNamer.new(:sitemap, :start => 4)
      ::SitemapGenerator::Sitemap.create do
        3.times do |i|
          add_to_index "sitemap#{i}.xml.gz"
        end
        add '/home'
      end
    end

    it "should create the index and start the sitemap numbering from 4" do
      file_should_exist(rails_path('public/sitemap.xml.gz'))
      file_should_exist(rails_path('public/sitemap4.xml.gz'))
      gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'siteindex'
      gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap4.xml.gz'), 'sitemap'
    end
  end

  describe "should handle links added manually" do
    before :each do
      clean_sitemap_files_from_rails_app
      ::SitemapGenerator::Sitemap.reset!
      ::SitemapGenerator::Sitemap.default_host = "http://www.example.com"
      ::SitemapGenerator::Sitemap.include_root = false
    end

    it "should create the index" do
      with_max_links(1) {
        ::SitemapGenerator::Sitemap.create do
          add_to_index "customsitemap.xml.gz"
          add '/one'
          add '/two'
        end
      }
      file_should_exist(rails_path('public/sitemap.xml.gz'))
      file_should_exist(rails_path('public/sitemap1.xml.gz'))
      file_should_exist(rails_path('public/sitemap2.xml.gz'))
      file_should_not_exist(rails_path('public/sitemap3.xml.gz'))
      gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'siteindex'
    end

    it "should create the index" do
      with_max_links(1) {
        ::SitemapGenerator::Sitemap.create do
          add '/one'
          add_to_index "customsitemap.xml.gz"
          add '/two'
        end
      }
      file_should_exist(rails_path('public/sitemap.xml.gz'))
      file_should_exist(rails_path('public/sitemap1.xml.gz'))
      file_should_exist(rails_path('public/sitemap2.xml.gz'))
      file_should_not_exist(rails_path('public/sitemap3.xml.gz'))
      gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'siteindex'
    end

    it "should create an index when only manually added links" do
      with_max_links(1) {
        ::SitemapGenerator::Sitemap.create(:create_index => :auto) do
          add_to_index "customsitemap1.xml.gz"
        end
      }
      file_should_exist(rails_path('public/sitemap.xml.gz'))
      file_should_not_exist(rails_path('public/sitemap1.xml.gz'))
      gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'siteindex'
    end

    it "should create an index when only manually added links" do
      with_max_links(1) {
        ::SitemapGenerator::Sitemap.create(:create_index => :auto) do
          add_to_index "customsitemap1.xml.gz"
          add_to_index "customsitemap2.xml.gz"
          add_to_index "customsitemap3.xml.gz"
        end
      }
      file_should_exist(rails_path('public/sitemap.xml.gz'))
      file_should_not_exist(rails_path('public/sitemap1.xml.gz'))
      gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'siteindex'
    end

    it "should not create an index" do
      # Create index is explicity turned off and no links added to sitemap,
      # respect the setting and don't create the index.  There is no sitemap file either.
      ::SitemapGenerator::Sitemap.create(:create_index => false) do
        add_to_index "customsitemap1.xml.gz"
        add_to_index "customsitemap2.xml.gz"
        add_to_index "customsitemap3.xml.gz"
      end
      file_should_not_exist(rails_path('public/sitemap.xml.gz'))
      file_should_not_exist(rails_path('public/sitemap1.xml.gz'))
    end

    it "should not create an index" do
      ::SitemapGenerator::Sitemap.create(:create_index => false) do
        add '/one'
      end
      file_should_exist(rails_path('public/sitemap.xml.gz')) # the sitemap, not an index
      file_should_not_exist(rails_path('public/sitemap1.xml.gz'))
      gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'sitemap'
    end
  end

  describe "sitemap path" do
    before :each do
      clean_sitemap_files_from_rails_app
      ::SitemapGenerator::Sitemap.reset!
      ::SitemapGenerator::Sitemap.default_host = 'http://test.local'
      ::SitemapGenerator::Sitemap.filename = 'sitemap'
      ::SitemapGenerator::Sitemap.create_index = true
    end

    it "should allow changing of the filename" do
      ::SitemapGenerator::Sitemap.create(:filename => :geo_sitemap) do
        add '/goerss', :geo => { :format => 'georss' }
        add '/kml', :geo => { :format => 'kml' }
      end
      file_should_exist(rails_path('public/geo_sitemap.xml.gz'))
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

      file_should_exist(rails_path('public/sitemaps/sitemap.xml.gz'))
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

      file_should_exist(rails_path('public/sitemaps/deep/directory/sitemap.xml.gz'))
      file_should_exist(rails_path('public/sitemaps/deep/directory/sitemap1.xml.gz'))
    end
  end

  describe "external dependencies" do
    it "should work outside of Rails" do
      Object.stubs(:Rails => nil)
      lambda { ::SitemapGenerator::LinkSet.new }.should_not raise_exception
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
      let(:ls) {
        SitemapGenerator::LinkSet.new(
          :include_root => false,
          :default_host => 'http://example.com',
          :create_index => true)
      }

      it "should always create index" do
        with_max_links(1) do
          ls.create { add('/one') }
        end
        ls.sitemap_index.link_count.should == 1 # one sitemap
        file_should_exist(rails_path('public/sitemap.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap2.xml.gz'))
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'siteindex'
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap1.xml.gz'), 'sitemap'

        # Test that the index url is reported correctly
        ls.search_engines = { :google => 'http://google.com/?url=%s' }
        ls.expects(:open).with("http://google.com/?url=#{CGI.escape('http://example.com/sitemap.xml.gz')}")
        ls.ping_search_engines
      end

      it "should always create index" do
        with_max_links(1) do
          ls.create { add('/one'); add('/two') }
        end
        ls.sitemap_index.link_count.should == 2 # two sitemaps
        file_should_exist(rails_path('public/sitemap.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_exist(rails_path('public/sitemap2.xml.gz'))
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'siteindex'
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap1.xml.gz'), 'sitemap'
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap2.xml.gz'), 'sitemap'

        # Test that the index url is reported correctly
        ls.search_engines = { :google => 'http://google.com/?url=%s' }
        ls.expects(:open).with("http://google.com/?url=#{CGI.escape('http://example.com/sitemap.xml.gz')}")
        ls.ping_search_engines
      end
    end

    # Technically when there's no index, the first sitemap is the "index"
    # regardless of how many sitemaps were created, or if create_index is false.
    describe "when false" do
      let(:ls) { SitemapGenerator::LinkSet.new(:include_root => false, :default_host => 'http://example.com', :create_index => false) }

      it "should never create index" do
        with_max_links(1) do
          ls.create { add('/one') }
        end
        ls.sitemap_index.link_count.should == 1 # one sitemap
        file_should_exist(rails_path('public/sitemap.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap1.xml.gz'))
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'sitemap'

        # Test that the index url is reported correctly
        ls.search_engines = { :google => 'http://google.com/?url=%s' }
        ls.expects(:open).with("http://google.com/?url=#{CGI.escape('http://example.com/sitemap.xml.gz')}")
        ls.ping_search_engines
      end

      it "should never create index" do
        with_max_links(1) do
          ls.create { add('/one'); add('/two') }
        end
        ls.sitemap_index.link_count.should == 2 # two sitemaps
        file_should_exist(rails_path('public/sitemap.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap2.xml.gz'))
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'sitemap'
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap1.xml.gz'), 'sitemap'

        # Test that the index url is reported correctly
        ls.search_engines = { :google => 'http://google.com/?url=%s' }
        ls.expects(:open).with("http://google.com/?url=#{CGI.escape('http://example.com/sitemap.xml.gz')}")
        ls.ping_search_engines
      end
    end

    describe "when :auto" do
      let(:ls) { SitemapGenerator::LinkSet.new(:include_root => false, :default_host => 'http://example.com', :create_index => :auto) }

      it "should not create index if only one sitemap file" do
        with_max_links(1) do
          ls.create { add('/one') }
        end
        ls.sitemap_index.link_count.should == 1 # one sitemap
        file_should_exist(rails_path('public/sitemap.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap1.xml.gz'))
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'sitemap'

        # Test that the index url is reported correctly
        ls.search_engines = { :google => 'http://google.com/?url=%s' }
        ls.expects(:open).with("http://google.com/?url=#{CGI.escape('http://example.com/sitemap.xml.gz')}")
        ls.ping_search_engines
      end

      it "should create index if more than one sitemap file" do
        with_max_links(1) do
          ls.create { add('/one'); add('/two') }
        end
        ls.sitemap_index.link_count.should == 2 # two sitemaps
        file_should_exist(rails_path('public/sitemap.xml.gz'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_exist(rails_path('public/sitemap2.xml.gz'))
        file_should_not_exist(rails_path('public/sitemap3.xml.gz'))
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'siteindex'
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap1.xml.gz'), 'sitemap'
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap2.xml.gz'), 'sitemap'

        # Test that the index url is reported correctly
        ls.search_engines = { :google => 'http://google.com/?url=%s' }
        ls.expects(:open).with("http://google.com/?url=#{CGI.escape('http://example.com/sitemap.xml.gz')}")
        ls.ping_search_engines
      end

      it "should create index if more than one group" do
        with_max_links(1) do
          ls.create do
            group(:filename => :group1) { add('/one') };
            group(:filename => :group2) { add('/two') };
          end
        end
        ls.sitemap_index.link_count.should == 2 # two sitemaps
        file_should_exist(rails_path('public/sitemap.xml.gz'))
        file_should_exist(rails_path('public/group1.xml.gz'))
        file_should_exist(rails_path('public/group2.xml.gz'))
        gzipped_xml_file_should_validate_against_schema rails_path('public/sitemap.xml.gz'), 'siteindex'
        gzipped_xml_file_should_validate_against_schema rails_path('public/group1.xml.gz'), 'sitemap'
        gzipped_xml_file_should_validate_against_schema rails_path('public/group2.xml.gz'), 'sitemap'

        # Test that the index url is reported correctly
        ls.search_engines = { :google => 'http://google.com/?url=%s' }
        ls.expects(:open).with("http://google.com/?url=#{CGI.escape('http://example.com/sitemap.xml.gz')}")
        ls.ping_search_engines
      end
    end
  end

  describe "compress" do
    let(:ls) { SitemapGenerator::LinkSet.new(:default_host => 'http://test.local', :include_root => false) }

    before :each do
      clean_sitemap_files_from_rails_app
    end

    describe "when false" do
      before :each do
        ls.compress = false
      end

      it "should not compress files" do
        with_max_links(1) do
          ls.create do
            add('/one')
            add('/two')
            group(:filename => :group) {
              add('/group1')
              add('/group2')
            }
          end
        end
        file_should_exist(rails_path('public/sitemap.xml'))
        file_should_exist(rails_path('public/sitemap1.xml'))
        file_should_exist(rails_path('public/group.xml'))
        file_should_exist(rails_path('public/group1.xml'))
      end
    end

    describe "when :all_but_first" do
      before :each do
        ls.compress = :all_but_first
      end

      it "should not compress first file" do
        with_max_links(1) do
          ls.create do
            add('/one')
            add('/two')
            add('/three')
            group(:filename => :group) {
              add('/group1')
              add('/group2')
            }
            group(:filename => :group2, :compress => true) {
              add('/group1')
              add('/group2')
            }
            group(:filename => :group2, :compress => false) {
              add('/group1')
              add('/group2')
            }
          end
        end
        file_should_exist(rails_path('public/sitemap.xml'))
        file_should_exist(rails_path('public/sitemap1.xml.gz'))
        file_should_exist(rails_path('public/sitemap2.xml.gz'))
        file_should_exist(rails_path('public/group.xml'))
        file_should_exist(rails_path('public/group1.xml.gz'))
        file_should_exist(rails_path('public/group2.xml.gz'))
        file_should_exist(rails_path('public/group21.xml.gz'))
      end
    end

    describe "in groups" do
      it "should respect passed in compress option" do
        with_max_links(1) do
          ls.create do
            group(:filename => :group1, :compress => :all_but_first) {
              add('/group1')
              add('/group2')
            }
            group(:filename => :group2, :compress => true) {
              add('/group1')
              add('/group2')
            }
            group(:filename => :group3, :compress => false) {
              add('/group1')
              add('/group2')
            }
          end
        end
        file_should_exist(rails_path('public/group1.xml'))
        file_should_exist(rails_path('public/group11.xml.gz'))
        file_should_exist(rails_path('public/group2.xml.gz'))
        file_should_exist(rails_path('public/group21.xml.gz'))
        file_should_exist(rails_path('public/group3.xml'))
        file_should_exist(rails_path('public/group31.xml'))
      end
    end
  end

  describe "respond_to?" do
    it "should correctly identify the methods that it responds to" do
      SitemapGenerator::Sitemap.respond_to?(:create).should be_true
      SitemapGenerator::Sitemap.respond_to?(:adapter).should be_true
      SitemapGenerator::Sitemap.respond_to?(:default_host).should be_true
      SitemapGenerator::Sitemap.respond_to?(:invalid_func).should be_false
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
