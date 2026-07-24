# frozen_string_literal: true

require 'spec_helper'
require 'bigdecimal'

RSpec.describe SitemapGenerator::BigDecimal do
  describe 'to_yaml' do
    it 'serializes correctly' do
      big_number = '100000.30020320320000000000000000000000000000001'
      expect(described_class.new(big_number).to_yaml).to match(/^--- #{Regexp.escape(big_number)}\n/)
      expect(described_class.new('Infinity').to_yaml).to match(/^--- \.Inf\n/)
      expect(described_class.new('NaN').to_yaml).to match(/^--- \.NaN\n/)
      expect(described_class.new('-Infinity').to_yaml).to match(/^--- -\.Inf\n/)
    end
  end

  describe 'to_d' do
    it 'converts correctly' do
      bd = described_class.new '10'
      expect(bd.to_d).to eq(bd)
    end
  end
end
