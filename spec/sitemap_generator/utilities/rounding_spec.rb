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
      negative_rounding_cases.each { |args, expected| expect(utils.round(*args)).to eq(expected) }
    end

    def negative_rounding_cases
      {
        [-1.4] => -1,
        [-1.6] => -2,
        [-1.4, 1] => -1.4,
        [-1.45, 1] => -1.5
      }
    end

    it 'rounds with negative precision' do
      { [123_456.0, -1] => 123_460.0, [123_456.0, -2] => 123_500.0 }.each do |args, expected|
        expect(utils.round(*args)).to eq(expected)
      end
    end
  end
end
