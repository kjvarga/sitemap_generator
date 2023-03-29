require 'spec_helper'

describe SitemapGenerator::Numeric do
  def numeric(size)
    SitemapGenerator::Numeric.new(size)
  end

  describe 'bytes' do
    it 'should define equality of different units' do
      relationships = {
        numeric(  1024).bytes     => numeric(  1).kilobyte,
        numeric(  1024).kilobytes => numeric(  1).megabyte,
        numeric(3584.0).kilobytes => numeric(3.5).megabytes,
        numeric(3584.0).megabytes => numeric(3.5).gigabytes,
        numeric(1).kilobyte ** 4  => numeric(  1).terabyte,
        numeric(1024).kilobytes + numeric(2).megabytes =>   numeric(3).megabytes,
        numeric(             2).gigabytes / 4 => numeric(512).megabytes,
        numeric(256).megabytes * 20 + numeric( 5).gigabytes => numeric(10).gigabytes,
        numeric(1).kilobyte ** 5 => numeric(1).petabyte,
        numeric(1).kilobyte ** 6 => numeric(1).exabyte
      }

      relationships.each do |left, right|
        expect(left).to eq(right)
      end
    end

    it 'should represent units as bytes' do
      expect(numeric(3).megabytes).to eq(3145728)
      expect(numeric(3).megabyte) .to eq(3145728)
      expect(numeric(3).kilobytes).to eq(3072)
      expect(numeric(3).kilobyte) .to eq(3072)
      expect(numeric(3).gigabytes).to eq(3221225472)
      expect(numeric(3).gigabyte) .to eq(3221225472)
      expect(numeric(3).terabytes).to eq(3298534883328)
      expect(numeric(3).terabyte) .to eq(3298534883328)
      expect(numeric(3).petabytes).to eq(3377699720527872)
      expect(numeric(3).petabyte) .to eq(3377699720527872)
      expect(numeric(3).exabytes) .to eq(3458764513820540928)
      expect(numeric(3).exabyte)  .to eq(3458764513820540928)
    end
  end
end
