require 'spec_helper'
require 'bigdecimal'

RSpec.describe SitemapGenerator::BigDecimal do
  describe 'to_yaml' do
    it 'should serialize correctly' do
      expect(SitemapGenerator::BigDecimal.new('100000.30020320320000000000000000000000000000001').to_yaml).to match(/^--- 100000\.30020320320000000000000000000000000000001\n/)
      expect(SitemapGenerator::BigDecimal.new('Infinity').to_yaml).to match(/^--- \.Inf\n/)
      expect(SitemapGenerator::BigDecimal.new('NaN').to_yaml).to match(/^--- \.NaN\n/)
      expect(SitemapGenerator::BigDecimal.new('-Infinity').to_yaml).to match(/^--- -\.Inf\n/)
    end
  end

  describe 'to_d' do
    it 'should convert correctly' do
      bd = SitemapGenerator::BigDecimal.new '10'
      expect(bd.to_d).to eq(bd)
    end
  end
end
