# frozen_string_literal: true

require 'spec_helper'
require 'bigdecimal'

RSpec.describe SitemapGenerator::BigDecimal do
  describe 'to_yaml' do
    it 'serializes correctly' do
      serialization_cases.each { |value, pattern| expect(described_class.new(value).to_yaml).to match(pattern) }
    end

    def serialization_cases
      big_number = '100000.30020320320000000000000000000000000000001'
      {
        big_number => /^--- #{Regexp.escape(big_number)}\n/,
        'Infinity' => /^--- \.Inf\n/,
        'NaN' => /^--- \.NaN\n/,
        '-Infinity' => /^--- -\.Inf\n/
      }
    end
  end

  describe 'to_d' do
    it 'converts correctly' do
      bd = described_class.new '10'
      expect(bd.to_d).to eq(bd)
    end
  end
end
