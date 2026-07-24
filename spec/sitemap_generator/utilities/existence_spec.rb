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
    BLANK.each { |v| expect(utils.blank?(v)).to be(true) }
    NOT.each   { |v| expect(utils.blank?(v)).to be(false) }
  end

  it 'defines presence' do
    BLANK.each { |v| expect(utils.present?(v)).to be(false) }
    NOT.each   { |v| expect(utils.present?(v)).to be(true) }
  end
end
