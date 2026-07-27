# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::SitemapLocation do
  subject(:location) { described_class.new(**options) }

  let(:options)      { {} }
  let(:default_host) { 'http://example.com' }

  it 'defaults to the public directory in the application root' do
    expect(location.public_path).to eq(SitemapGenerator.app.root.join('public/'))
  end

  it 'has a default namer', :aggregate_failures do
    expect(location[:namer]).not_to be_nil
    expect(location[:filename]).to be_nil
    expect(location.filename).to eq('sitemap1.xml.gz')
  end

  it 'requires a filename' do
    location[:filename] = nil
    expect { location.filename }.to raise_error(SitemapGenerator::SitemapError, 'No filename or namer set')
  end

  it 'requires a namer' do
    location[:namer] = nil
    expect { location.filename }.to raise_error(SitemapGenerator::SitemapError, 'No filename or namer set')
  end

  context 'when filename and namer are nil' do
    let(:options) { { filename: nil, namer: nil } }

    it 'requires a host' do
      expect { location.host }.to raise_error(SitemapGenerator::SitemapError, 'No value set for host')
    end
  end

  context 'when a custom namer is provided' do
    let(:namer)   { SitemapGenerator::SimpleNamer.new(:xxx) }
    let(:options) { { namer: namer } }

    it 'accepts a Namer option' do
      expect(location.filename).to eq(namer.to_s)
    end

    it 'protects the filename from further changes in the Namer' do
      original_filename = location.filename
      namer.next
      expect(location.filename).to eq(original_filename)
    end

    it 'allows changing the namer' do
      namer2 = SitemapGenerator::SimpleNamer.new(:yyy)
      location[:namer] = namer2
      expect(location.filename).to eq(namer2.to_s)
    end
  end

  describe 'testing options and #with' do
    # Array of tuples with instance options and expected method return values
    tests = [
      [{
        sitemaps_path: nil,
        public_path: '/public',
        filename: 'sitemap.xml.gz',
        host: 'http://test.com'
      },
       { url: 'http://test.com/sitemap.xml.gz',
         directory: '/public',
         path: '/public/sitemap.xml.gz',
         path_in_public: 'sitemap.xml.gz' }],
      [{
        sitemaps_path: 'sitemaps/en/',
        public_path: '/public/system/',
        filename: 'sitemap.xml.gz',
        host: 'http://test.com/plus/extra/'
      },
       { url: 'http://test.com/plus/extra/sitemaps/en/sitemap.xml.gz',
         directory: '/public/system/sitemaps/en',
         path: '/public/system/sitemaps/en/sitemap.xml.gz',
         path_in_public: 'sitemaps/en/sitemap.xml.gz' }]
    ]
    tests.each do |opts, returns|
      returns.each do |method, value|
        it "#{method} should return #{value}" do
          expect(location.with(opts).send(method)).to eq(value)
        end
      end
    end
  end

  describe 'when duplicated' do
    let(:options) { { filename: 'xxx', host: default_host, public_path: 'public/' } }

    it 'does not inherit some objects', :aggregate_failures do
      expect(location.url).to eq("#{default_host}/xxx")
      expect(location.public_path.to_s).to eq('public/')
      dup = location.dup
      expect_dup_value_not_shared(dup.url, location.url)
      expect_dup_path_not_shared(dup.public_path, location.public_path)
    end

    def expect_dup_value_not_shared(dup_value, original_value)
      expect(dup_value).to eq(original_value)
      expect(dup_value).not_to be(original_value)
    end

    def expect_dup_path_not_shared(dup_path, original_path)
      expect(dup_path.to_s).to eq(original_path.to_s)
      expect(dup_path).not_to be(original_path)
    end
  end

  describe 'filesize' do
    it 'reads the size of the file at path' do
      expect(File).to receive(:size?).with(location.path)
      location.filesize
    end
  end

  describe '#gzip?' do
    context 'when the filename ends in .gz' do
      let(:options) { { filename: 'sitemap.xml.gz' } }

      it 'returns true' do
        expect(location.gzip?).to be(true)
      end
    end

    context 'when the filename does not end in .gz' do
      let(:options) { { filename: 'sitemap.xml' } }

      it 'returns false' do
        expect(location.gzip?).to be(false)
      end
    end
  end

  describe '#content_type' do
    context 'when the filename ends in .gz' do
      let(:options) { { filename: 'sitemap.xml.gz' } }

      it "returns 'application/x-gzip'" do
        expect(location.content_type).to eq('application/x-gzip')
      end
    end

    context 'when the filename does not end in .gz' do
      let(:options) { { filename: 'sitemap.xml' } }

      it "returns 'application/xml'" do
        expect(location.content_type).to eq('application/xml')
      end
    end

    context 'when compress is :all_but_first' do
      let(:options) { { compress: :all_but_first } }

      it "returns 'application/xml' for the first file" do
        expect(location.content_type).to eq('application/xml')
      end
    end
  end

  describe 'public_path' do
    let(:options) { { public_path: 'public/google' } }

    it 'appends a trailing slash' do
      path_slash_cases.each do |input, expected|
        location[:public_path] = input
        expect(location.public_path.to_s).to eq(expected)
      end
    end

    def path_slash_cases
      { 'public/google' => 'public/google/', 'new/path' => 'new/path/', 'already/slashed/' => 'already/slashed/' }
    end
  end

  describe 'sitemaps_path' do
    let(:options) { { sitemaps_path: 'public/google' } }

    it 'appends a trailing slash' do
      path_slash_cases.each do |input, expected|
        location[:sitemaps_path] = input
        expect(location.sitemaps_path.to_s).to eq(expected)
      end
    end

    def path_slash_cases
      { 'public/google' => 'public/google/', 'new/path' => 'new/path/', 'already/slashed/' => 'already/slashed/' }
    end
  end

  describe 'url' do
    let(:options) { { public_path: 'public/google', filename: 'xxx', host: default_host, sitemaps_path: 'sub/dir' } }

    it 'handles paths not ending in slash' do
      expect(location.url).to eq("#{default_host}/sub/dir/xxx")
    end
  end

  describe 'write' do
    let(:options) { { public_path: 'public/', verbose: verbose } }

    context 'when verbose is true' do
      let(:verbose) { true }

      it 'outputs summary line', :aggregate_failures do
        expect(location.adapter).to receive(:write)
        expect { location.write('data', 1) }.to output(/links/).to_stdout
      end
    end

    context 'when verbose is false' do
      let(:verbose) { false }

      it 'does not output summary line', :aggregate_failures do
        expect(location.adapter).to receive(:write)
        expect { location.write('data', 1) }.not_to output.to_stdout
      end
    end
  end

  describe 'filename' do
    context 'when compress is false' do
      let(:options) { { namer: SitemapGenerator::SimpleNamer.new(:sitemap), compress: false } }

      it 'strips gz extension if not compressing' do
        expect(location.filename).to eq('sitemap.xml')
      end
    end

    context 'when compress is true' do
      let(:options) { { namer: SitemapGenerator::SimpleNamer.new(:sitemap), compress: true } }

      it 'does not strip gz extension if compressing' do
        expect(location.filename).to eq('sitemap.xml.gz')
      end
    end

    context 'when compress is :all_but_first and it is the first file' do
      let(:namer)   { SitemapGenerator::SimpleNamer.new(:sitemap) }
      let(:options) { { namer: namer, compress: :all_but_first } }

      it 'strips gz extension' do
        allow(namer).to receive(:start?).and_return(true)
        expect(location.filename).to eq('sitemap.xml')
      end
    end

    context 'when compress is :all_but_first and it is not the first file' do
      let(:namer)   { SitemapGenerator::SimpleNamer.new(:sitemap) }
      let(:options) { { namer: namer, compress: :all_but_first } }

      it 'does not strip gz extension' do
        allow(namer).to receive(:start?).and_return(false)
        expect(location.filename).to eq('sitemap.xml.gz')
      end
    end
  end

  describe 'max_sitemap_links' do
    let(:options) { { max_sitemap_links: 10 } }

    it 'returns the value set on the object' do
      expect(location[:max_sitemap_links]).to eq(10)
    end
  end

  describe 'when not compressing' do
    let(:options) { { namer: SitemapGenerator::SimpleNamer.new(:sitemap), host: 'http://example.com', compress: false } }

    it 'the URL should point to the uncompressed file' do
      expect(location.url).to eq('http://example.com/sitemap.xml')
    end
  end
end
