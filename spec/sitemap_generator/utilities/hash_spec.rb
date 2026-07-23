# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::Utilities do
  let(:utils) { described_class }

  describe 'assert_valid_keys' do
    it 'raises' do
      expect do
        utils.assert_valid_keys({ failore: 'stuff', funny: 'business' }, %i[failure funny])
        utils.assert_valid_keys({ failore: 'stuff', funny: 'business' }, :failure, :funny)
      end.to raise_error(ArgumentError, 'Unknown key(s): failore')
    end

    it 'does not raise' do
      expect do
        utils.assert_valid_keys({ failure: 'stuff', funny: 'business' }, %i[failure funny])
        utils.assert_valid_keys({ failure: 'stuff', funny: 'business' }, :failure, :funny)
      end.not_to raise_error
    end
  end

  describe 'keys' do
    before do
      @strings = { 'a' => 1, 'b' => 2 }
      @symbols = { a: 1, b: 2 }
      @mixed   = { :a => 1, 'b' => 2 }
      @fixnums = { 0 => 1, 1 => 2 }
      @illegal_symbols = if RUBY_VERSION < '1.9.0'
                           { '\0' => 1, '' => 2, [] => 3 }
                         else
                           { [] => 3 }
                         end
    end

    it 'symbolize_keyses' do
      expect(utils.symbolize_keys(@symbols)).to eq(@symbols)
      expect(utils.symbolize_keys(@strings)).to eq(@symbols)
      expect(utils.symbolize_keys(@mixed)).to eq(@symbols)
    end

    it 'symbolize_keys!s' do
      expect(utils.symbolize_keys!(@symbols.dup)).to eq(@symbols)
      expect(utils.symbolize_keys!(@strings.dup)).to eq(@symbols)
      expect(utils.symbolize_keys!(@mixed.dup)).to eq(@symbols)
    end

    it 'symbolize_keys_preserves_keys_that_cant_be_symbolizeds' do
      expect(utils.symbolize_keys(@illegal_symbols)).to eq(@illegal_symbols)
      expect(utils.symbolize_keys!(@illegal_symbols.dup)).to eq(@illegal_symbols)
    end

    it 'symbolize_keys_preserves_fixnum_keyses' do
      expect(utils.symbolize_keys(@fixnums)).to eq(@fixnums)
      expect(utils.symbolize_keys!(@fixnums.dup)).to eq(@fixnums)
    end
  end
end
