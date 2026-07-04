# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::Builder::SitemapUrl do
  let(:loc) do
    SitemapGenerator::SitemapLocation.new(
      sitemaps_path: 'sitemaps/',
      public_path: '/public',
      host: 'http://test.com',
      namer: SitemapGenerator::SimpleNamer.new(:sitemap)
    )
  end
  let(:sitemap_file) { SitemapGenerator::Builder::SitemapFile.new(loc) }

  def new_url(*args)
    args = ['/home', { host: 'http://example.com' }] if args.empty?
    SitemapGenerator::Builder::SitemapUrl.new(*args)
  end

  it 'builds urls for sitemap files' do
    url = described_class.new(sitemap_file)
    expect(url[:loc]).to eq('http://test.com/sitemaps/sitemap.xml.gz')
  end

  it 'lastmod should default to the last modified date for sitemap files' do
    lastmod = (Time.now - 1_209_600)
    expect(sitemap_file).to receive(:lastmod).and_return(lastmod)
    url = described_class.new(sitemap_file)
    expect(url[:lastmod]).to eq(lastmod)
  end

  it 'supports string option keys' do
    url = new_url('/home', 'host' => 'http://string.com', 'priority' => 1)
    expect(url[:priority]).to eq(1)
    expect(url[:host]).to eq('http://string.com')
  end

  it 'supports subdirectory routing' do
    url = described_class.new('/profile', host: 'http://example.com/subdir/')
    expect(url[:loc]).to eq('http://example.com/subdir/profile')
    url = described_class.new('profile', host: 'http://example.com/subdir/')
    expect(url[:loc]).to eq('http://example.com/subdir/profile')
    url = described_class.new('/deep/profile/', host: 'http://example.com/subdir/')
    expect(url[:loc]).to eq('http://example.com/subdir/deep/profile/')
    url = described_class.new('/deep/profile', host: 'http://example.com/subdir')
    expect(url[:loc]).to eq('http://example.com/subdir/deep/profile')
    url = described_class.new('deep/profile', host: 'http://example.com/subdir')
    expect(url[:loc]).to eq('http://example.com/subdir/deep/profile')
    url = described_class.new('deep/profile/', host: 'http://example.com/subdir/')
    expect(url[:loc]).to eq('http://example.com/subdir/deep/profile/')
    url = described_class.new('/', host: 'http://example.com/subdir/')
    expect(url[:loc]).to eq('http://example.com/subdir/')
  end

  it 'does not fail on a nil path segment' do
    expect do
      expect(described_class.new(nil, host: 'http://example.com')[:loc]).to eq('http://example.com')
    end.not_to raise_error
  end

  it 'supports a :videos option' do
    loc = described_class.new('', host: 'http://test.com', videos: [1, 2, 3])
    expect(loc[:videos]).to eq([1, 2, 3])
  end

  it 'supports a singular :video option' do
    loc = described_class.new('', host: 'http://test.com', video: 1)
    expect(loc[:videos]).to eq([1])
  end

  it 'supports an array :video option' do
    loc = described_class.new('', host: 'http://test.com', video: [1, 2], videos: [3, 4])
    expect(loc[:videos]).to eq([3, 4, 1, 2])
  end

  it 'supports a :alternates option' do
    loc = described_class.new('', host: 'http://test.com', alternates: [1, 2, 3])
    expect(loc[:alternates]).to eq([1, 2, 3])
  end

  it 'supports a singular :alternate option' do
    loc = described_class.new('', host: 'http://test.com', alternate: 1)
    expect(loc[:alternates]).to eq([1])
  end

  it 'supports an array :alternate option' do
    loc = described_class.new('', host: 'http://test.com', alternate: [1, 2],
                                  alternates: [3, 4])
    expect(loc[:alternates]).to eq([3, 4, 1, 2])
  end

  it 'does not fail if invalid characters are used in the URL' do
    special = ':$&+,;:=?@'
    url = described_class.new("/#{special}", host: "http://example.com/#{special}/")
    expect(url[:loc]).to eq("http://example.com/#{special}/#{special}")
  end

  describe 'w3c_date' do
    it 'converts dates and times to W3C format' do
      url = new_url
      expect(url.send(:w3c_date, Date.new(0))).to eq('0000-01-01')
      expect(url.send(:w3c_date, Time.at(0).utc)).to eq('1970-01-01T00:00:00+00:00')
      expect(url.send(:w3c_date, DateTime.new(0))).to eq('0000-01-01T00:00:00+00:00')
    end

    it 'returns strings unmodified' do
      expect(new_url.send(:w3c_date, '2010-01-01')).to eq('2010-01-01')
    end

    it 'tries to convert to utc' do
      time = Time.at(0)
      expect(time).to receive(:respond_to?).and_return(false)
      expect(time).to receive(:respond_to?).and_return(true)
      expect(new_url.send(:w3c_date, time)).to eq('1970-01-01T00:00:00+00:00')
    end

    it 'includes timezone for objects which do not respond to iso8601 or utc' do
      time = Time.at(0)
      expect(time).to receive(:respond_to?).and_return(false)
      expect(time).to receive(:respond_to?).and_return(false)
      expect(time).to receive(:strftime).and_return(+'+0800', '1970-01-01T00:00:00')
      expect(new_url.send(:w3c_date, time)).to eq('1970-01-01T00:00:00+08:00')
    end

    it 'supports integers' do
      expect(new_url.send(:w3c_date, Time.at(0).to_i)).to eq('1970-01-01T00:00:00+00:00')
    end
  end

  describe 'yes_or_no' do
    it 'recognizes truthy values' do
      expect(new_url.send(:yes_or_no, 1)).to eq('yes')
      expect(new_url.send(:yes_or_no, 0)).to eq('yes')
      expect(new_url.send(:yes_or_no, 'yes')).to eq('yes')
      expect(new_url.send(:yes_or_no, 'Yes')).to eq('yes')
      expect(new_url.send(:yes_or_no, 'YES')).to eq('yes')
      expect(new_url.send(:yes_or_no, true)).to eq('yes')
      expect(new_url.send(:yes_or_no, Object.new)).to eq('yes')
    end

    it 'recognizes falsy values' do
      expect(new_url.send(:yes_or_no, nil)).to   eq('no')
      expect(new_url.send(:yes_or_no, 'no')).to  eq('no')
      expect(new_url.send(:yes_or_no, 'No')).to  eq('no')
      expect(new_url.send(:yes_or_no, 'NO')).to  eq('no')
      expect(new_url.send(:yes_or_no, false)).to eq('no')
    end

    it 'raises on unrecognized strings' do
      expect { new_url.send(:yes_or_no, 'dunno')  }.to raise_error(ArgumentError)
      expect { new_url.send(:yes_or_no, 'yessir') }.to raise_error(ArgumentError)
    end
  end

  describe 'yes_or_no_with_default' do
    it 'uses the default if the value is nil' do
      url = new_url
      expect(url).to receive(:yes_or_no).with(true).and_return('surely')
      expect(url.send(:yes_or_no_with_default, nil, true)).to eq('surely')
    end

    it 'uses the value if it is not nil' do
      url = new_url
      expect(url).to receive(:yes_or_no).with('surely').and_return('absolutely')
      expect(url.send(:yes_or_no_with_default, 'surely', true)).to eq('absolutely')
    end
  end

  describe 'format_float' do
    it 'does not modify if a string' do
      expect(new_url.send(:format_float, '0.4')).to eq('0.4')
    end

    it 'rounds to one decimal place' do
      url = new_url
      expect(url.send(:format_float, 0.499999)).to eq('0.5')
      expect(url.send(:format_float, 3.444444)).to eq('3.4')
    end
  end

  describe 'expires' do
    let(:url)  { described_class.new('/path', host: 'http://example.com', expires: time) }
    let(:time) { Time.at(0).utc }

    it 'includes the option' do
      expect(url[:expires]).to eq(time)
    end

    it 'formats it and include it in the XML' do
      xml = url.to_xml
      doc = Nokogiri::XML("<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{xml}</root>")
      expect(doc.css('url expires').text).to eq(url.send(:w3c_date, time))
    end
  end

  describe 'alternates' do
    context 'when alternate href is a relative path' do
      let(:url) do
        described_class.new(
          '/page',
          host: 'http://example.com',
          alternate: { href: '/es/page', lang: :es }
        )
      end

      it 'prepends the host to the href' do
        xml = url.to_xml
        doc = Nokogiri::XML(
          "<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{xml}</root>"
        )
        link = doc.xpath('//xhtml:link', 'xhtml' => 'http://www.w3.org/1999/xhtml').first
        expect(link['href']).to eq('http://example.com/es/page')
      end
    end

    context 'when host has a subpath prefix' do
      let(:url) do
        described_class.new(
          '/page',
          host: 'http://example.com/app/',
          alternate: { href: '/es/page', lang: :es }
        )
      end

      it 'resolves the href relative to the host root' do
        xml = url.to_xml
        doc = Nokogiri::XML(
          "<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{xml}</root>"
        )
        link = doc.xpath('//xhtml:link', 'xhtml' => 'http://www.w3.org/1999/xhtml').first
        expect(link['href']).to eq('http://example.com/es/page')
      end
    end

    context 'when alternate href is already absolute' do
      let(:url) do
        described_class.new(
          '/page',
          host: 'http://example.com',
          alternate: { href: 'https://es.example.com/page', lang: :es }
        )
      end

      it 'leaves the href unchanged' do
        xml = url.to_xml
        doc = Nokogiri::XML(
          "<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{xml}</root>"
        )
        link = doc.xpath('//xhtml:link', 'xhtml' => 'http://www.w3.org/1999/xhtml').first
        expect(link['href']).to eq('https://es.example.com/page')
      end
    end
  end
end
