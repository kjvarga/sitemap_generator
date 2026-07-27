# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::Utilities do
  describe 'rounding' do
    let(:utils) { described_class }

    # Demonstrates a bug in the round method: utils.round(9.995, 2) is expected to be 10
    it 'rounds for positive number' do
      positive_rounding_cases.each { |args, expected| expect(utils.round(*args)).to eq(expected) }
    end

    def positive_rounding_cases
      {
        [1.4] => 1,
        [1.6] => 2,
        [1.6, 0] => 2,
        [1.4, 1] => 1.4,
        [1.4, 3] => 1.4,
        [1.45, 1] => 1.5,
        [1.445, 2] => 1.45
      }
    end

    it 'rounds for negative number' do
      expect(utils.round(-1.4)).to eq(-1)
      expect(utils.round(-1.6)).to eq(-2)
      expect(utils.round(-1.4, 1)).to eq(-1.4)
      expect(utils.round(-1.45, 1)).to eq(-1.5)
    end

    it 'rounds with negative precision' do
      expect(utils.round(123_456.0, -1)).to eq(123_460.0)
      expect(utils.round(123_456.0, -2)).to eq(123_500.0)
    end
  end
end
