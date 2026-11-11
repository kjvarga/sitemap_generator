# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SitemapGenerator::FileAdapter' do
  let(:location) { SitemapGenerator::SitemapLocation.new }
  let(:adapter)  { SitemapGenerator::FileAdapter.new }

  describe 'write' do
    it 'gzips contents if filename ends in .gz', :aggregate_failures do
      expect(location).to receive(:filename).and_return('sitemap.xml.gz').twice
      expect(adapter).to receive(:gzip)
      adapter.write(location, 'data')
    end

    it 'does not gzip contents if filename does not end in .gz', :aggregate_failures do
      expect(location).to receive(:filename).and_return('sitemap.xml').twice
      expect(adapter).not_to receive(:gzip)
      adapter.write(location, 'data')
    end
  end

  describe 'write to a directory' do
    let(:dir) { Dir.mktmpdir }
    let(:location) { SitemapGenerator::SitemapLocation.new(public_path: dir, filename: 'sitemap.xml') }
    let(:path) { File.join(dir, 'sitemap.xml') }

    after { FileUtils.remove_entry(dir) }

    it 'writes the file without leaving temporary files', :aggregate_failures do
      adapter.write(location, 'data')
      expect(File.read(path)).to eq('data')
      expect(Dir.children(dir)).to eq(['sitemap.xml'])
    end

    context 'when writing fails' do
      before do
        File.write(path, 'previous')
        allow(adapter).to receive(:gzip).and_raise(Errno::ENOSPC)
        allow(location).to receive(:gzip?).and_return(true)
      end

      it 'keeps the previous file and removes the temporary file', :aggregate_failures do
        expect { adapter.write(location, 'data') }.to raise_error(Errno::ENOSPC)
        expect(File.read(path)).to eq('previous')
        expect(Dir.children(dir)).to eq(['sitemap.xml'])
      end
    end

    context 'when the file is a symlink' do
      let(:target) { File.join(dir, 'shared', 'sitemap.xml') }

      before do
        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, 'previous')
        File.symlink(target, path)
      end

      it 'writes to the target and keeps the symlink', :aggregate_failures do
        adapter.write(location, 'data')
        expect(File.symlink?(path)).to be(true)
        expect(File.read(target)).to eq('data')
        expect(Dir.children(File.dirname(target))).to eq(['sitemap.xml'])
      end
    end

    context 'when the file is a symlink to a file that does not exist yet' do
      let(:target) { File.join(dir, 'shared', 'sitemap.xml') }

      before do
        FileUtils.mkdir_p(File.dirname(target))
        File.symlink('shared/sitemap.xml', path)
      end

      it 'creates the target and keeps the symlink', :aggregate_failures do
        adapter.write(location, 'data')
        expect(File.symlink?(path)).to be(true)
        expect(File.read(target)).to eq('data')
      end
    end

    context 'when the file is a chain of symlinks' do
      before do
        FileUtils.mkdir_p(File.join(dir, 'shared'))
        File.symlink('shared/sitemap.xml', File.join(dir, 'link.xml'))
        File.symlink('link.xml', path)
      end

      it 'writes to the last target and keeps the symlinks', :aggregate_failures do
        adapter.write(location, 'data')
        expect([File.symlink?(path), File.symlink?(File.join(dir, 'link.xml'))]).to eq([true, true])
        expect(File.read(File.join(dir, 'shared', 'sitemap.xml'))).to eq('data')
      end
    end

    context 'when the file has a custom mode' do
      before do
        File.write(path, 'previous')
        File.chmod(0o640, path)
      end

      it 'keeps the mode' do
        adapter.write(location, 'data')
        expect(File.stat(path).mode & 0o7777).to eq(0o640)
      end
    end
  end
end
