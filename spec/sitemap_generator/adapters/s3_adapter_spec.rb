# encoding: UTF-8

require 'spec_helper'

describe SitemapGenerator::S3Adapter do

  let(:location) { SitemapGenerator::SitemapLocation.new(:namer => SitemapGenerator::SitemapNamer.new(:sitemap), :public_path => 'tmp/', :sitemaps_path => 'test/', :host => 'http://example.com/') }
  let(:directory) { stub(:files => stub(:create)) }
  let(:directories) { stub(:directories => stub(:new => directory)) }

  before do
  	Fog::Storage.stubs(:new => directories)
  end

  it 'should create the file in S3 with a single operation' do
    subject.write(location, 'payload')
  end
end
