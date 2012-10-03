require 'spec_helper'

describe SitemapGenerator::Builder::SitemapUrl do
  let(:loc) {
    SitemapGenerator::SitemapLocation.new(
      :sitemaps_path => 'sitemaps/',
      :public_path => '/public',
      :host => 'http://test.com',
      :namer => SitemapGenerator::SitemapNamer.new(:sitemap)
    )}
  let(:sitemap_file) { SitemapGenerator::Builder::SitemapFile.new(loc) }

  def new_url(*args)
    if args.empty?
      args = ['/home', { :host => 'http://example.com' }]
    end
    SitemapGenerator::Builder::SitemapUrl.new(*args)
  end

  it "should build urls for sitemap files" do
    url = SitemapGenerator::Builder::SitemapUrl.new(sitemap_file)
    url[:loc].should == 'http://test.com/sitemaps/sitemap1.xml.gz'
  end

  it "lastmod should default to the last modified date for sitemap files" do
    lastmod = (Time.now - 1209600)
    sitemap_file.expects(:lastmod).returns(lastmod)
    url = SitemapGenerator::Builder::SitemapUrl.new(sitemap_file)
    url[:lastmod].should == lastmod
  end

  it "should support subdirectory routing" do
    url = SitemapGenerator::Builder::SitemapUrl.new('/profile', :host => 'http://example.com/subdir/')
    url[:loc].should == 'http://example.com/subdir/profile'
    url = SitemapGenerator::Builder::SitemapUrl.new('profile', :host => 'http://example.com/subdir/')
    url[:loc].should == 'http://example.com/subdir/profile'
    url = SitemapGenerator::Builder::SitemapUrl.new('/deep/profile/', :host => 'http://example.com/subdir/')
    url[:loc].should == 'http://example.com/subdir/deep/profile/'
    url = SitemapGenerator::Builder::SitemapUrl.new('/deep/profile', :host => 'http://example.com/subdir')
    url[:loc].should == 'http://example.com/subdir/deep/profile'
    url = SitemapGenerator::Builder::SitemapUrl.new('deep/profile', :host => 'http://example.com/subdir')
    url[:loc].should == 'http://example.com/subdir/deep/profile'
    url = SitemapGenerator::Builder::SitemapUrl.new('deep/profile/', :host => 'http://example.com/subdir/')
    url[:loc].should == 'http://example.com/subdir/deep/profile/'
    url = SitemapGenerator::Builder::SitemapUrl.new('/', :host => 'http://example.com/subdir/')
    url[:loc].should == 'http://example.com/subdir/'
  end

  it "should not fail on a nil path segment" do
    lambda do
      SitemapGenerator::Builder::SitemapUrl.new(nil, :host => 'http://example.com')[:loc].should == 'http://example.com'
    end.should_not raise_error
  end

  it "should support a :videos option" do
    loc = SitemapGenerator::Builder::SitemapUrl.new('', :host => 'http://test.com', :videos => [1,2,3])
    loc[:videos].should == [1,2,3]
  end

  it "should support a singular :video option" do
    loc = SitemapGenerator::Builder::SitemapUrl.new('', :host => 'http://test.com', :video => 1)
    loc[:videos].should == [1]
  end

  it "should support an array :video option" do
    loc = SitemapGenerator::Builder::SitemapUrl.new('', :host => 'http://test.com', :video => [1,2], :videos => [3,4])
    loc[:videos].should == [3,4,1,2]
  end

  it "should support a :alternates option" do
    loc = SitemapGenerator::Builder::SitemapUrl.new('', :host => 'http://test.com', :alternates => [1,2,3])
    loc[:alternates].should == [1,2,3]
  end

  it "should support a singular :alternate option" do
    loc = SitemapGenerator::Builder::SitemapUrl.new('', :host => 'http://test.com', :alternate => 1)
    loc[:alternates].should == [1]
  end

  it "should support an array :alternate option" do
    loc = SitemapGenerator::Builder::SitemapUrl.new('', :host => 'http://test.com', :alternate => [1,2], :alternates => [3,4])
    loc[:alternates].should == [3,4,1,2]
  end

  it "should not fail if invalid characters are used in the URL" do
    special = ':$&+,;:=?@'
    url = SitemapGenerator::Builder::SitemapUrl.new("/#{special}", :host => "http://example.com/#{special}/")
    url[:loc].should == "http://example.com/#{special}/#{special}"
  end

  describe "w3c_date" do
    it "should convert dates and times to W3C format" do
      url = new_url
      url.send(:w3c_date, Date.new(0)).should == '0000-01-01'
      url.send(:w3c_date, Time.at(0).utc).should == '1970-01-01T00:00:00+00:00'
      url.send(:w3c_date, DateTime.new(0)).should == '0000-01-01T00:00:00+00:00'
    end

    it "should return strings unmodified" do
      new_url.send(:w3c_date, '2010-01-01').should == '2010-01-01'
    end

    it "should try to convert to utc" do
      time = Time.at(0)
      time.expects(:respond_to?).times(2).returns(false, true) # iso8601, utc
      new_url.send(:w3c_date, time).should == '1970-01-01T00:00:00+00:00'
    end

    it "should include timezone for objects which do not respond to iso8601 or utc" do
      time = Time.at(0)
      time.expects(:respond_to?).times(2).returns(false, false) # iso8601, utc
      time.expects(:strftime).times(2).returns('+0800', '1970-01-01T00:00:00')
      new_url.send(:w3c_date, time).should == '1970-01-01T00:00:00+08:00'
    end
  end

  describe "yes_or_no" do
    it "should recognize truthy values" do
      new_url.send(:yes_or_no, 1).should == 'yes'
      new_url.send(:yes_or_no, 0).should == 'yes'
      new_url.send(:yes_or_no, 'yes').should == 'yes'
      new_url.send(:yes_or_no, 'Yes').should == 'yes'
      new_url.send(:yes_or_no, 'YES').should == 'yes'
      new_url.send(:yes_or_no, true).should == 'yes'
      new_url.send(:yes_or_no, Object.new).should == 'yes'
    end

    it "should recognize falsy values" do
      new_url.send(:yes_or_no, nil).should   == 'no'
      new_url.send(:yes_or_no, 'no').should  == 'no'
      new_url.send(:yes_or_no, 'No').should  == 'no'
      new_url.send(:yes_or_no, 'NO').should  == 'no'
      new_url.send(:yes_or_no, false).should == 'no'
    end

    it "should raise on unrecognized strings" do
      lambda { new_url.send(:yes_or_no, 'dunno')  }.should raise_error(ArgumentError)
      lambda { new_url.send(:yes_or_no, 'yessir') }.should raise_error(ArgumentError)
    end
  end

  describe "yes_or_no_with_default" do
    it "should use the default if the value is nil" do
      url = new_url
      url.expects(:yes_or_no).with(true).returns('surely')
      url.send(:yes_or_no_with_default, nil, true).should == 'surely'
    end

    it "should use the value if it is not nil" do
      url = new_url
      url.expects(:yes_or_no).with('surely').returns('absolutely')
      url.send(:yes_or_no_with_default, 'surely', true).should == 'absolutely'
    end
  end

  describe "format_float" do
    it "should not modify if a string" do
      new_url.send(:format_float, '0.4').should == '0.4'
    end

    it "should round to one decimal place" do
      url = new_url
      url.send(:format_float, 0.499999).should == '0.5'
      url.send(:format_float, 3.444444).should == '3.4'
    end
  end
end
