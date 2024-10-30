require 'spec_helper'

RSpec.describe SitemapGenerator::Utilities do
  describe 'rounding' do
    let(:utils) { SitemapGenerator::Utilities }

    it 'should round for positive number' do
      expect(utils.round(1.4))      .to eq(1)
      expect(utils.round(1.6))     .to eq(2)
      expect(utils.round(1.6, 0))  .to eq(2)
      expect(utils.round(1.4, 1))  .to eq(1.4)
      expect(utils.round(1.4, 3))  .to eq(1.4)
      expect(utils.round(1.45, 1)) .to eq(1.5)
      expect(utils.round(1.445, 2)).to eq(1.45)
      # Demonstrates a bug in the round method
      # utils.round(9.995, 2).should == 10
    end

    it 'should round for negative number' do
      expect(utils.round(-1.4))    .to eq(-1)
      expect(utils.round(-1.6))    .to eq(-2)
      expect(utils.round(-1.4, 1)) .to eq(-1.4)
      expect(utils.round(-1.45, 1)).to eq(-1.5)
    end

    it 'should round with negative precision' do
      expect(utils.round(123456.0, -1)).to eq(123460.0)
      expect(utils.round(123456.0, -2)).to eq(123500.0)
    end
  end
end
