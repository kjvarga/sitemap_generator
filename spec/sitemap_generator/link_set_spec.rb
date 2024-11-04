require 'spec_helper'

RSpec.describe SitemapGenerator::LinkSet do
  let(:default_host) { 'http://example.com' }
  let(:ls)           { SitemapGenerator::LinkSet.new(:default_host => default_host) }

  describe 'initializer options' do
    options = [:public_path, :sitemaps_path, :default_host, :filename, :search_engines, :max_sitemap_links]
    values = [File.expand_path(SitemapGenerator.app.root + 'tmp/'), 'mobile/', 'http://myhost.com', :xxx, { :abc => '123' }, 10]

    options.zip(values).each do |option, value|
      it 'should set #{option} to #{value}' do
        ls = SitemapGenerator::LinkSet.new(option => value)
        expect(ls.send(option)).to eq(value)
      end
    end
  end

  describe 'default options' do
    let(:ls) { SitemapGenerator::LinkSet.new }

    default_options = {
      :filename      => :sitemap,
      :sitemaps_path => nil,
      :public_path   => SitemapGenerator.app.root + 'public/',
      :default_host  => nil,
      :include_index => false,
      :include_root  => true,
      :create_index  => :auto,
      :max_sitemap_links => SitemapGenerator::MAX_SITEMAP_LINKS
    }

    default_options.each do |option, value|
      it '#{option} should default to #{value}' do
        expect(ls.send(option)).to eq(value)
      end
    end
  end

  describe 'include_root include_index option' do
    it 'should include the root url and the sitemap index url' do
      ls = SitemapGenerator::LinkSet.new(:default_host => default_host, :include_root => true, :include_index => true)
      expect(ls.include_root).to be(true)
      expect(ls.include_index).to be(true)
      ls.create { |sitemap| }
      expect(ls.sitemap.link_count).to eq(2)
    end

    it 'should not include the root url' do
      ls = SitemapGenerator::LinkSet.new(:default_host => default_host, :include_root => false)
      expect(ls.include_root).to be(false)
      expect(ls.include_index).to be(false)
      ls.create { |sitemap| }
      expect(ls.sitemap.link_count).to eq(0)
    end

    it 'should not include the sitemap index url' do
      ls = SitemapGenerator::LinkSet.new(:default_host => default_host, :include_index => false)
      expect(ls.include_root).to be(true)
      expect(ls.include_index).to be(false)
      ls.create { |sitemap| }
      expect(ls.sitemap.link_count).to eq(1)
    end

    it 'should not include the root url or the sitemap index url' do
      ls = SitemapGenerator::LinkSet.new(:default_host => default_host, :include_root => false, :include_index => false)
      expect(ls.include_root).to be(false)
      expect(ls.include_index).to be(false)
      ls.create { |sitemap| }
      expect(ls.sitemap.link_count).to eq(0)
    end
  end

  describe 'sitemaps public_path' do
    it 'should default to public/' do
      path = SitemapGenerator.app.root + 'public/'
      expect(ls.public_path).to eq(path)
      expect(ls.sitemap.location.public_path).to eq(path)
      expect(ls.sitemap_index.location.public_path).to eq(path)
    end

    it 'should change when the public_path is changed' do
      path = SitemapGenerator.app.root + 'tmp/'
      ls.public_path = 'tmp/'
      expect(ls.public_path).to eq(path)
      expect(ls.sitemap.location.public_path).to eq(path)
      expect(ls.sitemap_index.location.public_path).to eq(path)
    end

    it 'should append a slash to the path' do
      path = SitemapGenerator.app.root + 'tmp/'
      ls.public_path = 'tmp'
      expect(ls.public_path).to eq(path)
      expect(ls.sitemap.location.public_path).to eq(path)
      expect(ls.sitemap_index.location.public_path).to eq(path)
    end
  end

  describe 'sitemaps url' do
    it 'should change when the default_host is changed' do
      ls.default_host = 'http://one.com'
      expect(ls.default_host).to eq('http://one.com')
      expect(ls.default_host).to eq(ls.sitemap.location.host)
      expect(ls.default_host).to eq(ls.sitemap_index.location.host)
    end

    it 'should change when the sitemaps_path is changed' do
      ls.default_host = 'http://one.com'
      ls.sitemaps_path = 'sitemaps/'
      expect(ls.sitemap.location.url).to eq('http://one.com/sitemaps/sitemap.xml.gz')
      expect(ls.sitemap_index.location.url).to eq('http://one.com/sitemaps/sitemap.xml.gz')
    end

    it 'should append a slash to the path' do
      ls.default_host = 'http://one.com'
      ls.sitemaps_path = 'sitemaps'
      expect(ls.sitemap.location.url).to eq('http://one.com/sitemaps/sitemap.xml.gz')
      expect(ls.sitemap_index.location.url).to eq('http://one.com/sitemaps/sitemap.xml.gz')
    end
  end

  describe 'sitemap_index_url' do
    it 'should return the url to the index file' do
      ls.default_host = default_host
      expect(ls.sitemap_index.location.url).to eq("#{default_host}/sitemap.xml.gz")
      expect(ls.sitemap_index_url).to eq(ls.sitemap_index.location.url)
    end
  end

  describe 'search_engines' do
    it 'should have search engines by default' do
      expect(ls.search_engines).to be_a(Hash)
      expect(ls.search_engines.size).to eq(1)
    end

    it 'should support being modified' do
      ls.search_engines[:newengine] = 'abc'
      expect(ls.search_engines.size).to eq(2)
    end

    it 'should support being set to nil' do
      ls = SitemapGenerator::LinkSet.new(:default_host => 'http://one.com', :search_engines => nil)
      expect(ls.search_engines).to be_a(Hash)
      expect(ls.search_engines).to be_empty
      ls.search_engines = nil
      expect(ls.search_engines).to be_a(Hash)
      expect(ls.search_engines).to be_empty
    end
  end

  describe 'ping search engines' do
    it 'should not fail' do
      request = stub_request(:get, //)
      expect { ls.ping_search_engines }.not_to raise_error
      expect(request).to have_been_requested.at_least_once
    end

    it 'should raise if no host is set' do
      expect { SitemapGenerator::LinkSet.new.ping_search_engines }.to raise_error(SitemapGenerator::SitemapError, 'No value set for host')
    end

    it 'should use the sitemap index url provided' do
      index_url = 'http://example.com/index.xml'
      ls = SitemapGenerator::LinkSet.new(:search_engines => { :google => 'http://google.com/?url=%s' })
      request = stub_request(:get, "http://google.com/?url=#{CGI.escape(index_url)}")
      ls.ping_search_engines(index_url)
      expect(request).to have_been_requested
    end

    it 'should use the sitemap index url from the link set' do
      ls = SitemapGenerator::LinkSet.new(
        :default_host => default_host,
        :search_engines => { :google => 'http://google.com/?url=%s' })
      index_url = ls.sitemap_index_url
      request = stub_request(:get, "http://google.com/?url=#{CGI.escape(index_url)}")
      ls.ping_search_engines
      expect(request).to have_been_requested
    end

    it 'should include the given search engines' do
      ls.search_engines = nil
      request = stub_request(:get, /^http:\/\/newnegine\.com\?/)
      ls.ping_search_engines(:newengine => 'http://newnegine.com?%s')
      expect(request).to have_been_requested

      WebMock.reset_executed_requests!
      ls.ping_search_engines(:newengine => 'http://newnegine.com?%s', :anotherengine => 'http://newnegine.com?%s')
      expect(request).to have_been_requested.twice
    end
  end

  describe 'verbose' do
    it 'should be set as an initialize option' do
      expect(SitemapGenerator::LinkSet.new(:default_host => default_host, :verbose => false).verbose).to be(false)
      expect(SitemapGenerator::LinkSet.new(:default_host => default_host, :verbose => true).verbose).to be(true)
    end

    it 'should be set as an accessor' do
      ls.verbose = true
      expect(ls.verbose).to be(true)
      ls.verbose = false
      expect(ls.verbose).to be(false)
    end

    it 'should use SitemapGenerator.verbose as a default' do
      expect(SitemapGenerator).to receive(:verbose).and_return(true).twice
      expect(SitemapGenerator::LinkSet.new.verbose).to be(true)
    end

    it 'should use SitemapGenerator.verbose as a default' do
      expect(SitemapGenerator).to receive(:verbose).and_return(false).twice
      expect(SitemapGenerator::LinkSet.new.verbose).to be(false)
    end
  end

  describe 'when finalizing' do
    let(:ls) { SitemapGenerator::LinkSet.new(:default_host => default_host, :verbose => true, :create_index => true) }

    it 'should output summary lines' do
      expect(ls.sitemap.location).to receive(:summary)
      expect(ls.sitemap_index.location).to receive(:summary)
      ls.finalize!
    end
  end

  describe 'sitemaps host' do
    let(:new_host) { 'http://wowza.com' }

    it 'should have a host' do
      ls.default_host = default_host
      expect(ls.default_host).to eq(default_host)
    end

    it 'should default to default host' do
      expect(ls.sitemaps_host).to eq(ls.default_host)
    end

    it 'should update the host in the sitemaps when changed' do
      ls.sitemaps_host = new_host
      expect(ls.sitemaps_host).to eq(new_host)
      expect(ls.sitemap.location.host).to eq(ls.sitemaps_host)
      expect(ls.sitemap_index.location.host).to eq(ls.sitemaps_host)
    end

    it 'should not change the default host for links' do
      ls.sitemaps_host = new_host
      expect(ls.default_host).to eq(default_host)
    end
  end

  describe 'with a sitemap index specified' do
    before do
      @index = SitemapGenerator::Builder::SitemapIndexFile.new(:host => default_host)
      @ls = SitemapGenerator::LinkSet.new(:sitemap_index => @index, :sitemaps_host => 'http://newhost.com')
    end

    it 'should not modify the index' do
      @ls.filename = :newname
      expect(@ls.sitemap.location.filename).to match(/newname/)
      @ls.sitemap_index.location.filename =~ /sitemap/
    end

    it 'should not modify the index' do
      @ls.sitemaps_host = 'http://newhost.com'
      expect(@ls.sitemap.location.host).to eq('http://newhost.com')
      expect(@ls.sitemap_index.location.host).to eq(default_host)
    end

    it 'should not finalize the index' do
      @ls.send(:finalize_sitemap_index!)
      expect(@ls.sitemap_index.finalized?).to be(false)
    end
  end

  describe 'new group' do
    describe 'general behaviour' do
      it 'should return a LinkSet' do
        expect(ls.group).to be_a(SitemapGenerator::LinkSet)
      end

      it 'should inherit the index' do
        expect(ls.group.sitemap_index).to eq(ls.sitemap_index)
      end

      it 'should protect the sitemap_index' do
        expect(ls.group.instance_variable_get(:@protect_index)).to be(true)
      end

      it 'should not allow chaning the public_path' do
        expect(ls.group(:public_path => 'new/path/').public_path.to_s).to eq(ls.public_path.to_s)
      end
    end

    describe 'include_index' do
      it 'should set the value' do
        expect(ls.group(:include_index => !ls.include_index).include_index).not_to eq(ls.include_index)
      end

      it 'should default to false' do
        expect(ls.group.include_index).to be(false)
      end
    end

    describe 'include_root' do
      it 'should set the value' do
        expect(ls.group(:include_root => !ls.include_root).include_root).not_to eq(ls.include_root)
      end

      it 'should default to false' do
        expect(ls.group.include_root).to be(false)
      end
    end

    describe 'filename' do
      it 'should inherit the value' do
        expect(ls.group.filename).to eq(:sitemap)
      end

      it 'should set the value' do
        group = ls.group(:filename => :xxx)
        expect(group.filename).to eq(:xxx)
        expect(group.sitemap.location.filename).to match(/xxx/)
      end
    end

    describe 'verbose' do
      it 'should inherit the value' do
        expect(ls.group.verbose).to eq(ls.verbose)
      end

      it 'should set the value' do
        expect(ls.group(:verbose => !ls.verbose).verbose).not_to eq(ls.verbose)
      end
    end

    describe 'sitemaps_path' do
      it 'should inherit the sitemaps_path' do
        group = ls.group
        expect(group.sitemaps_path).to eq(ls.sitemaps_path)
        expect(group.sitemap.location.sitemaps_path).to eq(ls.sitemap.location.sitemaps_path)
      end

      it 'should set the sitemaps_path' do
        path = 'new/path'
        group = ls.group(:sitemaps_path => path)
        expect(group.sitemaps_path).to eq(path)
        expect(group.sitemap.location.sitemaps_path.to_s).to eq('new/path/')
      end
    end

    describe 'default_host' do
      it 'should inherit the default_host' do
        expect(ls.group.default_host).to eq(default_host)
      end

      it 'should set the default_host' do
        host = 'http://defaulthost.com'
        group = ls.group(:default_host => host)
        expect(group.default_host).to eq(host)
        expect(group.sitemap.location.host).to eq(host)
      end
    end

    describe 'sitemaps_host' do
      it 'should set the sitemaps host' do
        @host = 'http://sitemaphost.com'
        @group = ls.group(:sitemaps_host => @host)
        expect(@group.sitemaps_host).to eq(@host)
        expect(@group.sitemap.location.host).to eq(@host)
      end

      it 'should finalize the sitemap if it is the only option' do
        expect(ls).to receive(:finalize_sitemap!)
        ls.group(:sitemaps_host => 'http://test.com') {}
      end

      it 'should use the same namer' do
        @group = ls.group(:sitemaps_host => 'http://test.com') {}
        expect(@group.sitemap.location.namer).to eq(ls.sitemap.location.namer)
      end
    end

    describe 'namer' do
      it 'should inherit the value' do
        expect(ls.group.namer).to eq(ls.namer)
        expect(ls.group.sitemap.location.namer).to eq(ls.namer)
      end

      it 'should set the value' do
        namer = SitemapGenerator::SimpleNamer.new(:xxx)
        group = ls.group(:namer => namer)
        expect(group.namer).to eq(namer)
        expect(group.sitemap.location.namer).to eq(namer)
        expect(group.sitemap.location.filename).to match(/xxx/)
      end
    end

    describe 'create_index' do
      it 'should inherit the value' do
        expect(ls.group.create_index).to eq(ls.create_index)
        ls.create_index = :some_value
        expect(ls.group.create_index).to eq(:some_value)
      end

      it 'should set the value' do
        group = ls.group(:create_index => :some_value)
        expect(group.create_index).to eq(:some_value)
      end
    end

    describe 'should share the current sitemap' do
      it 'if only default_host is passed' do
        group = ls.group(:default_host => 'http://newhost.com')
        expect(group.sitemap).to eq(ls.sitemap)
        expect(group.sitemap.location.host).to eq('http://newhost.com')
      end
    end

    describe 'should not share the current sitemap' do
      {
        :filename => :xxx,
        :sitemaps_path => 'en/',
        :namer => SitemapGenerator::SimpleNamer.new(:sitemap)
      }.each do |key, value|
        it 'if #{key} is present' do
          expect(ls.group(key => value).sitemap).not_to eq(ls.sitemap)
        end
      end
    end

    describe 'finalizing' do
      it 'should only finalize the sitemaps if a block is passed' do
        @group = ls.group
        expect(@group.sitemap.finalized?).to be(false)
      end

      it 'should not finalize the sitemap if a group is created' do
        ls.create { group {} }
        expect(ls.sitemap.empty?).to be(true)
        expect(ls.sitemap.finalized?).to be(false)
      end

      {:sitemaps_path => 'en/',
        :filename => :example,
        :namer => SitemapGenerator::SimpleNamer.new(:sitemap)
      }.each do |k, v|

        it 'should not finalize the sitemap if #{k} is present' do
          expect(ls).to receive(:finalize_sitemap!).never
          ls.group(k => v) { }
        end
      end
    end

    describe 'adapter' do
      it 'should inherit the current adapter' do
        ls.adapter = Object.new
        group = ls.group
        expect(group).not_to be(ls)
        expect(group.adapter).to be(ls.adapter)
      end

      it 'should set the value' do
        adapter = Object.new
        group = ls.group(:adapter => adapter)
        expect(group.adapter).to be(adapter)
      end
    end
  end

  describe 'after create' do
    it 'should finalize the sitemap index' do
      ls.create {}
      expect(ls.sitemap_index.finalized?).to be(true)
    end

    it 'should finalize the sitemap' do
      ls.create {}
      expect(ls.sitemap.finalized?).to be(true)
    end

    it 'should not finalize the sitemap if a group was created' do
      ls.instance_variable_set(:@created_group, true)
      ls.send(:finalize_sitemap!)
      expect(ls.sitemap.finalized?).to be(false)
    end
  end

  describe 'options to create' do
    before do
      expect(ls).to receive(:finalize!)
    end

    it 'should set include_index' do
      original = ls.include_index
      expect(ls.create(:include_index => !original).include_index).not_to eq(original)
    end

    it 'should set include_root' do
      original = ls.include_root
      expect(ls.create(:include_root => !original).include_root).not_to eq(original)
    end

    it 'should set the filename' do
      ls.create(:filename => :xxx)
      expect(ls.filename).to eq(:xxx)
      expect(ls.sitemap.location.filename).to match(/xxx/)
    end

    it 'should set verbose' do
      original = ls.verbose
      expect(ls.create(:verbose => !original).verbose).not_to eq(original)
    end

    it 'should set the sitemaps_path' do
      path = 'new/path'
      ls.create(:sitemaps_path => path)
      expect(ls.sitemaps_path).to eq(path)
      expect(ls.sitemap.location.sitemaps_path.to_s).to eq('new/path/')
    end

    it 'should set the default_host' do
      host = 'http://defaulthost.com'
      ls.create(:default_host => host)
      expect(ls.default_host).to eq(host)
      expect(ls.sitemap.location.host).to eq(host)
    end

    it 'should set the sitemaps host' do
      host = 'http://sitemaphost.com'
      ls.create(:sitemaps_host => host)
      expect(ls.sitemaps_host).to eq(host)
      expect(ls.sitemap.location.host).to eq(host)
    end

    it 'should set the namer' do
      namer = SitemapGenerator::SimpleNamer.new(:xxx)
      ls.create(:namer => namer)
      expect(ls.namer).to eq(namer)
      expect(ls.sitemap.location.namer).to eq(namer)
      expect(ls.sitemap.location.filename).to match(/xxx/)
    end

    it 'should support both namer and filename options' do
      namer = SitemapGenerator::SimpleNamer.new('sitemap2')
      ls.create(:namer => namer, :filename => 'sitemap1')
      expect(ls.namer).to eq(namer)
      expect(ls.sitemap.location.namer).to eq(namer)
      expect(ls.sitemap.location.filename).to match(/^sitemap2/)
      expect(ls.sitemap_index.location.filename).to match(/^sitemap2/)
    end

    it 'should support both namer and filename options no matter the order' do
      options = {
        :namer => SitemapGenerator::SimpleNamer.new('sitemap1'),
        :filename => 'sitemap2'
      }
      ls.create(options)
      expect(ls.sitemap.location.filename).to match(/^sitemap1/)
      expect(ls.sitemap_index.location.filename).to match(/^sitemap1/)
    end

    it 'should not modify the options hash' do
      options = { :filename => 'sitemaptest', :verbose => false }
      ls.create(options)
      expect(options).to eq({ :filename => 'sitemaptest', :verbose => false })
    end

    it 'should set create_index' do
      ls.create(:create_index => :auto)
      expect(ls.create_index).to eq(:auto)
    end
  end

  describe 'reset!' do
    it 'should reset the sitemap namer' do
      expect(SitemapGenerator::Sitemap.namer).to receive(:reset)
      SitemapGenerator::Sitemap.create(:default_host => 'http://cnn.com')
    end

    it 'should reset the default link variable' do
      SitemapGenerator::Sitemap.instance_variable_set(:@added_default_links, true)
      SitemapGenerator::Sitemap.create(:default_host => 'http://cnn.com')
      SitemapGenerator::Sitemap.instance_variable_set(:@added_default_links, false)
    end
  end

  describe 'include_root?' do
    it 'should return false' do
      ls.include_root = false
      expect(ls.include_root).to be(false)
    end

    it 'should return true' do
      ls.include_root = true
      expect(ls.include_root).to be(true)
    end
  end

  describe 'include_index?' do
    let(:sitemaps_host)  { 'http://amazon.com' }

    it 'should be true if no sitemaps_host set, or it is the same' do
      ls.include_index = true
      ls.sitemaps_host = default_host
      expect(ls.include_index?).to be(true)

      ls.sitemaps_host = nil
      expect(ls.include_index?).to be(true)
    end

    it 'should be false if include_index is false or sitemaps_host differs' do
      ls.include_index = false
      ls.sitemaps_host = default_host
      expect(ls.include_index?).to be(false)

      ls.include_index = true
      ls.sitemaps_host = sitemaps_host
      expect(ls.include_index?).to be(false)
    end

    it 'should return false' do
      ls = SitemapGenerator::LinkSet.new(:default_host => default_host, :sitemaps_host => sitemaps_host)
      expect(ls.include_index?).to be(false)
    end
  end

  describe 'output' do
    it 'should not output' do
      ls.verbose = false
      expect(ls).to receive(:puts).never
      ls.send(:output, '')
    end

    it 'should print the given string' do
      ls.verbose = true
      expect(ls).to receive(:puts).with('')
      ls.send(:output, '')
    end
  end

  describe 'yield_sitemap' do
    it 'should default to the value of SitemapGenerator.yield_sitemap?' do
      expect(SitemapGenerator).to receive(:yield_sitemap?).and_return(true)
      expect(ls.yield_sitemap?).to be(true)
      expect(SitemapGenerator).to receive(:yield_sitemap?).and_return(false)
      expect(ls.yield_sitemap?).to be(false)
    end

    it 'should be settable as an option' do
      expect(SitemapGenerator).to receive(:yield_sitemap?).never
      expect(SitemapGenerator::LinkSet.new(:yield_sitemap => true).yield_sitemap?).to be(true)
      expect(SitemapGenerator::LinkSet.new(:yield_sitemap => false).yield_sitemap?).to be(false)
    end

    it 'should be settable as an attribute' do
      ls.yield_sitemap = true
      expect(ls.yield_sitemap?).to be(true)
      ls.yield_sitemap = false
      expect(ls.yield_sitemap?).to be(false)
    end

    it 'should yield the sitemap in the call to create' do
      expect(ls.send(:interpreter)).to receive(:eval).with(:yield_sitemap => true)
      ls.yield_sitemap = true
      ls.create
      expect(ls.send(:interpreter)).to receive(:eval).with(:yield_sitemap => false)
      ls.yield_sitemap = false
      ls.create
    end
  end

  describe 'add' do
    it 'should not modify the options hash' do
      options = { :host => 'http://newhost.com' }
      ls.add('/home', options)
      expect(options).to eq({ :host => 'http://newhost.com' })
    end

    it 'should add the link to the sitemap and include the default host' do
      expect(ls).to receive(:add_default_links)
      expect(ls.sitemap).to receive(:add).with('/home', { :host => ls.default_host })
      ls.add('/home')
    end

    it 'should allow setting of a custom host' do
      expect(ls).to receive(:add_default_links)
      expect(ls.sitemap).to receive(:add).with('/home', { :host => 'http://newhost.com' })
      ls.add('/home', :host => 'http://newhost.com')
    end

    it 'should add the default links if they have not been added' do
      expect(ls).to receive(:add_default_links)
      ls.add('/home')
    end
  end

  describe 'add_to_index' do
    it 'should add the link to the sitemap index and pass options' do
      expect(ls.sitemap_index).to receive(:add).with('/test', hash_including(:option => 'value'))
      ls.add_to_index('/test', :option => 'value')
    end

    it 'should not modify the options hash' do
      options = { :host => 'http://newhost.com' }
      ls.add_to_index('/home', options)
      expect(options).to eq({ :host => 'http://newhost.com' })
    end

    describe 'host' do
      it 'should be the sitemaps_host' do
        ls.sitemaps_host = 'http://sitemapshost.com'
        expect(ls.sitemap_index).to receive(:add).with('/home', { :host => 'http://sitemapshost.com' })
        ls.add_to_index('/home')
      end

      it 'should be the default_host if no sitemaps_host set' do
        expect(ls.sitemap_index).to receive(:add).with('/home', { :host => ls.default_host })
        ls.add_to_index('/home')
      end

      it 'should allow setting a custom host' do
        expect(ls.sitemap_index).to receive(:add).with('/home', { :host => 'http://newhost.com' })
        ls.add_to_index('/home', :host => 'http://newhost.com')
      end
    end
  end

  describe 'create_index' do
    let(:location) { SitemapGenerator::SitemapLocation.new(:namer => SitemapGenerator::SimpleNamer.new(:sitemap), :public_path => 'tmp/', :sitemaps_path => 'test/', :host => 'http://example.com/') }
    let(:sitemap)  { SitemapGenerator::Builder::SitemapFile.new(location) }

    describe 'when false' do
      let(:ls)  { SitemapGenerator::LinkSet.new(:default_host => default_host, :create_index => false) }

      it 'should not write the index' do
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.written?).to be(false)
      end

      it 'should still add finalized sitemaps to the index (but the index is never finalized)' do
        expect(ls).to receive(:add_to_index).with(ls.sitemap).once
        ls.send(:finalize_sitemap!)
      end
    end

    describe 'when true' do
      let(:ls)  { SitemapGenerator::LinkSet.new(:default_host => default_host, :create_index => true) }

      it 'should always finalize the index' do
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.finalized?).to be(true)
      end

      it 'should add finalized sitemaps to the index' do
        expect(ls).to receive(:add_to_index).with(ls.sitemap).once
        ls.send(:finalize_sitemap!)
      end
    end

    describe 'when :auto' do
      let(:ls)  { SitemapGenerator::LinkSet.new(:default_host => default_host, :create_index => :auto) }

      it 'should not write the index when it is empty' do
        expect(ls.sitemap_index.empty?).to be(true)
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.written?).to be(false)
      end

      it 'should add finalized sitemaps to the index' do
        expect(ls).to receive(:add_to_index).with(ls.sitemap).once
        ls.send(:finalize_sitemap!)
      end

      it 'should write the index when a link is added manually' do
        ls.sitemap_index.add '/test'
        expect(ls.sitemap_index.empty?).to be(false)
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.written?).to be(true)

        # Test that the index url is reported correctly
        expect(ls.sitemap_index.index_url).to eq('http://example.com/sitemap.xml.gz')
      end

      it 'should not write the index when only one sitemap is added (considered internal usage)' do
        ls.sitemap_index.add sitemap
        expect(ls.sitemap_index.empty?).to be(false)
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.written?).to be(false)

        # Test that the index url is reported correctly
        expect(ls.sitemap_index.index_url).to eq(sitemap.location.url)
      end

      it 'should write the index when more than one sitemap is added (considered internal usage)' do
        ls.sitemap_index.add sitemap
        ls.sitemap_index.add sitemap.new
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.written?).to be(true)

        # Test that the index url is reported correctly
        expect(ls.sitemap_index.index_url).to eq(ls.sitemap_index.location.url)
        expect(ls.sitemap_index.index_url).to eq('http://example.com/sitemap.xml.gz')
      end

      it 'should write the index when it has more than one link' do
        ls.sitemap_index.add '/test1'
        ls.sitemap_index.add '/test2'
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.written?).to be(true)

        # Test that the index url is reported correctly
        expect(ls.sitemap_index.index_url).to eq('http://example.com/sitemap.xml.gz')
      end
    end
  end

  describe 'when sitemap empty' do
    before do
      ls.include_root = false
    end

    it 'should not be written' do
      expect(ls.sitemap.empty?).to be(true)
      expect(ls).to receive(:add_to_index).never
      ls.send(:finalize_sitemap!)
    end

    it 'should be written' do
      ls.sitemap.add '/test'
      expect(ls.sitemap.empty?).to be(false)
      expect(ls).to receive(:add_to_index).with(ls.sitemap)
      ls.send(:finalize_sitemap!)
    end
  end

  describe 'compress' do
    it 'should be true by default' do
      expect(ls.compress).to be(true)
    end

    it 'should be set on the location objects' do
      expect(ls.sitemap.location[:compress]).to be(true)
      expect(ls.sitemap_index.location[:compress]).to be(true)
    end

    it 'should be settable and gettable' do
      ls.compress = false
      expect(ls.compress).to be(false)
      ls.compress = :all_but_first
      expect(ls.compress).to eq(:all_but_first)
    end

    it 'should update the location objects when set' do
      ls.compress = false
      expect(ls.sitemap.location[:compress]).to be(false)
      expect(ls.sitemap_index.location[:compress]).to be(false)
    end

    describe 'in groups' do
      it 'should inherit the current compress setting' do
        ls.compress = false
        expect(ls.group.compress).to be(false)
      end

      it 'should set the compress value' do
        group = ls.group(:compress => false)
        expect(group.compress).to be(false)
      end
    end
  end

  describe 'max_sitemap_links' do
    it 'can be set via initializer' do
      ls = SitemapGenerator::LinkSet.new(:max_sitemap_links => 10)
      expect(ls.max_sitemap_links).to eq(10)
    end

    it 'can be set via accessor' do
      ls.max_sitemap_links = 10
      expect(ls.max_sitemap_links).to eq(10)
    end
  end

  describe 'options_for_group' do
    context 'max_sitemap_links' do
      it 'inherits the current value' do
        ls.max_sitemap_links = 10
        options = ls.send(:options_for_group, {})
        expect(options[:max_sitemap_links]).to eq(10)
      end

      it 'returns the value when set' do
        options = ls.send(:options_for_group, :max_sitemap_links => 10)
        expect(options[:max_sitemap_links]).to eq(10)
      end
    end
  end

  describe 'sitemap_location' do
    it 'returns an instance initialized with values from the link set' do
      expect(ls).to receive(:sitemaps_host).and_return(:host)
      expect(ls).to receive(:namer).and_return(:namer)
      expect(ls).to receive(:public_path).and_return(:public_path)
      expect(ls).to receive(:verbose).and_return(:verbose)
      expect(ls).to receive(:max_sitemap_links).and_return(:max_sitemap_links)

      ls.instance_variable_set(:@sitemaps_path, :sitemaps_path)
      ls.instance_variable_set(:@adapter, :adapter)
      ls.instance_variable_set(:@compress, :compress)

      expect(SitemapGenerator::SitemapLocation).to receive(:new).with(
        :host => :host,
        :namer => :namer,
        :public_path => :public_path,
        :sitemaps_path => :sitemaps_path,
        :adapter => :adapter,
        :verbose => :verbose,
        :compress => :compress,
        :max_sitemap_links => :max_sitemap_links
      )
      ls.sitemap_location
    end
  end
end
