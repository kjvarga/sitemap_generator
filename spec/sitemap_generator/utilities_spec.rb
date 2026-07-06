# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe SitemapGenerator::Utilities do
  describe 'assert_valid_keys' do
    it 'raises error on invalid keys' do
      expect do
        described_class.assert_valid_keys({ name: 'Rob', years: '28' }, :name, :age)
      end.to raise_exception(ArgumentError)
      expect do
        described_class.assert_valid_keys({ name: 'Rob', age: '28' }, 'name', 'age')
      end.to raise_exception(ArgumentError)
    end

    it 'does not raise error on valid keys' do
      expect do
        described_class.assert_valid_keys({ name: 'Rob', age: '28' }, :name, :age)
      end.not_to raise_exception

      expect do
        described_class.assert_valid_keys({ name: 'Rob' }, :name, :age)
      end.not_to raise_exception
    end
  end

  describe 'titleize' do
    it 'titleizes words and replace underscores' do
      expect(described_class.titleize('google')).to eq('Google')
      expect(described_class.titleize('amy_and_jon')).to eq('Amy And Jon')
    end
  end

  describe 'truthy?' do
    it 'is truthy' do
      ['1', 1, 't', 'true', true].each do |value|
        expect(described_class.truthy?(value)).to be(true)
      end
      expect(described_class.truthy?(nil)).to be(false)
    end
  end

  describe 'falsy?' do
    it 'is falsy' do
      ['0', 0, 'f', 'false', false].each do |value|
        expect(described_class.falsy?(value)).to be(true)
      end
      expect(described_class.falsy?(nil)).to be(false)
    end
  end

  describe 'as_array' do
    it 'returns an array unchanged' do
      expect(described_class.as_array([])).to eq([])
      expect(described_class.as_array([1])).to eq([1])
      expect(described_class.as_array([1, 2, 3])).to eq([1, 2, 3])
    end

    it 'returns empty array on nil' do
      expect(described_class.as_array(nil)).to eq([])
    end

    it 'makes array of item otherwise' do
      expect(described_class.as_array('')).to eq([''])
      expect(described_class.as_array(1)).to eq([1])
      expect(described_class.as_array('hello')).to eq(['hello'])
      expect(described_class.as_array({})).to eq([{}])
    end
  end

  describe 'append_slash' do
    it 'yields the expect result' do
      expect(described_class.append_slash('')).to eq('')
      expect(described_class.append_slash(nil)).to eq('')
      expect(described_class.append_slash(Pathname.new(''))).to eq('')
      expect(described_class.append_slash('tmp')).to eq('tmp/')
      expect(described_class.append_slash(Pathname.new('tmp'))).to eq('tmp/')
      expect(described_class.append_slash('tmp/')).to eq('tmp/')
      expect(described_class.append_slash(Pathname.new('tmp/'))).to eq('tmp/')
    end
  end

  describe 'ellipsis' do
    context 'when string length is less than or equal to max' do
      it 'returns the string unchanged' do
        (1..10).each do |i|
          string = 'a' * i
          expect(described_class.ellipsis(string, 10)).to eq(string)
        end
      end
    end

    context 'when string length is greater than max' do
      it 'replaces the last 3 characters with ellipsis' do
        (1..5).each do |i|
          string = "aaaaa#{'a' * i}"
          expect(described_class.ellipsis(string, 5)).to eq('aa...')
        end
      end
    end

    context 'when string is shorter than the ellipsis itself' do
      it 'returns ellipsis' do
        expect(described_class.ellipsis('a', 1)).to eq('a')
        expect(described_class.ellipsis('aa', 1)).to eq('...')
        expect(described_class.ellipsis('aaa', 1)).to eq('...')
      end
    end
  end

  describe '.clean_files' do
    let(:tmp_dir) { Dir.mktmpdir }

    before do
      SitemapGenerator::Sitemap.reset!
      SitemapGenerator::Sitemap.public_path = tmp_dir
    end

    after do
      SitemapGenerator::Sitemap.reset!
      FileUtils.rm_rf(tmp_dir)
    end

    context 'when sitemaps are compressed' do
      it 'removes .xml.gz files from the configured directory' do
        FileUtils.touch(File.join(tmp_dir, 'sitemap.xml.gz'))
        FileUtils.touch(File.join(tmp_dir, 'sitemap1.xml.gz'))
        described_class.clean_files
        expect(Dir["#{tmp_dir}/sitemap*.xml.gz"]).to be_empty
      end
    end

    context 'when sitemaps are uncompressed' do
      it 'removes .xml files from the configured directory' do
        FileUtils.touch(File.join(tmp_dir, 'sitemap.xml'))
        FileUtils.touch(File.join(tmp_dir, 'sitemap1.xml'))
        described_class.clean_files
        expect(Dir["#{tmp_dir}/sitemap*.xml"]).to be_empty
      end
    end

    context 'when a custom sitemaps_path is configured' do
      let(:sub_dir) { File.join(tmp_dir, 'sitemaps', 'en') }

      before do
        FileUtils.mkdir_p(sub_dir)
        SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/en'
      end

      it 'removes files from the configured subdirectory' do
        FileUtils.touch(File.join(sub_dir, 'sitemap.xml.gz'))
        described_class.clean_files
        expect(Dir["#{sub_dir}/sitemap*.xml.gz"]).to be_empty
      end

      it 'does not remove files outside the configured subdirectory' do
        FileUtils.touch(File.join(tmp_dir, 'sitemap.xml.gz'))
        described_class.clean_files
        expect(File.exist?(File.join(tmp_dir, 'sitemap.xml.gz'))).to be(true)
      end
    end
  end
  describe '.current_time' do
    context 'when Time.zone is available' do
      let(:zone_now) { Time.at(1_000_000).utc }
      let(:mock_zone) { Struct.new(:now).new(zone_now) }

      before { allow(Time).to receive(:zone).and_return(mock_zone) }

      it 'returns Time.zone.now' do
        expect(described_class.current_time).to eq(zone_now)
      end
    end

    context 'when Time.zone is nil' do
      let(:frozen) { Time.at(999_999).utc }

      before do
        allow(Time).to receive(:zone).and_return(nil)
        allow(Time).to receive(:now).and_return(frozen)
      end

      it 'returns Time.now' do
        expect(described_class.current_time).to eq(frozen)
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

      it 'returns Time.now' do
        frozen = Time.at(888_888).utc
        allow(Time).to receive(:now).and_return(frozen)
        expect(described_class.current_time).to eq(frozen)
      end
    end
  end
end