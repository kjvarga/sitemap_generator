require 'spec_helper'

RSpec.describe SitemapGenerator::SitemapLocation do
  let(:default_host) { 'http://example.com' }
  let(:location)     { SitemapGenerator::SitemapLocation.new }

  it 'public_path should default to the public directory in the application root' do
    expect(location.public_path).to eq(SitemapGenerator.app.root + 'public/')
  end

  it 'should have a default namer' do
    expect(location[:namer]).not_to be_nil
    expect(location[:filename]).to be_nil
    expect(location.filename).to eq('sitemap1.xml.gz')
  end

  it 'should require a filename' do
    location[:filename] = nil
    expect {
      expect(location.filename).to be_nil
    }.to raise_error(SitemapGenerator::SitemapError, 'No filename or namer set')
  end

  it 'should require a namer' do
    location[:namer] = nil
    expect {
      expect(location.filename).to be_nil
    }.to raise_error(SitemapGenerator::SitemapError, 'No filename or namer set')
  end

  it 'should require a host' do
    location = SitemapGenerator::SitemapLocation.new(:filename => nil, :namer => nil)
    expect {
      expect(location.host).to be_nil
    }.to raise_error(SitemapGenerator::SitemapError, 'No value set for host')
  end

  it 'should accept a Namer option' do
    @namer = SitemapGenerator::SimpleNamer.new(:xxx)
    location = SitemapGenerator::SitemapLocation.new(:namer => @namer)
    expect(location.filename).to eq(@namer.to_s)
  end

  it 'should protect the filename from further changes in the Namer' do
    @namer = SitemapGenerator::SimpleNamer.new(:xxx)
    location = SitemapGenerator::SitemapLocation.new(:namer => @namer)
    expect(location.filename).to eq(@namer.to_s)
    @namer.next
    expect(location.filename).to eq(@namer.previous.to_s)
  end

  it 'should allow changing the namer' do
    @namer1 = SitemapGenerator::SimpleNamer.new(:xxx)
    location = SitemapGenerator::SitemapLocation.new(:namer => @namer1)
    expect(location.filename).to eq(@namer1.to_s)
    @namer2 = SitemapGenerator::SimpleNamer.new(:yyy)
    location[:namer] = @namer2
    expect(location.filename).to eq(@namer2.to_s)
  end

  describe 'testing options and #with' do

    # Array of tuples with instance options and expected method return values
    tests = [
      [{
        :sitemaps_path => nil,
        :public_path => '/public',
        :filename => 'sitemap.xml.gz',
        :host => 'http://test.com' },
      { :url => 'http://test.com/sitemap.xml.gz',
        :directory => '/public',
        :path => '/public/sitemap.xml.gz',
        :path_in_public => 'sitemap.xml.gz'
      }],
      [{
        :sitemaps_path => 'sitemaps/en/',
        :public_path => '/public/system/',
        :filename => 'sitemap.xml.gz',
        :host => 'http://test.com/plus/extra/' },
      { :url => 'http://test.com/plus/extra/sitemaps/en/sitemap.xml.gz',
        :directory => '/public/system/sitemaps/en',
        :path => '/public/system/sitemaps/en/sitemap.xml.gz',
        :path_in_public => 'sitemaps/en/sitemap.xml.gz'
      }]
    ]
    tests.each do |opts, returns|
      returns.each do |method, value|
        it '#{method} should return #{value}' do
          expect(location.with(opts).send(method)).to eq(value)
        end
      end
    end
  end

  describe 'when duplicated' do
    it 'should not inherit some objects' do
      location = SitemapGenerator::SitemapLocation.new(:filename => 'xxx', :host => default_host, :public_path => 'public/')
      expect(location.url).to eq(default_host+'/xxx')
      expect(location.public_path.to_s).to eq('public/')
      dup = location.dup
      expect(dup.url).to eq(location.url)
      expect(dup.url).not_to be(location.url)
      expect(dup.public_path.to_s).to eq(location.public_path.to_s)
      expect(dup.public_path).not_to be(location.public_path)
    end
  end

  describe 'filesize' do
    it 'should read the size of the file at path' do
      expect(location).to receive(:path).and_return('/somepath')
      expect(File).to receive(:size?).with('/somepath')
      location.filesize
    end
  end

  describe 'public_path' do
    it 'should append a trailing slash' do
      location = SitemapGenerator::SitemapLocation.new(:public_path => 'public/google')
      expect(location.public_path.to_s).to eq('public/google/')
      location[:public_path] = 'new/path'
      expect(location.public_path.to_s).to eq('new/path/')
      location[:public_path] = 'already/slashed/'
      expect(location.public_path.to_s).to eq('already/slashed/')
    end
  end

  describe 'sitemaps_path' do
    it 'should append a trailing slash' do
      location = SitemapGenerator::SitemapLocation.new(:sitemaps_path => 'public/google')
      expect(location.sitemaps_path.to_s).to eq('public/google/')
      location[:sitemaps_path] = 'new/path'
      expect(location.sitemaps_path.to_s).to eq('new/path/')
      location[:sitemaps_path] = 'already/slashed/'
      expect(location.sitemaps_path.to_s).to eq('already/slashed/')
    end
  end

  describe 'url' do
    it 'should handle paths not ending in slash' do
      location = SitemapGenerator::SitemapLocation.new(
          :public_path => 'public/google', :filename => 'xxx',
          :host => default_host, :sitemaps_path => 'sub/dir')
      expect(location.url).to eq(default_host + '/sub/dir/xxx')
    end
  end

  describe 'write' do
    let(:location) do
      SitemapGenerator::SitemapLocation.new(:public_path => 'public/', :verbose => verbose)
    end

    before do
      expect(location.adapter).to receive(:write)
    end

    context 'when verbose is true' do
      let(:verbose) { true }

      it 'should output summary line' do
        expect(location).to receive(:summary)
        location.write('data', 1)
      end
    end

    context 'when verbose is false' do
      let(:verbose) { false }

      it 'should not output summary line' do
        expect(location).not_to receive(:summary)
        location.write('data', 1)
      end
    end
  end

  describe 'filename' do
    it 'should strip gz extension if not compressing' do
      location = SitemapGenerator::SitemapLocation.new(:namer => SitemapGenerator::SimpleNamer.new(:sitemap), :compress => false)
      expect(location.filename).to eq('sitemap.xml')
    end

    it 'should not strip gz extension if compressing' do
      location = SitemapGenerator::SitemapLocation.new(:namer => SitemapGenerator::SimpleNamer.new(:sitemap), :compress => true)
      expect(location.filename).to eq('sitemap.xml.gz')
    end

    it 'should strip gz extension if :all_but_first and first file' do
      namer = SitemapGenerator::SimpleNamer.new(:sitemap)
      expect(namer).to receive(:start?).and_return(true)
      location = SitemapGenerator::SitemapLocation.new(:namer => namer, :compress => :all_but_first)
      expect(location.filename).to eq('sitemap.xml')
    end

    it 'should strip gz extension if :all_but_first and first file' do
      namer = SitemapGenerator::SimpleNamer.new(:sitemap)
      expect(namer).to receive(:start?).and_return(false)
      location = SitemapGenerator::SitemapLocation.new(:namer => namer, :compress => :all_but_first)
      expect(location.filename).to eq('sitemap.xml.gz')
    end
  end

  describe 'max_sitemap_links' do
    it 'returns the value set on the object' do
      location = SitemapGenerator::SitemapLocation.new(:max_sitemap_links => 10)
      location[:max_sitemap_links] = 10
    end
  end

  describe 'when not compressing' do
    it 'the URL should point to the uncompressed file' do
      location = SitemapGenerator::SitemapLocation.new(
        :namer => SitemapGenerator::SimpleNamer.new(:sitemap),
        :host => 'http://example.com',
        :compress => false
      )
      expect(location.url).to eq('http://example.com/sitemap.xml')
    end
  end
end

RSpec.describe SitemapGenerator::SitemapIndexLocation do
  let(:location)     { SitemapGenerator::SitemapIndexLocation.new }

  it 'should have a default namer' do
    location = SitemapGenerator::SitemapIndexLocation.new
    expect(location[:namer]).not_to be_nil
    expect(location[:filename]).to be_nil
    expect(location.filename).to eq('sitemap.xml.gz')
  end
end
