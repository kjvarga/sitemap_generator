# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::Builder::XmlEscape do
  # Escape +value+ the way Builder::XmlMarkup does, by rendering it as text and as an attribute.
  def builder_text(value)
    Builder::XmlMarkup.new.x(value).delete_prefix('<x>').delete_suffix('</x>')
  end

  def builder_attribute(value)
    Builder::XmlMarkup.new.x(a: value)[%r{\A<x a="(.*)"/>\z}m, 1]
  end

  samples = [
    'http://example.com/path?a=1', 'a & b', '<tag>', 'say "hi"', "it's", "line\nbreak", "cr\rlf", "tab\tbed",
    "nul\x00", "bell\x07", "esc\x1B", 'café', '日本語', "cp1252 \u0080 \u0099", '😀', '',
    "invalid #{0xFFFE.chr(Encoding::UTF_8)}",
    (+"latin1 \xE9").force_encoding('ISO-8859-1'), (+"binary \xC3\xA9").force_encoding('BINARY'),
    (+"invalid utf-8 \xFF").force_encoding('UTF-8')
  ]

  describe '.escape_text' do
    samples.each do |sample|
      context "when given #{sample.inspect}" do
        it 'matches Builder::XmlMarkup' do
          expect(described_class.escape_text(sample)).to eq(builder_text(sample))
        end
      end
    end

    context 'when given a non-string' do
      it 'converts it with to_s' do
        expect(described_class.escape_text(1.5)).to eq('1.5')
      end
    end

    context 'when the string has nothing to escape' do
      it 'returns the same object' do
        string = 'http://example.com/'
        expect(described_class.escape_text(string)).to be(string)
      end
    end
  end

  describe '.escape_attribute' do
    samples.each do |sample|
      context "when given #{sample.inspect}" do
        it 'matches Builder::XmlMarkup' do
          expect(described_class.escape_attribute(sample)).to eq(builder_attribute(sample))
        end
      end
    end

    context 'when given a symbol' do
      it 'does not escape it' do
        expect(described_class.escape_attribute(:'a&b')).to eq('a&b')
      end
    end
  end
end
