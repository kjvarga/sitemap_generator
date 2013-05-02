require 'spec_helper'

describe SitemapGenerator::LinkSet do
  let(:default_host) { 'http://example.com' }
  let(:ls)           { SitemapGenerator::LinkSet.new(:default_host => default_host) }

  describe "initializer options" do
    options = [:public_path, :sitemaps_path, :default_host, :filename, :search_engines]
    values = [File.expand_path(SitemapGenerator.app.root + 'tmp/'), 'mobile/', 'http://myhost.com', :xxx, { :abc => '123' }]

    options.zip(values).each do |option, value|
      it "should set #{option} to #{value}" do
        ls = SitemapGenerator::LinkSet.new(option => value)
        ls.send(option).should == value
      end
    end
  end

  describe "default options" do
    let(:ls) { SitemapGenerator::LinkSet.new }

    default_options = {
      :filename      => :sitemap,
      :sitemaps_path => nil,
      :public_path   => SitemapGenerator.app.root + 'public/',
      :default_host  => nil,
      :include_index => false,
      :include_root  => true,
      :create_index  => true
    }

    default_options.each do |option, value|
      it "#{option} should default to #{value}" do
        ls.send(option).should == value
      end
    end
  end

  describe "include_root include_index option" do
    it "should include the root url and the sitemap index url" do
      ls = SitemapGenerator::LinkSet.new(:default_host => default_host, :include_root => true, :include_index => true)
      ls.include_root.should be_true
      ls.include_index.should be_true
      ls.add_links { |sitemap| }
      ls.sitemap.link_count.should == 2
    end

    it "should not include the root url" do
      ls = SitemapGenerator::LinkSet.new(:default_host => default_host, :include_root => false)
      ls.include_root.should be_false
      ls.include_index.should be_false
      ls.add_links { |sitemap| }
      ls.sitemap.link_count.should == 0
    end

    it "should not include the sitemap index url" do
      ls = SitemapGenerator::LinkSet.new(:default_host => default_host, :include_index => false)
      ls.include_root.should be_true
      ls.include_index.should be_false
      ls.add_links { |sitemap| }
      ls.sitemap.link_count.should == 1
    end

    it "should not include the root url or the sitemap index url" do
      ls = SitemapGenerator::LinkSet.new(:default_host => default_host, :include_root => false, :include_index => false)
      ls.include_root.should be_false
      ls.include_index.should be_false
      ls.add_links { |sitemap| }
      ls.sitemap.link_count.should == 0
    end
  end

  describe "sitemaps public_path" do
    it "should default to public/" do
      ls.public_path.should ==  SitemapGenerator.app.root + 'public/'
      ls.sitemap.location.public_path.should == ls.public_path
      ls.sitemap_index.location.public_path.should == ls.public_path
    end

    it "should change when the public_path is changed" do
      ls.public_path = 'tmp'
      ls.sitemap.location.public_path.should == ls.public_path
      ls.sitemap_index.location.public_path.should == ls.public_path
    end
  end

  describe "sitemaps url" do
    it "should change when the default_host is changed" do
      ls.default_host = 'http://one.com'
      ls.default_host.should == 'http://one.com'
      ls.default_host.should == ls.sitemap.location.host
      ls.default_host.should == ls.sitemap_index.location.host
    end

    it "should change when the sitemaps_path is changed" do
      ls.default_host = 'http://one.com'
      ls.sitemaps_path = 'sitemaps/'
      ls.sitemap.location.url.should == 'http://one.com/sitemaps/sitemap1.xml.gz'
      ls.sitemap_index.location.url.should == 'http://one.com/sitemaps/sitemap_index.xml.gz'
    end
  end

  describe "sitemap_index_url" do
    it "should return the url to the index file" do
      ls.default_host = default_host
      ls.sitemap_index.location.url.should == "#{default_host}/sitemap_index.xml.gz"
      ls.sitemap_index_url.should == ls.sitemap_index.location.url
    end
  end

  describe "search_engines" do
    it "should have search engines by default" do
      ls.search_engines.should be_a(Hash)
      ls.search_engines.size.should == 3
    end

    it "should support being modified" do
      ls.search_engines[:newengine] = 'abc'
      ls.search_engines.size.should == 4
    end

    it "should support being set to nil" do
      ls = SitemapGenerator::LinkSet.new(:default_host => 'http://one.com', :search_engines => nil)
      ls.search_engines.should be_a(Hash)
      ls.search_engines.should be_empty
      ls.search_engines = nil
      ls.search_engines.should be_a(Hash)
      ls.search_engines.should be_empty
    end
  end

  describe "ping search engines" do
    it "should not fail" do
      ls.expects(:open).at_least_once
      lambda { ls.ping_search_engines }.should_not raise_error
    end

    it "should raise if no host is set" do
      lambda { SitemapGenerator::LinkSet.new.ping_search_engines }.should raise_error(SitemapGenerator::SitemapError, 'No value set for host')
    end

    it "should use the sitemap index url provided" do
      index_url = 'http://example.com/index.xml'
      ls = SitemapGenerator::LinkSet.new(:search_engines => { :google => 'http://google.com/?url=%s' })
      ls.expects(:open).with("http://google.com/?url=#{CGI.escape(index_url)}")
      ls.ping_search_engines(index_url)
    end

    it "should use the sitemap index url from the link set" do
      ls = SitemapGenerator::LinkSet.new(
        :default_host => default_host,
        :search_engines => { :google => 'http://google.com/?url=%s' })
      index_url = ls.sitemap_index_url
      ls.expects(:open).with("http://google.com/?url=#{CGI.escape(index_url)}")
      ls.ping_search_engines(index_url)
    end

    it "should include the given search engines" do
      ls.search_engines = nil
      ls.expects(:open).with(regexp_matches(/^http:\/\/newnegine\.com\?/))
      ls.ping_search_engines(:newengine => 'http://newnegine.com?%s')

      ls.expects(:open).with(regexp_matches(/^http:\/\/newnegine\.com\?/)).twice
      ls.ping_search_engines(:newengine => 'http://newnegine.com?%s', :anotherengine => 'http://newnegine.com?%s')
    end
  end

  describe "only" do
    it "should be set as an initialize option" do
      SitemapGenerator::LinkSet.new(:default_host => default_host, :only => [/group_name/]).only.should == [/group_name/]
    end

    it "should be set as an accessor" do
      ls.only = [/group_name/]
      ls.only.should == [/group_name/]
    end
  end

  describe "exclude" do
    it "should be set as an initialize option" do
      SitemapGenerator::LinkSet.new(:default_host => default_host, :exclude => [/group_name/]).exclude.should == [/group_name/]
    end

    it "should be set as an accessor" do
      ls.exclude = [/group_name/]
      ls.exclude.should == [/group_name/]
    end
  end

  describe "verbose" do
    it "should be set as an initialize option" do
      SitemapGenerator::LinkSet.new(:default_host => default_host, :verbose => false).verbose.should be_false
      SitemapGenerator::LinkSet.new(:default_host => default_host, :verbose => true).verbose.should be_true
    end

    it "should be set as an accessor" do
      ls.verbose = true
      ls.verbose.should be_true
      ls.verbose = false
      ls.verbose.should be_false
    end

    it "should use SitemapGenerator.verbose as a default" do
      SitemapGenerator.expects(:verbose).returns(true).at_least_once
      SitemapGenerator::LinkSet.new.verbose.should be_true
      SitemapGenerator.expects(:verbose).returns(false).at_least_once
      SitemapGenerator::LinkSet.new.verbose.should be_false
    end
  end

  describe "when finalizing" do
    let(:ls) { SitemapGenerator::LinkSet.new(:default_host => default_host, :verbose => true) }

    it "should output summary lines" do
      ls.sitemap.expects(:summary)
      ls.sitemap_index.expects(:summary)
      ls.finalize!
    end
  end

  describe "sitemaps host" do
    let(:new_host) { 'http://wowza.com' }

    it "should have a host" do
      ls.default_host = default_host
      ls.default_host.should == default_host
    end

    it "should default to default host" do
      ls.sitemaps_host.should == ls.default_host
    end

    it "should update the host in the sitemaps when changed" do
      ls.sitemaps_host = new_host
      ls.sitemaps_host.should == new_host
      ls.sitemap.location.host.should == ls.sitemaps_host
      ls.sitemap_index.location.host.should == ls.sitemaps_host
    end

    it "should not change the default host for links" do
      ls.sitemaps_host = new_host
      ls.default_host.should == default_host
    end
  end

  describe "with a sitemap index specified" do
    before :each do
      @index = SitemapGenerator::Builder::SitemapIndexFile.new(:host => default_host)
      @ls = SitemapGenerator::LinkSet.new(:sitemap_index => @index, :sitemaps_host => 'http://newhost.com')
    end

    it "should not modify the index" do
      @ls.filename = :newname
      @ls.sitemap.location.filename.should =~ /newname/
      @ls.sitemap_index.location.filename =~ /sitemap_index/
    end

    it "should not modify the index" do
      @ls.sitemaps_host = 'http://newhost.com'
      @ls.sitemap.location.host.should == 'http://newhost.com'
      @ls.sitemap_index.location.host.should == default_host
    end

    it "should not finalize the index" do
      @ls.send(:finalize_sitemap_index!)
      @ls.sitemap_index.finalized?.should be_false
    end
  end

  describe "new group" do
    describe "general behaviour" do
      it "should return a LinkSet" do
        ls.group.should be_a(SitemapGenerator::LinkSet)
      end

      it "should inherit the index" do
        ls.group.sitemap_index.should == ls.sitemap_index
      end

      it "should protect the sitemap_index" do
        ls.group.instance_variable_get(:@protect_index).should be_true
      end

      it "should not allow chaning the public_path" do
        ls.group(:public_path => 'new/path/').public_path.to_s.should == ls.public_path.to_s
      end
    end

    describe "include_index" do
      it "should set the value" do
        ls.group(:include_index => !ls.include_index).include_index.should_not == ls.include_index
      end

      it "should default to false" do
        ls.group.include_index.should be_false
      end
    end

    describe "include_root" do
      it "should set the value" do
        ls.group(:include_root => !ls.include_root).include_root.should_not == ls.include_root
      end

      it "should default to false" do
        ls.group.include_root.should be_false
      end
    end

    describe "filename" do
      it "should inherit the value" do
        ls.group.filename.should == :sitemap
      end

      it "should set the value" do
        group = ls.group(:filename => :xxx)
        group.filename.should == :xxx
        group.sitemap.location.filename.should =~ /xxx/
      end
    end

    describe "verbose" do
      it "should inherit the value" do
        ls.group.verbose.should == ls.verbose
      end

      it "should set the value" do
        ls.group(:verbose => !ls.verbose).verbose.should_not == ls.verbose
      end
    end

    describe "sitemaps_path" do
      it "should inherit the sitemaps_path" do
        group = ls.group
        group.sitemaps_path.should == ls.sitemaps_path
        group.sitemap.location.sitemaps_path.should == ls.sitemap.location.sitemaps_path
      end

      it "should set the sitemaps_path" do
        path = 'new/path'
        group = ls.group(:sitemaps_path => path)
        group.sitemaps_path.should == path
        group.sitemap.location.sitemaps_path.to_s.should == path
      end
    end

    describe "default_host" do
      it "should inherit the default_host" do
        ls.group.default_host.should == default_host
      end

      it "should set the default_host" do
        host = 'http://defaulthost.com'
        group = ls.group(:default_host => host)
        group.default_host.should == host
        group.sitemap.location.host.should == host
      end
    end

    describe "sitemaps_host" do
      it "should set the sitemaps host" do
        @host = 'http://sitemaphost.com'
        @group = ls.group(:sitemaps_host => @host)
        @group.sitemaps_host.should == @host
        @group.sitemap.location.host.should == @host
      end

      it "should finalize the sitemap if it is the only option" do
        ls.expects(:finalize_sitemap!)
        ls.group(:sitemaps_host => 'http://test.com') {}
      end

      it "should use the same sitemaps_namer" do
        @group = ls.group(:sitemaps_host => 'http://test.com') {}
        @group.sitemap.location.namer.should == ls.sitemap.location.namer
      end
    end

    describe "sitemaps_namer" do
      it "should inherit the value" do
        ls.group.sitemaps_namer.should == ls.sitemaps_namer
        ls.group.sitemap.location.namer.should == ls.sitemaps_namer
      end

      it "should set the value" do
        namer = SitemapGenerator::SitemapNamer.new(:xxx)
        group = ls.group(:sitemaps_namer => namer)
        group.sitemaps_namer.should == namer
        group.sitemap.location.namer.should == namer
        group.sitemap.location.filename.should =~ /xxx/
      end
    end

    describe "create_index" do
      it "should inherit the value" do
        ls.group.create_index.should == ls.create_index
        ls.create_index = :some_value
        ls.group.create_index.should == :some_value
      end

      it "should set the value" do
        group = ls.group(:create_index => :some_value)
        group.create_index.should == :some_value
      end
    end

    describe "should share the current sitemap" do
      it "if only default_host is passed" do
        group = ls.group(:default_host => 'http://newhost.com')
        group.sitemap.should == ls.sitemap
        group.sitemap.location.host.should == 'http://newhost.com'
      end
    end

    describe "should not share the current sitemap" do
      {
        :filename => :xxx,
        :sitemaps_path => 'en/',
        :filename => :example,
        :sitemaps_namer => SitemapGenerator::SitemapNamer.new(:sitemap)
      }.each do |key, value|
        it "if #{key} is present" do
          ls.group(key => value).sitemap.should_not == ls.sitemap
        end
      end
    end

    describe "finalizing" do
      it "should only finalize the sitemaps if a block is passed" do
        @group = ls.group
        @group.sitemap.finalized?.should be_false
      end

      it "should not finalize the sitemap if a group is created" do
        ls.create { group {} }
        ls.sitemap.empty?.should be_true
        ls.sitemap.finalized?.should be_false
      end

      {:sitemaps_path => 'en/',
        :filename => :example,
        :sitemaps_namer => SitemapGenerator::SitemapNamer.new(:sitemap)}.each do |k, v|

        it "should not finalize the sitemap if #{k} is present" do
          ls.expects(:finalize_sitemap!).never
          ls.group(k => v) { }
        end
      end
    end

    describe "adapter" do
      it "should inherit the current adapter" do
        ls.adapter = mock('adapter')
        group = ls.group
        group.should_not be(ls)
        group.adapter.should be(ls.adapter)
      end

      it "should set the value" do
        adapter = mock('adapter')
        group = ls.group(:adapter => adapter)
        group.adapter.should be(adapter)
      end
    end
  end

  describe "after create" do
    it "should finalize the sitemap index" do
      ls.create {}
      ls.sitemap_index.finalized?.should be_true
    end

    it "should finalize the sitemap" do
      ls.create {}
      ls.sitemap.finalized?.should be_true
    end

    it "should not finalize the sitemap if a group was created" do
      ls.instance_variable_set(:@created_group, true)
      ls.send(:finalize_sitemap!)
      ls.sitemap.finalized?.should be_false
    end
  end

  describe "options to create" do
    before :each do
      ls.stubs(:finalize!)
    end

    it "should set include_index" do
      original = ls.include_index
      ls.create(:include_index => !original).include_index.should_not == original
    end

    it "should set include_root" do
      original = ls.include_root
      ls.create(:include_root => !original).include_root.should_not == original
    end

    it "should set the filename" do
      ls.create(:filename => :xxx)
      ls.filename.should == :xxx
      ls.sitemap.location.filename.should =~ /xxx/
    end

    it "should set only" do
      ls.create(:only => [/set_group_name_only/])
      ls.only.should == [/set_group_name_only/]
    end

    it "should set exclude" do
      ls.create(:exclude => [/set_group_name_exclude/])
      ls.exclude.should == [/set_group_name_exclude/]
    end

    it "should set verbose" do
      original = ls.verbose
      ls.create(:verbose => !original).verbose.should_not == original
    end

    it "should set the sitemaps_path" do
      path = 'new/path'
      ls.create(:sitemaps_path => path)
      ls.sitemaps_path.should == path
      ls.sitemap.location.sitemaps_path.to_s.should == path
    end

    it "should set the default_host" do
      host = 'http://defaulthost.com'
      ls.create(:default_host => host)
      ls.default_host.should == host
      ls.sitemap.location.host.should == host
    end

    it "should set the sitemaps host" do
      host = 'http://sitemaphost.com'
      ls.create(:sitemaps_host => host)
      ls.sitemaps_host.should == host
      ls.sitemap.location.host.should == host
    end

    it "should set the sitemaps_namer" do
      namer = SitemapGenerator::SitemapNamer.new(:xxx)
      ls.create(:sitemaps_namer => namer)
      ls.sitemaps_namer.should == namer
      ls.sitemap.location.namer.should == namer
      ls.sitemap.location.filename.should =~ /xxx/
    end

    it "should support both sitemaps_namer and filename options" do
      namer = SitemapGenerator::SitemapNamer.new("sitemap1_")
      ls.create(:sitemaps_namer => namer, :filename => "sitemap1")
      ls.sitemaps_namer.should == namer
      ls.sitemap.location.namer.should == namer
      ls.sitemap.location.filename.should =~ /sitemap1_1/
      ls.sitemap_index.location.filename.should =~ /sitemap1_index/
    end

    it "should support both sitemaps_namer and filename options no matter the order" do
      namer = SitemapGenerator::SitemapNamer.new("sitemap1_")
      options = {} #ActiveSupport::OrderedHash.new
      options[:sitemaps_namer] = namer
      options[:filename] = "sitemap1"
      ls.create(options)
      ls.sitemap.location.filename.should =~ /sitemap1_1/
      ls.sitemap_index.location.filename.should =~ /sitemap1_index/
    end

    it "should not modify the options hash" do
      options = { :filename => 'sitemaptest', :verbose => false }
      ls.create(options)
      options.should == { :filename => 'sitemaptest', :verbose => false }
    end

    it "should set create_index" do
      ls.create(:create_index => :auto)
      ls.create_index.should == :auto
    end
  end

  describe "reset!" do
    it "should reset the sitemap namer" do
      SitemapGenerator::Sitemap.sitemaps_namer.expects(:reset)
      SitemapGenerator::Sitemap.create(:default_host => 'http://cnn.com')
    end

    it "should reset the default link variable" do
      SitemapGenerator::Sitemap.instance_variable_set(:@added_default_links, true)
      SitemapGenerator::Sitemap.create(:default_host => 'http://cnn.com')
      SitemapGenerator::Sitemap.instance_variable_set(:@added_default_links, false)
    end
  end

  describe "include_root?" do
    it "should return false" do
      ls.include_root = false
      ls.include_root.should be_false
    end

    it "should return true" do
      ls.include_root = true
      ls.include_root.should be_true
    end
  end

  describe "include_index?" do
    let(:sitemaps_host)  { 'http://amazon.com' }

    it "should be true if no sitemaps_host set, or it is the same" do
      ls.include_index = true
      ls.sitemaps_host = default_host
      ls.include_index?.should be_true

      ls.sitemaps_host = nil
      ls.include_index?.should be_true
    end

    it "should be false if include_index is false or sitemaps_host differs" do
      ls.include_index = false
      ls.sitemaps_host = default_host
      ls.include_index?.should be_false

      ls.include_index = true
      ls.sitemaps_host = sitemaps_host
      ls.include_index?.should be_false
    end

    it "should return false" do
      ls = SitemapGenerator::LinkSet.new(:default_host => default_host, :sitemaps_host => sitemaps_host)
      ls.include_index?.should be_false
    end
  end

  describe "output" do
    it "should not output" do
      ls.verbose = false
      ls.expects(:puts).never
      ls.send(:output, '')
    end

    it "should print the given string" do
      ls.verbose = true
      ls.expects(:puts).with('')
      ls.send(:output, '')
    end
  end

  describe "yield_sitemap" do
    it "should default to the value of SitemapGenerator.yield_sitemap?" do
      SitemapGenerator.expects(:yield_sitemap?).returns(true)
      ls.yield_sitemap?.should be_true
      SitemapGenerator.expects(:yield_sitemap?).returns(false)
      ls.yield_sitemap?.should be_false
    end

    it "should be settable as an option" do
      SitemapGenerator.expects(:yield_sitemap?).never
      SitemapGenerator::LinkSet.new(:yield_sitemap => true).yield_sitemap?.should be_true
      SitemapGenerator::LinkSet.new(:yield_sitemap => false).yield_sitemap?.should be_false
    end

    it "should be settable as an attribute" do
      ls.yield_sitemap = true
      ls.yield_sitemap?.should be_true
      ls.yield_sitemap = false
      ls.yield_sitemap?.should be_false
    end

    it "should yield the sitemap in the call to create" do
      ls.send(:interpreter).expects(:eval).with(:yield_sitemap => true)
      ls.yield_sitemap = true
      ls.create
      ls.send(:interpreter).expects(:eval).with(:yield_sitemap => false)
      ls.yield_sitemap = false
      ls.create
    end
  end

  describe "add_links" do
    it "should not change the value of yield_sitemap" do
      ls.stubs(:create)
      ls.yield_sitemap = false
      ls.add_links
      ls.yield_sitemap.should be_false
      ls.yield_sitemap = true
      ls.add_links
      ls.yield_sitemap.should be_true
    end

    it "should always yield the sitemap instance" do
      ls.send(:interpreter).expects(:eval).with(:yield_sitemap => true).twice
      ls.yield_sitemap = false
      ls.add_links
      ls.yield_sitemap = true
      ls.add_links
    end
  end

  describe "add" do
    it "should not modify the options hash" do
      options = { :host => 'http://newhost.com' }
      ls.add('/home', options)
      options.should == { :host => 'http://newhost.com' }
    end

    it "should add the link to the sitemap and include the default host" do
      ls.stubs(:add_default_links)
      ls.sitemap.expects(:add).with('/home', :host => ls.default_host)
      ls.add('/home')
    end

    it "should allow setting of a custom host" do
      ls.stubs(:add_default_links)
      ls.sitemap.expects(:add).with('/home', :host => 'http://newhost.com')
      ls.add('/home', :host => 'http://newhost.com')
    end

    it "should add the default links if they have not been added" do
      ls.expects(:add_default_links)
      ls.add('/home')
    end
  end

  describe "add_to_index" do
    it "should add the link to the sitemap index and pass options" do
      ls.sitemap_index.expects(:add).with('/test', has_entry(:option => 'value'))
      ls.add_to_index('/test', :option => 'value')
    end

    it "should not modify the options hash" do
      options = { :host => 'http://newhost.com' }
      ls.add_to_index('/home', options)
      options.should == { :host => 'http://newhost.com' }
    end

    describe "host" do
      it "should be the sitemaps_host" do
        ls.sitemaps_host = 'http://sitemapshost.com'
        ls.sitemap_index.expects(:add).with('/home', :host => 'http://sitemapshost.com')
        ls.add_to_index('/home')
      end

      it "should be the default_host if no sitemaps_host set" do
        ls.sitemap_index.expects(:add).with('/home', :host => ls.default_host)
        ls.add_to_index('/home')
      end

      it "should allow setting a custom host" do
        ls.sitemap_index.expects(:add).with('/home', :host => 'http://newhost.com')
        ls.add_to_index('/home', :host => 'http://newhost.com')
      end
    end
  end

  describe "create_index" do
    describe "when false" do
      let(:ls)  { SitemapGenerator::LinkSet.new(:default_host => default_host, :create_index => false) }

      it "should not write the index" do
        ls.send(:finalize_sitemap_index!)
        ls.sitemap_index.written?.should be_false
      end

      it "should still add finalized sitemaps to the index (but the index is never finalized)" do
        ls.expects(:add_to_index).with(ls.sitemap).once
        ls.send(:finalize_sitemap!)
      end
    end

    describe "when true" do
      let(:ls)  { SitemapGenerator::LinkSet.new(:default_host => default_host, :create_index => true) }

      it "should always finalize the index" do
        ls.send(:finalize_sitemap_index!)
        ls.sitemap_index.finalized?.should be_true
      end

      it "should add finalized sitemaps to the index" do
        ls.expects(:add_to_index).with(ls.sitemap).once
        ls.send(:finalize_sitemap!)
      end
    end

    describe "when :auto" do
      let(:ls)  { SitemapGenerator::LinkSet.new(:default_host => default_host, :create_index => :auto) }

      it "should not write the index when it is empty" do
        ls.sitemap_index.empty?.should be_true
        ls.send(:finalize_sitemap_index!)
        ls.sitemap_index.written?.should be_false
      end

      it "should add finalized sitemaps to the index" do
        ls.expects(:add_to_index).with(ls.sitemap).once
        ls.send(:finalize_sitemap!)
      end

      it "should not write the index when it has only one link" do
        ls.sitemap_index.add '/test', :host => default_host
        ls.sitemap_index.empty?.should be_false
        ls.send(:finalize_sitemap_index!)
        ls.sitemap_index.written?.should be_false
      end

      it "should write the index when it has more than one link" do
        ls.sitemap_index.add '/test1', :host => default_host
        ls.sitemap_index.add '/test2', :host => default_host
        ls.send(:finalize_sitemap_index!)
        ls.sitemap_index.written?.should be_true
      end
    end
  end
end
