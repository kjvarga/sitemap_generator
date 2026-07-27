# frozen_string_literal: true

require 'spec_helper'
require 'uri'

RSpec.describe SitemapGenerator::LinkSet do
  let(:default_host) { 'http://example.com' }
  let(:ls)           { described_class.new(default_host: default_host) }

  describe 'initializer options' do
    options = %i[public_path sitemaps_path default_host filename search_engines max_sitemap_links]
    values = [File.expand_path(SitemapGenerator.app.root.join('tmp/')), 'mobile/', 'http://myhost.com', :xxx,
              { abc: '123' }, 10]

    options.zip(values).each do |option, value|
      it "sets #{option} to #{value}" do
        ls = described_class.new(option => value)
        expect(ls.send(option)).to eq(value)
      end
    end
  end

  describe 'default options' do
    let(:ls) { described_class.new }

    default_options = {
      filename: :sitemap,
      sitemaps_path: nil,
      public_path: SitemapGenerator.app.root.join('public/'),
      default_host: nil,
      include_index: false,
      include_root: true,
      create_index: :auto,
      max_sitemap_links: SitemapGenerator::MAX_SITEMAP_LINKS
    }

    default_options.each do |option, value|
      it "#{option} should default to #{value}" do
        expect(ls.send(option)).to eq(value)
      end
    end
  end

  describe 'include_root include_index option' do
    it 'includes the root url and the sitemap index url' do
      ls = described_class.new(default_host: default_host, include_root: true, include_index: true)
      ls.create { |sitemap| sitemap }
      expect(ls).to have_attributes(include_root: true, include_index: true, sitemap: have_attributes(link_count: 2))
    end

    it 'does not include the root url' do
      ls = described_class.new(default_host: default_host, include_root: false)
      ls.create { |sitemap| sitemap }
      expect(ls).to have_attributes(include_root: false, include_index: false,
                                    sitemap: have_attributes(link_count: 0))
    end

    it 'does not include the sitemap index url' do
      ls = described_class.new(default_host: default_host, include_index: false)
      ls.create { |sitemap| sitemap }
      expect(ls).to have_attributes(include_root: true, include_index: false, sitemap: have_attributes(link_count: 1))
    end

    it 'does not include the root url or the sitemap index url' do
      ls = described_class.new(default_host: default_host, include_root: false, include_index: false)
      ls.create { |sitemap| sitemap }
      expect(ls).to have_attributes(include_root: false, include_index: false,
                                    sitemap: have_attributes(link_count: 0))
    end
  end

  describe 'sitemaps public_path' do
    it 'defaults to public/' do
      path = SitemapGenerator.app.root.join('public/')
      expect([ls.public_path, ls.sitemap.location.public_path, ls.sitemap_index.location.public_path]).to all(eq(path))
    end

    it 'changes when the public_path is changed' do
      path = SitemapGenerator.app.root.join('tmp/')
      ls.public_path = 'tmp/'
      expect([ls.public_path, ls.sitemap.location.public_path, ls.sitemap_index.location.public_path]).to all(eq(path))
    end

    it 'appends a slash to the path' do
      path = SitemapGenerator.app.root.join('tmp/')
      ls.public_path = 'tmp'
      expect([ls.public_path, ls.sitemap.location.public_path, ls.sitemap_index.location.public_path]).to all(eq(path))
    end
  end

  describe 'sitemaps url' do
    it 'changes when the default_host is changed' do
      ls.default_host = 'http://one.com'
      expect([ls.default_host, ls.sitemap.location.host, ls.sitemap_index.location.host]).to all(eq('http://one.com'))
    end

    it 'changes when the sitemaps_path is changed' do
      ls.default_host = 'http://one.com'
      ls.sitemaps_path = 'sitemaps/'
      expect([ls.sitemap.location.url, ls.sitemap_index.location.url])
        .to all(eq('http://one.com/sitemaps/sitemap.xml.gz'))
    end

    it 'appends a slash to the path' do
      ls.default_host = 'http://one.com'
      ls.sitemaps_path = 'sitemaps'
      expect([ls.sitemap.location.url, ls.sitemap_index.location.url])
        .to all(eq('http://one.com/sitemaps/sitemap.xml.gz'))
    end
  end

  describe 'sitemap_index_url' do
    it 'returns the url to the index file' do
      ls.default_host = default_host
      expect([ls.sitemap_index.location.url, ls.sitemap_index_url]).to all(eq("#{default_host}/sitemap.xml.gz"))
    end
  end

  describe 'search_engines' do
    it 'has search engines by default' do
      expect(ls.search_engines).to eq({})
    end

    it 'supports being modified' do
      ls.search_engines[:newengine] = 'abc'
      expect(ls.search_engines.size).to eq(1)
    end

    it 'supports being set to nil' do
      ls = described_class.new(default_host: 'http://one.com', search_engines: nil)
      expect_empty_hash(ls.search_engines)
      ls.search_engines = nil
      expect_empty_hash(ls.search_engines)
    end

    def expect_empty_hash(value)
      expect(value).to be_a(Hash)
      expect(value).to be_empty
    end
  end

  describe 'ping search engines' do
    it 'raises if no host is set' do
      expect do
        described_class.new.ping_search_engines
      end.to raise_error(SitemapGenerator::SitemapError, 'No value set for host')
    end

    it 'uses the sitemap index url provided' do
      index_url = 'http://example.com/index.xml'
      ls = described_class.new(search_engines: { google: 'http://google.com/?url=%s' })
      request = stub_request(:get, "http://google.com/?url=#{URI.encode_www_form_component(index_url)}")
      ls.ping_search_engines(index_url)
      expect(request).to have_been_requested
    end

    it 'uses the sitemap index url from the link set' do
      ls = described_class.new(default_host: default_host, search_engines: { google: 'http://google.com/?url=%s' })
      expect_search_engine_pinged(ls.sitemap_index_url) { ls.ping_search_engines }
    end

    # rubocop:disable RSpec/ExampleLength -- 2 distinct scenarios (single ping, then reset + double ping)
    it 'includes the given search engines', :aggregate_failures do
      ls.search_engines = nil
      request = stub_request(:get, %r{^http://newnegine\.com\?})
      ls.ping_search_engines(newengine: 'http://newnegine.com?%s')
      expect(request).to have_been_requested

      WebMock.reset_executed_requests!
      ls.ping_search_engines(newengine: 'http://newnegine.com?%s', anotherengine: 'http://newnegine.com?%s')
      expect(request).to have_been_requested.twice
    end
    # rubocop:enable RSpec/ExampleLength

    def expect_search_engine_pinged(index_url)
      request = stub_request(:get, "http://google.com/?url=#{URI.encode_www_form_component(index_url)}")
      yield
      expect(request).to have_been_requested
    end
  end

  describe 'verbose' do
    it 'is set as an initialize option' do
      [false, true].each do |value|
        expect(described_class.new(default_host: default_host, verbose: value).verbose).to be(value)
      end
    end

    it 'is set as an accessor' do
      [true, false].each do |value|
        ls.verbose = value
        expect(ls.verbose).to be(value)
      end
    end

    it 'uses SitemapGenerator.verbose as a default when true', :aggregate_failures do
      expect(SitemapGenerator).to receive(:verbose).and_return(true).twice
      expect(described_class.new.verbose).to be(true)
    end

    it 'uses SitemapGenerator.verbose as a default when false', :aggregate_failures do
      expect(SitemapGenerator).to receive(:verbose).and_return(false).twice
      expect(described_class.new.verbose).to be(false)
    end
  end

  describe 'when finalizing' do
    let(:ls) { described_class.new(default_host: default_host, verbose: true, create_index: true) }

    it 'outputs summary lines', :aggregate_failures do
      expect(ls.sitemap.location).to receive(:summary)
      expect(ls.sitemap_index.location).to receive(:summary)
      ls.finalize!
    end
  end

  describe 'sitemaps host' do
    let(:new_host) { 'http://wowza.com' }

    it 'has a host' do
      ls.default_host = default_host
      expect(ls.default_host).to eq(default_host)
    end

    it 'defaults to default host' do
      expect(ls.sitemaps_host).to eq(ls.default_host)
    end

    it 'updates the host in the sitemaps when changed' do
      ls.sitemaps_host = new_host
      expect([ls.sitemaps_host, ls.sitemap.location.host, ls.sitemap_index.location.host]).to all(eq(new_host))
    end

    it 'does not change the default host for links' do
      ls.sitemaps_host = new_host
      expect(ls.default_host).to eq(default_host)
    end
  end

  describe 'with a sitemap index specified' do
    let(:index) { SitemapGenerator::Builder::SitemapIndexFile.new(host: default_host) }
    let(:ls) { described_class.new(sitemap_index: index, sitemaps_host: 'http://newhost.com') }

    it 'does not modify the index when the filename changes' do
      ls.filename = :newname
      expect(ls.sitemap.location.filename).to include('newname')
      ls.sitemap_index.location.filename.include?('sitemap')
    end

    it 'does not modify the index when sitemaps_host changes', :aggregate_failures do
      ls.sitemaps_host = 'http://newhost.com'
      expect(ls.sitemap.location.host).to eq('http://newhost.com')
      expect(ls.sitemap_index.location.host).to eq(default_host)
    end

    it 'does not finalize the index' do
      ls.send(:finalize_sitemap_index!)
      expect(ls.sitemap_index.finalized?).to be(false)
    end
  end

  describe 'new group' do
    describe 'general behaviour' do
      it 'returns a LinkSet' do
        expect(ls.group).to be_a(described_class)
      end

      it 'inherits the index' do
        expect(ls.group.sitemap_index).to eq(ls.sitemap_index)
      end

      it 'protects the sitemap_index' do
        expect(ls.group.instance_variable_get(:@protect_index)).to be(true)
      end

      it 'does not allow changing the public_path' do
        expect(ls.group(public_path: 'new/path/').public_path.to_s).to eq(ls.public_path.to_s)
      end
    end

    describe 'include_index' do
      it 'sets the value' do
        expect(ls.group(include_index: !ls.include_index).include_index).not_to eq(ls.include_index)
      end

      it 'defaults to false' do
        expect(ls.group.include_index).to be(false)
      end
    end

    describe 'include_root' do
      it 'sets the value' do
        expect(ls.group(include_root: !ls.include_root).include_root).not_to eq(ls.include_root)
      end

      it 'defaults to false' do
        expect(ls.group.include_root).to be(false)
      end
    end

    describe 'filename' do
      it 'inherits the value' do
        expect(ls.group.filename).to eq(:sitemap)
      end

      it 'sets the value', :aggregate_failures do
        group = ls.group(filename: :xxx)
        expect(group.filename).to eq(:xxx)
        expect(group.sitemap.location.filename).to include('xxx')
      end
    end

    describe 'verbose' do
      it 'inherits the value' do
        expect(ls.group.verbose).to eq(ls.verbose)
      end

      it 'sets the value' do
        expect(ls.group(verbose: !ls.verbose).verbose).not_to eq(ls.verbose)
      end
    end

    describe 'sitemaps_path' do
      it 'inherits the sitemaps_path', :aggregate_failures do
        group = ls.group
        expect(group.sitemaps_path).to eq(ls.sitemaps_path)
        expect(group.sitemap.location.sitemaps_path).to eq(ls.sitemap.location.sitemaps_path)
      end

      it 'sets the sitemaps_path', :aggregate_failures do
        path = 'new/path'
        group = ls.group(sitemaps_path: path)
        expect(group.sitemaps_path).to eq(path)
        expect(group.sitemap.location.sitemaps_path.to_s).to eq('new/path/')
      end
    end

    describe 'default_host' do
      it 'inherits the default_host' do
        expect(ls.group.default_host).to eq(default_host)
      end

      it 'sets the default_host' do
        host = 'http://defaulthost.com'
        group = ls.group(default_host: host)
        expect([group.default_host, group.sitemap.location.host]).to all(eq(host))
      end
    end

    describe 'sitemaps_host' do
      it 'sets the sitemaps host' do
        host = 'http://sitemaphost.com'
        group = ls.group(sitemaps_host: host)
        expect([group.sitemaps_host, group.sitemap.location.host]).to all(eq(host))
      end

      it 'finalizes the sitemap if it is the only option' do
        expect(ls).to receive(:finalize_sitemap!)
        ls.group(sitemaps_host: 'http://test.com') { nil }
      end

      it 'uses the same namer' do
        group = ls.group(sitemaps_host: 'http://test.com') { nil }
        expect(group.sitemap.location.namer).to eq(ls.sitemap.location.namer)
      end
    end

    describe 'namer' do
      it 'inherits the value' do
        expect([ls.group.namer, ls.group.sitemap.location.namer]).to all(eq(ls.namer))
      end

      it 'sets the value', :aggregate_failures do
        namer = SitemapGenerator::SimpleNamer.new(:xxx)
        group = ls.group(namer: namer)
        expect(group.namer).to eq(namer)
        expect(group.sitemap.location.namer).to eq(namer)
        expect(group.sitemap.location.filename).to include('xxx')
      end
    end

    describe 'create_index' do
      it 'inherits the value', :aggregate_failures do
        expect(ls.group.create_index).to eq(ls.create_index)
        ls.create_index = :some_value
        expect(ls.group.create_index).to eq(:some_value)
      end

      it 'sets the value' do
        group = ls.group(create_index: :some_value)
        expect(group.create_index).to eq(:some_value)
      end
    end

    context 'when only default_host is passed' do
      it 'shares the current sitemap and uses the new host', :aggregate_failures do
        group = ls.group(default_host: 'http://newhost.com')
        expect(group.sitemap).to eq(ls.sitemap)
        expect(group.sitemap.location.host).to eq('http://newhost.com')
      end
    end

    {
      filename: :xxx,
      sitemaps_path: 'en/',
      namer: SitemapGenerator::SimpleNamer.new(:sitemap)
    }.each do |key, value|
      context "when a new-location option (#{key}) is present" do
        it 'does not share the current sitemap' do
          expect(ls.group(key => value).sitemap).not_to eq(ls.sitemap)
        end
      end
    end

    describe 'finalizing' do
      it 'only finalizes the sitemaps if a block is passed' do
        group = ls.group
        expect(group.sitemap.finalized?).to be(false)
      end

      it 'does not finalize the sitemap if a group is created' do
        ls.create { group { nil } }
        expect(ls.sitemap).to have_attributes(empty?: true, finalized?: false)
      end

      { sitemaps_path: 'en/',
        filename: :example,
        namer: SitemapGenerator::SimpleNamer.new(:sitemap) }.each do |k, v|
        it "does not finalize the sitemap if #{k} is present" do
          expect(ls).not_to receive(:finalize_sitemap!)
          ls.group(k => v) { nil }
        end
      end
    end

    describe 'adapter' do
      it 'inherits the current adapter', :aggregate_failures do
        ls.adapter = Object.new
        group = ls.group
        expect(group).not_to be(ls)
        expect(group.adapter).to be(ls.adapter)
      end

      it 'sets the value' do
        adapter = Object.new
        group = ls.group(adapter: adapter)
        expect(group.adapter).to be(adapter)
      end
    end
  end

  describe 'after create' do
    it 'finalizes the sitemap index' do
      ls.create { nil }
      expect(ls.sitemap_index.finalized?).to be(true)
    end

    it 'finalizes the sitemap' do
      ls.create { nil }
      expect(ls.sitemap.finalized?).to be(true)
    end

    it 'does not finalize the sitemap if a group was created' do
      ls.instance_variable_set(:@created_group, true)
      ls.send(:finalize_sitemap!)
      expect(ls.sitemap.finalized?).to be(false)
    end
  end

  describe 'options to create' do
    it 'sets include_index' do
      original = ls.include_index
      expect(ls.create(include_index: !original).include_index).not_to eq(original)
    end

    it 'sets include_root' do
      original = ls.include_root
      expect(ls.create(include_root: !original).include_root).not_to eq(original)
    end

    it 'sets the filename', :aggregate_failures do
      ls.create(filename: :xxx)
      expect(ls.filename).to eq(:xxx)
      expect(ls.sitemap.location.filename).to include('xxx')
    end

    it 'sets verbose' do
      original = ls.verbose
      expect(ls.create(verbose: !original).verbose).not_to eq(original)
    end

    it 'sets the sitemaps_path', :aggregate_failures do
      path = 'new/path'
      ls.create(sitemaps_path: path)
      expect(ls.sitemaps_path).to eq(path)
      expect(ls.sitemap.location.sitemaps_path.to_s).to eq('new/path/')
    end

    it 'sets the default_host' do
      host = 'http://defaulthost.com'
      ls.create(default_host: host)
      expect([ls.default_host, ls.sitemap.location.host]).to all(eq(host))
    end

    it 'sets the sitemaps host' do
      host = 'http://sitemaphost.com'
      ls.create(sitemaps_host: host)
      expect([ls.sitemaps_host, ls.sitemap.location.host]).to all(eq(host))
    end

    it 'sets the namer', :aggregate_failures do
      namer = SitemapGenerator::SimpleNamer.new(:xxx)
      ls.create(namer: namer)
      expect(ls.namer).to eq(namer)
      expect(ls.sitemap.location.namer).to eq(namer)
      expect(ls.sitemap.location.filename).to include('xxx')
    end

    it 'supports both namer and filename options' do
      namer = SitemapGenerator::SimpleNamer.new('sitemap2')
      ls.create(namer: namer, filename: 'sitemap1')
      expect([ls.namer, ls.sitemap.location.namer]).to all(eq(namer))
      expect_filenames_to_match(/^sitemap2/)
    end

    it 'supports both namer and filename options no matter the order' do
      ls.create(namer: SitemapGenerator::SimpleNamer.new('sitemap1'), filename: 'sitemap2')
      expect_filenames_to_match(/^sitemap1/)
    end

    def expect_filenames_to_match(pattern)
      expect(ls.sitemap.location.filename).to match(pattern)
      expect(ls.sitemap_index.location.filename).to match(pattern)
    end

    it 'does not modify the options hash' do
      options = { filename: 'sitemaptest', verbose: false }
      ls.create(options)
      expect(options).to eq({ filename: 'sitemaptest', verbose: false })
    end

    it 'sets create_index' do
      ls.create(create_index: :auto)
      expect(ls.create_index).to eq(:auto)
    end

    it 'does not call finalize!' do
      expect(ls).not_to receive(:finalize!)
      ls.create({})
    end

    context 'when block is given' do
      it 'finalize!s after the block' do
        expect(ls).to receive(:finalize!)
        ls.create do
          add('/test')
        end
      end
    end
  end

  describe 'reset!' do
    it 'resets the sitemap namer' do
      expect(SitemapGenerator::Sitemap.namer).to receive(:reset)
      SitemapGenerator::Sitemap.create(default_host: 'http://cnn.com')
    end

    it 'resets the default link variable' do
      # SitemapGenerator::Sitemap delegates via method_missing to an internal @link_set;
      # instance_variable_get/set on Sitemap itself would silently touch the wrong object.
      SitemapGenerator::Sitemap.namer # ensure @link_set is lazily initialized
      link_set = SitemapGenerator::Sitemap.instance_variable_get(:@link_set)
      link_set.instance_variable_set(:@added_default_links, true)
      SitemapGenerator::Sitemap.create(default_host: 'http://cnn.com')
      expect(link_set.instance_variable_get(:@added_default_links)).to be(false)
    end
  end

  describe 'include_root?' do
    it 'returns false' do
      ls.include_root = false
      expect(ls.include_root).to be(false)
    end

    it 'returns true' do
      ls.include_root = true
      expect(ls.include_root).to be(true)
    end
  end

  describe 'include_index?' do
    let(:sitemaps_host) { 'http://amazon.com' }

    it 'is true when sitemaps_host is unset or matches default_host' do
      ls.include_index = true
      [default_host, nil].each do |host|
        ls.sitemaps_host = host
        expect(ls.include_index?).to be(true)
      end
    end

    it 'is false if include_index is false or sitemaps_host differs' do
      false_include_index_scenarios.each do |include_index, host|
        ls.include_index = include_index
        ls.sitemaps_host = host
        expect(ls.include_index?).to be(false)
      end
    end

    def false_include_index_scenarios
      [[false, default_host], [true, sitemaps_host]]
    end

    it 'returns false' do
      ls = described_class.new(default_host: default_host, sitemaps_host: sitemaps_host)
      expect(ls.include_index?).to be(false)
    end
  end

  describe 'output' do
    it 'does not output' do
      ls.verbose = false
      expect(ls).not_to receive(:puts)
      ls.send(:output, '')
    end

    it 'prints the given string' do
      ls.verbose = true
      expect(ls).to receive(:puts).with('')
      ls.send(:output, '')
    end
  end

  describe 'yield_sitemap' do
    it 'defaults to the value of SitemapGenerator.yield_sitemap?' do
      allow(SitemapGenerator).to receive(:yield_sitemap?).and_return(true, false)
      [true, false].each { |expected| expect(ls.yield_sitemap?).to be(expected) }
    end

    it 'is settable as an option', :aggregate_failures do
      expect(SitemapGenerator).not_to receive(:yield_sitemap?)
      [true, false].each { |value| expect(described_class.new(yield_sitemap: value).yield_sitemap?).to be(value) }
    end

    it 'is settable as an attribute' do
      [true, false].each do |value|
        ls.yield_sitemap = value
        expect(ls.yield_sitemap?).to be(value)
      end
    end

    it 'yields the sitemap in the call to create' do
      expect_create_yields(true)
      expect_create_yields(false)
    end

    def expect_create_yields(yield_sitemap)
      expect(ls.send(:interpreter)).to receive(:eval).with(yield_sitemap: yield_sitemap)
      ls.yield_sitemap = yield_sitemap
      ls.create
    end
  end

  describe 'add' do
    it 'does not modify the options hash' do
      options = { host: 'http://newhost.com' }
      ls.add('/home', options)
      expect(options).to eq({ host: 'http://newhost.com' })
    end

    it 'adds the link to the sitemap and include the default host', :aggregate_failures do
      expect(ls).to receive(:add_default_links)
      expect(ls.sitemap).to receive(:add).with('/home', { host: ls.default_host })
      ls.add('/home')
    end

    it 'allows setting of a custom host', :aggregate_failures do
      expect(ls).to receive(:add_default_links)
      expect(ls.sitemap).to receive(:add).with('/home', { host: 'http://newhost.com' })
      ls.add('/home', host: 'http://newhost.com')
    end

    it 'adds the default links if they have not been added' do
      expect(ls).to receive(:add_default_links)
      ls.add('/home')
    end
  end

  describe 'add_to_index' do
    it 'adds the link to the sitemap index and pass options' do
      expect(ls.sitemap_index).to receive(:add).with('/test', hash_including(option: 'value'))
      ls.add_to_index('/test', option: 'value')
    end

    it 'does not modify the options hash' do
      options = { host: 'http://newhost.com' }
      ls.add_to_index('/home', options)
      expect(options).to eq({ host: 'http://newhost.com' })
    end

    describe 'host' do
      it 'is the sitemaps_host' do
        ls.sitemaps_host = 'http://sitemapshost.com'
        expect(ls.sitemap_index).to receive(:add).with('/home', { host: 'http://sitemapshost.com' })
        ls.add_to_index('/home')
      end

      it 'is the default_host when sitemaps_host is not set' do
        expect(ls.sitemap_index).to receive(:add).with('/home', { host: ls.default_host })
        ls.add_to_index('/home')
      end

      it 'allows setting a custom host' do
        expect(ls.sitemap_index).to receive(:add).with('/home', { host: 'http://newhost.com' })
        ls.add_to_index('/home', host: 'http://newhost.com')
      end
    end
  end

  describe 'create_index' do
    let(:location) do
      SitemapGenerator::SitemapLocation.new(namer: SitemapGenerator::SimpleNamer.new(:sitemap), public_path: 'tmp/',
                                            sitemaps_path: 'test/', host: 'http://example.com/')
    end
    let(:sitemap)  { SitemapGenerator::Builder::SitemapFile.new(location) }

    describe 'when false' do
      let(:ls) { described_class.new(default_host: default_host, create_index: false) }

      it 'does not write the index' do
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.written?).to be(false)
      end

      it 'still adds finalized sitemaps to the index (but the index is never finalized)' do
        expect(ls).to receive(:add_to_index).with(ls.sitemap).once
        ls.send(:finalize_sitemap!)
      end
    end

    describe 'when true' do
      let(:ls) { described_class.new(default_host: default_host, create_index: true) }

      it 'always finalizes the index' do
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.finalized?).to be(true)
      end

      it 'adds finalized sitemaps to the index' do
        expect(ls).to receive(:add_to_index).with(ls.sitemap).once
        ls.send(:finalize_sitemap!)
      end
    end

    describe 'when :auto' do
      let(:ls) { described_class.new(default_host: default_host, create_index: :auto) }

      it 'does not write the index when it is empty', :aggregate_failures do
        expect(ls.sitemap_index.empty?).to be(true)
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.written?).to be(false)
      end

      it 'adds finalized sitemaps to the index' do
        expect(ls).to receive(:add_to_index).with(ls.sitemap).once
        ls.send(:finalize_sitemap!)
      end

      it 'writes the index when a link is added manually', :aggregate_failures do
        ls.sitemap_index.add '/test'
        expect(ls.sitemap_index.empty?).to be(false)
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.written?).to be(true)

        # Test that the index url is reported correctly
        expect(ls.sitemap_index.index_url).to eq('http://example.com/sitemap.xml.gz')
      end

      it 'does not write the index when only one sitemap is added (internal usage)', :aggregate_failures do
        ls.sitemap_index.add sitemap
        expect(ls.sitemap_index.empty?).to be(false)
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.written?).to be(false)

        # Test that the index url is reported correctly
        expect(ls.sitemap_index.index_url).to eq(sitemap.location.url)
      end

      it 'writes the index when more than one sitemap is added (considered internal usage)' do
        ls.sitemap_index.add sitemap
        ls.sitemap_index.add sitemap.new
        ls.send(:finalize_sitemap_index!)
        expect(ls.sitemap_index.written?).to be(true)
        expect_index_url_reported_correctly('http://example.com/sitemap.xml.gz')
      end

      # Test that the index url is reported correctly
      def expect_index_url_reported_correctly(expected_url)
        expect(ls.sitemap_index.index_url).to eq(ls.sitemap_index.location.url)
        expect(ls.sitemap_index.index_url).to eq(expected_url)
      end

      it 'writes the index when it has more than one link', :aggregate_failures do
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

    it 'is not written', :aggregate_failures do
      expect(ls.sitemap.empty?).to be(true)
      expect(ls).not_to receive(:add_to_index)
      ls.send(:finalize_sitemap!)
    end

    it 'is written', :aggregate_failures do
      ls.sitemap.add '/test'
      expect(ls.sitemap.empty?).to be(false)
      expect(ls).to receive(:add_to_index).with(ls.sitemap)
      ls.send(:finalize_sitemap!)
    end
  end

  describe 'compress' do
    it 'is true by default' do
      expect(ls.compress).to be(true)
    end

    it 'is set on the location objects' do
      expect([ls.sitemap.location[:compress], ls.sitemap_index.location[:compress]]).to all(be(true))
    end

    it 'is settable and gettable' do
      [false, :all_but_first].each do |value|
        ls.compress = value
        expect(ls.compress).to eq(value)
      end
    end

    it 'updates the location objects when set' do
      ls.compress = false
      expect([ls.sitemap.location[:compress], ls.sitemap_index.location[:compress]]).to all(be(false))
    end

    describe 'in groups' do
      it 'inherits the current compress setting' do
        ls.compress = false
        expect(ls.group.compress).to be(false)
      end

      it 'sets the compress value' do
        group = ls.group(compress: false)
        expect(group.compress).to be(false)
      end
    end
  end

  describe 'max_sitemap_links' do
    it 'can be set via initializer' do
      ls = described_class.new(max_sitemap_links: 10)
      expect(ls.max_sitemap_links).to eq(10)
    end

    it 'can be set via accessor' do
      ls.max_sitemap_links = 10
      expect(ls.max_sitemap_links).to eq(10)
    end
  end

  describe 'options_for_group' do
    describe 'max_sitemap_links' do
      it 'inherits the current value' do
        ls.max_sitemap_links = 10
        options = ls.send(:options_for_group, {})
        expect(options[:max_sitemap_links]).to eq(10)
      end

      it 'returns the value when set' do
        options = ls.send(:options_for_group, max_sitemap_links: 10)
        expect(options[:max_sitemap_links]).to eq(10)
      end
    end
  end

  describe 'sitemap_location' do
    it 'returns an instance initialized with values from the link set' do
      allow(ls).to receive_messages(sitemaps_host: :host, namer: :namer, public_path: :public_path,
                                    verbose: :verbose, max_sitemap_links: :max_sitemap_links)
      assign_ivars(sitemaps_path: :sitemaps_path, adapter: :adapter, compress: :compress)
      expect(SitemapGenerator::SitemapLocation).to receive(:new).with(expected_sitemap_location_args)
      ls.sitemap_location
    end

    def assign_ivars(ivars)
      ivars.each { |name, value| ls.instance_variable_set(:"@#{name}", value) }
    end

    def expected_sitemap_location_args
      {
        host: :host,
        namer: :namer,
        public_path: :public_path,
        sitemaps_path: :sitemaps_path,
        adapter: :adapter,
        verbose: :verbose,
        compress: :compress,
        max_sitemap_links: :max_sitemap_links
      }
    end
  end

  describe '#add_default_links' do
    let(:frozen_time) { Time.at(1_000_000).utc }

    before do
      allow(SitemapGenerator::Utilities).to receive(:current_time).and_return(frozen_time)
    end

    context 'when include_root is true' do
      it 'adds the root URL with lastmod and priority set' do
        expect(ls).to receive(:add).with('/', hash_including(lastmod: frozen_time, priority: 1.0))
        ls.send(:add_default_links)
      end
    end

    context 'when include_index is true' do
      let(:ls) { described_class.new(default_host: default_host, include_index: true, include_root: false) }

      it 'adds the sitemap index with lastmod and priority set' do
        expect(ls).to receive(:add).with(ls.sitemap_index, hash_including(lastmod: frozen_time, priority: 1.0))
        ls.send(:add_default_links)
      end
    end
  end
end
