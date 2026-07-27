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

  # rubocop:disable RSpec/MultipleMemoizedHelpers -- 5 independent hash fixtures needed to
  # exercise symbolize_keys across string/symbol/mixed/fixnum/illegal-symbol key types
  describe 'keys' do
    let(:strings) { { 'a' => 1, 'b' => 2 } }
    let(:symbols) { { a: 1, b: 2 } }
    let(:mixed)   { { :a => 1, 'b' => 2 } }
    let(:fixnums) { { 0 => 1, 1 => 2 } }
    let(:illegal_symbols) do
      if RUBY_VERSION < '1.9.0'
        { '\0' => 1, '' => 2, [] => 3 }
      else
        { [] => 3 }
      end
    end

    it 'symbolizes keys' do
      results = [utils.symbolize_keys(symbols), utils.symbolize_keys(strings), utils.symbolize_keys(mixed)]
      expect(results).to all(eq(symbols))
    end

    it 'symbolizes keys destructively' do
      results = [utils.symbolize_keys!(symbols.dup), utils.symbolize_keys!(strings.dup),
                 utils.symbolize_keys!(mixed.dup)]
      expect(results).to all(eq(symbols))
    end

    it 'preserves keys that cannot be symbolized' do
      results = [utils.symbolize_keys(illegal_symbols), utils.symbolize_keys!(illegal_symbols.dup)]
      expect(results).to all(eq(illegal_symbols))
    end

    it 'preserves fixnum keys' do
      results = [utils.symbolize_keys(fixnums), utils.symbolize_keys!(fixnums.dup)]
      expect(results).to all(eq(fixnums))
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
