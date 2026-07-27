# frozen_string_literal: true

require 'spec_helper'

class EmptyTrue
  def empty?
    true
  end
end

class EmptyFalse
  def empty?
    false
  end
end

BLANK = [EmptyTrue.new, nil, false, '', '   ', "  \n\t  \r ", [], {}].freeze
NOT   = [EmptyFalse.new, Object.new, true, 0, 1, 'a', [nil], { nil => 0 }].freeze

RSpec.describe Object do
  let(:utils) { SitemapGenerator::Utilities }

  it 'defines blankness' do
    blankness_cases.each { |v, expected| expect(utils.blank?(v)).to be(expected) }
  end

  it 'defines presence' do
    blankness_cases.each { |v, expected| expect(utils.present?(v)).to be(!expected) }
  end

  def blankness_cases
    BLANK.map { |v| [v, true] } + NOT.map { |v| [v, false] }
  end
end
