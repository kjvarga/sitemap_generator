# encoding: UTF-8

require 'spec_helper'

# Don't run this test as part of the unit testing suite as we don't want
# Fog to be a dependency of SitemapGenerator core.  This is an integration
# test.  Unfortunately it doesn't really test much, so its usefullness is
# questionable.
describe 'SitemapGenerator::S3Adapter', :integration => true do

  let(:location) { SitemapGenerator::SitemapLocation.new(:namer => SitemapGenerator::SitemapNamer.new(:sitemap), :public_path => 'tmp/', :sitemaps_path => 'test/', :host => 'http://example.com/') }
  let(:directory) { stub(:files => stub(:create)) }
  let(:directories) { stub(:directories => stub(:create => directory)) }

  before do
    SitemapGenerator::S3Adapter # eager load
    Fog::Storage.stubs(:new => directories)
  end

  it 'should create the file in S3 with a single operation' do
    subject.write(location, 'payload')
  end
end
