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

    it 'tries to convert to utc' do
      time = Time.at(0)
      allow(time).to receive(:respond_to?).and_return(false, true)
      expect(new_url.send(:w3c_date, time)).to eq('1970-01-01T00:00:00+00:00')
    end

    it 'includes timezone for objects which do not respond to iso8601 or utc', :aggregate_failures do
      time = Time.at(0)
      allow(time).to receive(:respond_to?).and_return(false)
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

    it 'raises on unrecognized strings' do
      %w[dunno yessir].each { |value| expect { new_url.send(:yes_or_no, value) }.to raise_error(ArgumentError) }
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

    it 'rounds to one decimal place' do
      url = new_url
      expect(url.send(:format_float, 0.499999)).to eq('0.5')
    end

    it 'rounds 3.444444 down to 3.4' do
      url = new_url
      expect(url.send(:format_float, 3.444444)).to eq('3.4')
    end
  end

  describe '#initialize' do
    context 'when lastmod is not given' do
      let(:frozen_time) { Time.at(1_000_000).utc }

      before do
        allow(SitemapGenerator::Utilities).to receive(:current_time).and_return(frozen_time)
      end

      it 'defaults to Utilities.current_time' do
        url = described_class.new('/home', host: 'http://example.com')
        expect(url[:lastmod]).to eq(frozen_time)
      end
    end

    context 'when path contains non-ASCII characters' do
      it 'percent-encodes non-ASCII characters in the loc' do
        url = described_class.new('/RFC3986ü中文', host: 'http://example.com', lastmod: nil)
        expect(url[:loc]).to eq('http://example.com/RFC3986%C3%BC%E4%B8%AD%E6%96%87')
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

  describe 'alternates' do
    let(:xml_doc) do
      Nokogiri::XML(
        "<root xmlns='http://www.sitemaps.org/schemas/sitemap/0.9' xmlns:xhtml='http://www.w3.org/1999/xhtml'>#{url.to_xml}</root>"
      )
    end
    let(:alternate_link) { xml_doc.xpath('//xhtml:link', 'xhtml' => 'http://www.w3.org/1999/xhtml').first }

    context 'when alternate href is a relative path' do
      let(:url) do
        described_class.new(
          '/page',
          host: 'http://example.com',
          alternate: { href: '/es/page', lang: :es }
        )
      end

      it 'prepends the host to the href' do
        expect(alternate_link['href']).to eq('http://example.com/es/page')
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
        expect(alternate_link['href']).to eq('http://example.com/es/page')
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
        expect(alternate_link['href']).to eq('https://es.example.com/page')
      end
    end
  end

  describe '#to_xml' do
    # This is the exact output of the previous Builder::XmlMarkup based implementation,
    # so this spec guards against any change in the generated XML.
    let(:expected_xml) do
      [
        '<url>',
        '<loc>http://example.com/page?a=1&amp;b=2</loc>',
        '<lastmod>2024-01-02T03:04:05+00:00</lastmod>',
        '<expires>2025-06-07</expires>',
        '<changefreq>daily</changefreq>',
        '<priority>0.8</priority>',
        '<news:news>',
        '<news:publication><news:name>Example &amp; Co</news:name><news:language>en</news:language></news:publication>',
        '<news:access>Subscription</news:access>',
        '<news:genres>Blog</news:genres>',
        '<news:publication_date>2024-01-02T00:00:00+00:00</news:publication_date>',
        '<news:title>A &lt;b&gt;bold&lt;/b&gt; title</news:title>',
        '<news:keywords>a, b</news:keywords>',
        '<news:stock_tickers>NASDAQ:A</news:stock_tickers>',
        '</news:news>',
        '<image:image>',
        '<image:loc>http://example.com/image.jpg</image:loc>',
        '<image:caption>Café "au lait"</image:caption>',
        '<image:geo_location>Paris</image:geo_location>',
        "<image:title>Tab\there</image:title>",
        '<image:license>https://example.com/license</image:license>',
        '</image:image>',
        '<video:video>',
        '<video:thumbnail_loc>http://example.com/thumb.jpg</video:thumbnail_loc>',
        '<video:title>Video</video:title>',
        "<video:description>Line 1\nLine 2 €</video:description>",
        '<video:content_loc>http://example.com/video.mp4</video:content_loc>',
        '<video:player_loc allow_embed="no" autoplay="ap=1">http://example.com/player?id=1&amp;autoplay=0</video:player_loc>',
        '<video:duration>600</video:duration>',
        '<video:expiration_date>2030-01-01T00:00:00+00:00</video:expiration_date>',
        '<video:rating>4.2</video:rating>',
        '<video:view_count>10</video:view_count>',
        '<video:publication_date>2024-01-02T00:00:00+00:00</video:publication_date>',
        '<video:tag>one</video:tag><video:tag>two</video:tag><video:tag>three</video:tag>',
        '<video:category>Cat</video:category>',
        '<video:family_friendly>yes</video:family_friendly>',
        '<video:gallery_loc title="Gallery &quot;1&quot;">http://example.com/gallery</video:gallery_loc>',
        '<video:price currency="EUR" type="own" resolution="HD">1.99</video:price>',
        '<video:uploader info="http://example.com/u">Uploader</video:uploader>',
        '<video:live>no</video:live>',
        '<video:requires_subscription>yes</video:requires_subscription>',
        '</video:video>',
        '<xhtml:link rel="alternate nofollow" href="http://example.com/fr/page" hreflang="fr" ' \
        'media="only screen and (max-width: 640px)"/>',
        '<mobile:mobile/>',
        '<pagemap:PageMap><pagemap:DataObject type="document" id="hibachi">',
        '<pagemap:Attribute name="name">Dragon &amp; &lt;Tiger&gt;</pagemap:Attribute>',
        '</pagemap:DataObject></pagemap:PageMap>',
        '</url>'
      ].join
    end

    let(:video) do
      {
        thumbnail_loc: 'http://example.com/thumb.jpg', title: 'Video',
        description: "Line 1\nLine 2 \u0080", # U+0080 is mapped to € (CP1252 fix-up)
        content_loc: 'http://example.com/video.mp4', player_loc: 'http://example.com/player?id=1&autoplay=0',
        allow_embed: false, autoplay: 'ap=1', duration: 600, expiration_date: Time.utc(2030, 1, 1), rating: 4.25,
        view_count: 10, publication_date: Time.utc(2024, 1, 2), tags: %w[one two], tag: 'three', category: 'Cat',
        family_friendly: true, gallery_loc: 'http://example.com/gallery', gallery_title: 'Gallery "1"',
        price: 1.99, price_currency: 'EUR', price_type: :own, price_resolution: 'HD', uploader: 'Uploader',
        uploader_info: 'http://example.com/u', live: false, requires_subscription: 'yes'
      }
    end

    let(:url) do
      described_class.new(
        '/page?a=1&b=2',
        host: 'http://example.com', lastmod: Time.utc(2024, 1, 2, 3, 4, 5), expires: Date.new(2025, 6, 7),
        changefreq: 'daily', priority: 0.8, mobile: true, video: video,
        news: {
          publication_name: 'Example & Co', publication_language: 'en', publication_date: Time.utc(2024, 1, 2),
          genres: 'Blog', access: 'Subscription', title: 'A <b>bold</b> title', keywords: 'a, b',
          stock_tickers: 'NASDAQ:A'
        },
        images: [{
          loc: '/image.jpg', caption: 'Café "au lait"', geo_location: 'Paris', title: "Tab\there",
          license: 'https://example.com/license'
        }],
        alternates: [{ href: '/fr/page', lang: 'fr', nofollow: true, media: 'only screen and (max-width: 640px)' }],
        pagemap: {
          dataobjects: [{ type: 'document', id: 'hibachi', attributes: [{ name: 'name', value: 'Dragon & <Tiger>' }] }]
        }
      )
    end

    it 'generates the same XML as Builder::XmlMarkup' do
      expect(url.to_xml).to eq(expected_xml)
    end

    context 'when given a Builder::XmlMarkup' do
      it 'appends the XML to the builder' do
        builder = Builder::XmlMarkup.new
        builder.urlset { url.to_xml(builder) }
        expect(builder.target!).to eq("<urlset>#{expected_xml}</urlset>")
      end
    end

    context 'when the url has no optional elements' do
      let(:url) { described_class.new('/', host: 'http://example.com', lastmod: nil, changefreq: nil, priority: nil) }

      it 'generates only the loc element' do
        expect(url.to_xml).to eq('<url><loc>http://example.com</loc></url>')
      end
    end
  end
end
