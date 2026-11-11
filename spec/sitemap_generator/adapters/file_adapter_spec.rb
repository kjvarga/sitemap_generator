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

    context 'when the file is a symlink to a relative target starting with ~' do
      before do
        FileUtils.mkdir_p(File.join(dir, '~'))
        File.symlink('~/sitemap.xml', path)
      end

      it 'writes to the target in the same directory' do
        adapter.write(location, 'data')
        expect(File.read(File.join(dir, '~', 'sitemap.xml'))).to eq('data')
      end
    end

    context 'when the directory is a symlink and the file a symlink to a relative target' do
      let(:location) do
        SitemapGenerator::SitemapLocation.new(public_path: File.join(dir, 'public/'), filename: 'sitemap.xml')
      end

      before do
        FileUtils.mkdir_p([File.join(dir, 'shared', 'public'), File.join(dir, 'shared', 'other')])
        File.symlink(File.join(dir, 'shared', 'public'), File.join(dir, 'public'))
        File.symlink('../other/sitemap.xml', File.join(dir, 'shared', 'public', 'sitemap.xml'))
      end

      it 'resolves the target from the real directory of the symlink' do
        adapter.write(location, 'data')
        expect(File.read(File.join(dir, 'shared', 'other', 'sitemap.xml'))).to eq('data')
      end
    end

    context 'when the owner of the file cannot be kept' do
      let!(:gid) do
        File.write(path, 'previous')
        File.stat(path).gid
      end

      before do
        allow(File).to receive(:chown).and_call_original
        allow(File).to receive(:chown).with(Integer, Integer, String).and_raise(Errno::EPERM)
      end

      it 'keeps its group' do
        expect(File).to receive(:chown).with(nil, gid, String).and_call_original
        adapter.write(location, 'data')
      end
    end

    context 'when something is already at the temporary file name' do
      let(:victim) { File.join(dir, 'victim.txt') }

      before do
        File.write(victim, 'previous')
        allow(adapter).to receive(:rand).and_return(0)
        File.symlink(victim, File.join(dir, ".sitemap.xml.#{Process.pid}.0.tmp"))
      end

      it 'neither writes through it nor removes it', :aggregate_failures do
        expect { adapter.write(location, 'data') }.to raise_error(Errno::EEXIST)
        expect(File.read(victim)).to eq('previous')
        expect(File.symlink?(File.join(dir, ".sitemap.xml.#{Process.pid}.0.tmp"))).to be(true)
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
