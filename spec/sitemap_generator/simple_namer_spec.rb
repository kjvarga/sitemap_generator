# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::SimpleNamer do
  it 'generates file names' do
    namer = described_class.new(:sitemap)
    names = [namer.to_s, namer.next.to_s, namer.next.to_s]
    expect(names).to eq(%w[sitemap.xml.gz sitemap1.xml.gz sitemap2.xml.gz])
  end

  it 'sets the file extension' do
    namer = described_class.new(:sitemap, extension: '.xyz')
    names = [namer.to_s, namer.next.to_s, namer.next.to_s]
    expect(names).to eq(%w[sitemap.xyz sitemap1.xyz sitemap2.xyz])
  end

  it 'sets the starting index' do
    namer = described_class.new(:sitemap, start: 10)
    names = [namer.to_s, namer.next.to_s, namer.next.to_s]
    expect(names).to eq(%w[sitemap.xml.gz sitemap10.xml.gz sitemap11.xml.gz])
  end

  it 'accepts a string name' do
    namer = described_class.new('abc-def')
    names = [namer.to_s, namer.next.to_s, namer.next.to_s]
    expect(names).to eq(%w[abc-def.xml.gz abc-def1.xml.gz abc-def2.xml.gz])
  end

  it 'returns previous name' do
    namer = described_class.new(:sitemap)
    expect(namer.to_s).to eq('sitemap.xml.gz')
    expect_next_then_previous_sequence(namer)
  end

  def expect_next_then_previous_sequence(namer)
    expect(namer.next.to_s).to eq('sitemap1.xml.gz')
    expect(namer.previous.to_s).to eq('sitemap.xml.gz')
    expect_double_next_then_previous(namer, 'sitemap2.xml.gz', 'sitemap1.xml.gz')
    expect_double_next_then_previous(namer, 'sitemap3.xml.gz', 'sitemap2.xml.gz')
  end

  def expect_double_next_then_previous(namer, next_name, previous_name)
    expect(namer.next.next.to_s).to eq(next_name)
    expect(namer.previous.to_s).to eq(previous_name)
  end

  it 'raises if already at the start' do
    namer = described_class.new(:sitemap)
    # Use a regex because in Ruby 3.1 the error message includes newlines and the first line of backtrace
    expect { namer.previous }.to raise_error(NameError, /Already at the start of the series/)
  end

  it 'handles names with underscores' do
    namer = described_class.new('sitemap1_')
    names = [namer.to_s, namer.next.to_s]
    expect(names).to eq(%w[sitemap1_.xml.gz sitemap1_1.xml.gz])
  end

  it 'resets the namer' do
    namer = described_class.new(:sitemap)
    expect_initial_and_first_name(namer)
    namer.reset
    expect_initial_and_first_name(namer)
  end

  def expect_initial_and_first_name(namer)
    expect(namer.to_s).to eq('sitemap.xml.gz')
    expect(namer.next.to_s).to eq('sitemap1.xml.gz')
  end

  describe 'should handle the zero option' do
    it 'as a plain string' do
      namer = described_class.new(:sitemap, zero: 'string')
      names = [namer.to_s, namer.next.to_s]
      expect(names).to eq(%w[sitemapstring.xml.gz sitemap1.xml.gz])
    end

    it 'as an integer' do
      namer = described_class.new(:sitemap, zero: 0)
      names = [namer.to_s, namer.next.to_s]
      expect(names).to eq(%w[sitemap0.xml.gz sitemap1.xml.gz])
    end

    it 'as a string with a leading underscore' do
      namer = described_class.new(:sitemap, zero: '_index')
      names = [namer.to_s, namer.next.to_s]
      expect(names).to eq(%w[sitemap_index.xml.gz sitemap1.xml.gz])
    end

    it 'as a symbol' do
      namer = described_class.new(:sitemap, zero: :index)
      names = [namer.to_s, namer.next.to_s]
      expect(names).to eq(%w[sitemapindex.xml.gz sitemap1.xml.gz])
    end

    it 'with a starting index' do
      namer = described_class.new(:sitemap, zero: 'abc', start: 10)
      names = [namer.to_s, namer.next.to_s, namer.next.to_s]
      expect(names).to eq(%w[sitemapabc.xml.gz sitemap10.xml.gz sitemap11.xml.gz])
    end
  end
end
