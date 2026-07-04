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

  it 'defaults lastmod to the last modified date for sitemap files' do
    lastmod = (Time.now - 1_209_600)
    allow(sitemap_file).to receive(:lastmod).and_return(lastmod)
    url = described_class.new(sitemap_file)
    expect(url[:lastmod]).to eq(lastmod)
  end

  context 'when given string option keys' do
    let(:url) { new_url('/home', 'host' => 'http://string.com', 'priority' => 1) }

    it 'converts :priority' do
      expect(url[:priority]).to eq(1)
    end

    it 'converts :host' do
      expect(url[:host]).to eq('http://string.com')
    end
  end

  it 'supports subdirectory routing with a leading slash' do
    url = described_class.new('/profile', host: 'http://example.com/subdir/')
    expect(url[:loc]).to eq('http://example.com/subdir/profile')
  end

  it 'supports subdirectory routing without a leading slash' do
    url = described_class.new('profile', host: 'http://example.com/subdir/')
    expect(url[:loc]).to eq('http://example.com/subdir/profile')
  end

  it 'supports deep subdirectory routing with trailing slash' do
    url = described_class.new('/deep/profile/', host: 'http://example.com/subdir/')
    expect(url[:loc]).to eq('http://example.com/subdir/deep/profile/')
  end

  it 'supports deep subdirectory routing without trailing slash' do
    url = described_class.new('/deep/profile', host: 'http://example.com/subdir')
    expect(url[:loc]).to eq('http://example.com/subdir/deep/profile')
  end

  it 'supports deep subdirectory routing without leading slash' do
    url = described_class.new('deep/profile', host: 'http://example.com/subdir')
    expect(url[:loc]).to eq('http://example.com/subdir/deep/profile')
  end

  it 'supports deep subdirectory routing without leading slash with trailing slash' do
    url = described_class.new('deep/profile/', host: 'http://example.com/subdir/')
    expect(url[:loc]).to eq('http://example.com/subdir/deep/profile/')
  end

  it 'supports root path with subdirectory host' do
    url = described_class.new('/', host: 'http://example.com/subdir/')
    expect(url[:loc]).to eq('http://example.com/subdir/')
  end

  it 'does not fail on a nil path segment' do
    url = described_class.new(nil, host: 'http://example.com')
    expect(url[:loc]).to eq('http://example.com')
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
    it 'converts a Date to W3C format' do
      expect(new_url.send(:w3c_date, Date.new(0))).to eq('0000-01-01')
    end

    it 'converts a Time to W3C format' do
      expect(new_url.send(:w3c_date, Time.at(0).utc)).to eq('1970-01-01T00:00:00+00:00')
    end

    it 'converts a DateTime to W3C format' do
      expect(new_url.send(:w3c_date, DateTime.new(0))).to eq('0000-01-01T00:00:00+00:00')
    end

    it 'returns strings unmodified' do
      expect(new_url.send(:w3c_date, '2010-01-01')).to eq('2010-01-01')
    end

    it 'tries to convert to utc' do # rubocop:disable RSpec/MultipleExpectations
      time = Time.at(0)
      expect(time).to receive(:respond_to?).and_return(false) # rubocop:disable RSpec/StubbedMock, RSpec/MessageSpies
      expect(time).to receive(:respond_to?).and_return(true) # rubocop:disable RSpec/StubbedMock, RSpec/MessageSpies
      expect(new_url.send(:w3c_date, time)).to eq('1970-01-01T00:00:00+00:00')
    end

    it 'includes timezone for objects which do not respond to iso8601 or utc' do # rubocop:disable RSpec/MultipleExpectations
      time = Time.at(0)
      expect(time).to receive(:respond_to?).and_return(false) # rubocop:disable RSpec/StubbedMock, RSpec/MessageSpies
      expect(time).to receive(:respond_to?).and_return(false) # rubocop:disable RSpec/StubbedMock, RSpec/MessageSpies
      expect(time).to receive(:strftime).and_return(+'+0800', '1970-01-01T00:00:00') # rubocop:disable RSpec/MessageSpies
      expect(new_url.send(:w3c_date, time)).to eq('1970-01-01T00:00:00+08:00')
    end

    it 'supports integers' do
      expect(new_url.send(:w3c_date, Time.at(0).to_i)).to eq('1970-01-01T00:00:00+00:00')
    end
  end

  describe 'yes_or_no' do
    it 'recognizes 1 as yes' do
      expect(new_url.send(:yes_or_no, 1)).to eq('yes')
    end

    it 'recognizes 0 as yes' do
      expect(new_url.send(:yes_or_no, 0)).to eq('yes')
    end

    it 'recognizes string "yes" as yes' do
      expect(new_url.send(:yes_or_no, 'yes')).to eq('yes')
    end

    it 'recognizes string "Yes" as yes' do
      expect(new_url.send(:yes_or_no, 'Yes')).to eq('yes')
    end

    it 'recognizes string "YES" as yes' do
      expect(new_url.send(:yes_or_no, 'YES')).to eq('yes')
    end

    it 'recognizes true as yes' do
      expect(new_url.send(:yes_or_no, true)).to eq('yes')
    end

    it 'recognizes an object as yes' do
      expect(new_url.send(:yes_or_no, Object.new)).to eq('yes')
    end

    it 'recognizes nil as no' do
      expect(new_url.send(:yes_or_no, nil)).to eq('no')
    end

    it 'recognizes string "no" as no' do
      expect(new_url.send(:yes_or_no, 'no')).to eq('no')
    end

    it 'recognizes string "No" as no' do
      expect(new_url.send(:yes_or_no, 'No')).to eq('no')
    end

    it 'recognizes string "NO" as no' do
      expect(new_url.send(:yes_or_no, 'NO')).to eq('no')
    end

    it 'recognizes false as no' do
      expect(new_url.send(:yes_or_no, false)).to eq('no')
    end

    it 'raises on "dunno"' do
      expect { new_url.send(:yes_or_no, 'dunno') }.to raise_error(ArgumentError)
    end

    it 'raises on "yessir"' do
      expect { new_url.send(:yes_or_no, 'yessir') }.to raise_error(ArgumentError)
    end
  end

  describe 'yes_or_no_with_default' do
    it 'uses the default if the value is nil' do
      url = new_url
      allow(url).to receive(:yes_or_no).with(true).and_return('surely')
      expect(url.send(:yes_or_no_with_default, nil, true)).to eq('surely')
    end

    it 'uses the value if it is not nil' do
      url = new_url
      allow(url).to receive(:yes_or_no).with('surely').and_return('absolutely')
      expect(url.send(:yes_or_no_with_default, 'surely', true)).to eq('absolutely')
    end
  end

  describe 'format_float' do
    it 'does not modify if a string' do
      expect(new_url.send(:format_float, '0.4')).to eq('0.4')
    end

    it 'rounds 0.499999 up to 0.5' do
      url = new_url
      expect(url.send(:format_float, 0.499999)).to eq('0.5')
    end

    it 'rounds 3.444444 down to 3.4' do
      url = new_url
      expect(url.send(:format_float, 3.444444)).to eq('3.4')
    end
  end

  describe '#initialize' do
    context 'lastmod' do
      context 'when Time.zone is available' do
        let(:zone_now) { Time.at(1_000_000).utc }
        let(:mock_zone) { Struct.new(:now).new(zone_now) }

        before do
          allow(Time).to receive(:zone).and_return(mock_zone)
        end

        it 'uses Time.zone.now as the default lastmod' do
          url = described_class.new('/home', host: 'http://example.com')
          expect(url[:lastmod]).to eq(zone_now)
        end
      end

      context 'when Time.zone is nil' do
        before do
          allow(Time).to receive(:zone).and_return(nil)
        end

        it 'falls back to Time.now as the default lastmod' do
          frozen = Time.at(999_999).utc
          allow(Time).to receive(:now).and_return(frozen)
          url = described_class.new('/home', host: 'http://example.com')
          expect(url[:lastmod]).to eq(frozen)
        end
      end

      context 'when Time.zone is not defined (outside Rails)' do
        before do
          Time.singleton_class.class_eval do
            alias_method :__zone_bak__, :zone
            undef_method :zone
          end
        end

        after do
          Time.singleton_class.class_eval do
            alias_method :zone, :__zone_bak__
            remove_method :__zone_bak__
          end
        end

        it 'falls back to Time.now' do
          frozen = Time.at(888_888).utc
          allow(Time).to receive(:now).and_return(frozen)
          url = described_class.new('/home', host: 'http://example.com')
          expect(url[:lastmod]).to eq(frozen)
        end
      end
    end
  end

  describe 'expires' do
    let(:url)  { described_class.new('/path', host: 'http://example.com', expires: time) }
    let(:time) { Time.at(0).utc }

    it 'includes the option' do
      expect(url[:expires]).to eq(time)
    end

    it 'formats it and includes it in the XML' do
      xml = url.to_xml
      doc = Nokogiri::XML("<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{xml}</root>")
      expect(doc.css('url expires').text).to eq(url.send(:w3c_date, time))
    end
  end
end
