require 'spec_helper'

RSpec.describe SitemapGenerator::Utilities do

  describe 'assert_valid_keys' do
    it 'should raise error on invalid keys' do
      expect {
        SitemapGenerator::Utilities.assert_valid_keys({ :name => 'Rob', :years => '28' }, :name, :age)
      }.to raise_exception(ArgumentError)
      expect {
        SitemapGenerator::Utilities.assert_valid_keys({ :name => 'Rob', :age => '28' }, 'name', 'age')
      }.to raise_exception(ArgumentError)
    end

    it 'should not raise error on valid keys' do
      expect {
        SitemapGenerator::Utilities.assert_valid_keys({ :name => 'Rob', :age => '28' }, :name, :age)
      }.not_to raise_exception

      expect {
        SitemapGenerator::Utilities.assert_valid_keys({ :name => 'Rob' }, :name, :age)
      }.not_to raise_exception
    end
  end

  describe 'titleize' do
    it 'should titleize words and replace underscores' do
      expect(SitemapGenerator::Utilities.titleize('google')).to eq('Google')
      expect(SitemapGenerator::Utilities.titleize('amy_and_jon')).to eq('Amy And Jon')
    end
  end

  describe 'truthy?' do
    it 'should be truthy' do
      ['1', 1, 't', 'true', true].each do |value|
        expect(SitemapGenerator::Utilities.truthy?(value)).to be(true)
      end
      expect(SitemapGenerator::Utilities.truthy?(nil)).to be(false)
    end
  end

  describe 'falsy?' do
    it 'should be falsy' do
      ['0', 0, 'f', 'false', false].each do |value|
        expect(SitemapGenerator::Utilities.falsy?(value)).to be(true)
      end
      expect(SitemapGenerator::Utilities.falsy?(nil)).to be(false)
    end
  end

  describe 'as_array' do
    it 'should return an array unchanged' do
      expect(SitemapGenerator::Utilities.as_array([])).to eq([])
      expect(SitemapGenerator::Utilities.as_array([1])).to eq([1])
      expect(SitemapGenerator::Utilities.as_array([1,2,3])).to eq([1,2,3])
    end

    it 'should return empty array on nil' do
      expect(SitemapGenerator::Utilities.as_array(nil)).to eq([])
    end

    it 'should make array of item otherwise' do
      expect(SitemapGenerator::Utilities.as_array('')).to eq([''])
      expect(SitemapGenerator::Utilities.as_array(1)).to eq([1])
      expect(SitemapGenerator::Utilities.as_array('hello')).to eq(['hello'])
      expect(SitemapGenerator::Utilities.as_array({})).to eq([{}])
    end
  end

  describe 'append_slash' do
    it 'should yield the expect result' do
      expect(SitemapGenerator::Utilities.append_slash('')).to eq('')
      expect(SitemapGenerator::Utilities.append_slash(nil)).to eq('')
      expect(SitemapGenerator::Utilities.append_slash(Pathname.new(''))).to eq('')
      expect(SitemapGenerator::Utilities.append_slash('tmp')).to eq('tmp/')
      expect(SitemapGenerator::Utilities.append_slash(Pathname.new('tmp'))).to eq('tmp/')
      expect(SitemapGenerator::Utilities.append_slash('tmp/')).to eq('tmp/')
      expect(SitemapGenerator::Utilities.append_slash(Pathname.new('tmp/'))).to eq('tmp/')
    end
  end

  describe 'ellipsis' do
    it 'should not modify when less than or equal to max' do
      (1..10).each do |i|
        string = 'a'*i
        expect(SitemapGenerator::Utilities.ellipsis(string, 10)).to eq(string)
      end
    end

    it 'should replace last 3 characters with ellipsis when greater than max' do
      (1..5).each do |i|
        string = 'aaaaa' + 'a'*i
        expect(SitemapGenerator::Utilities.ellipsis(string, 5)).to eq('aa...')
      end
    end

    it 'should not freak out when string too small' do
      expect(SitemapGenerator::Utilities.ellipsis('a', 1)).to eq('a')
      expect(SitemapGenerator::Utilities.ellipsis('aa', 1)).to eq('...')
      expect(SitemapGenerator::Utilities.ellipsis('aaa', 1)).to eq('...')
    end
  end
end
