# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::Numeric do
  def numeric(size)
    SitemapGenerator::Numeric.new(size)
  end

  describe 'bytes' do
    let(:byte_unit_relationships) do
      {
        numeric(1024).bytes => numeric(1).kilobyte,
        numeric(1024).kilobytes => numeric(1).megabyte,
        numeric(3584.0).kilobytes => numeric(3.5).megabytes,
        numeric(3584.0).megabytes => numeric(3.5).gigabytes,
        numeric(1).kilobyte**4 => numeric(1).terabyte,
        numeric(1024).kilobytes + numeric(2).megabytes => numeric(3).megabytes,
        numeric(2).gigabytes / 4 => numeric(512).megabytes,
        (numeric(256).megabytes * 20) + numeric(5).gigabytes => numeric(10).gigabytes,
        numeric(1).kilobyte**5 => numeric(1).petabyte,
        numeric(1).kilobyte**6 => numeric(1).exabyte
      }
    end

    let(:byte_unit_values) do
      {
        numeric(3).megabytes => 3_145_728,
        numeric(3).megabyte => 3_145_728,
        numeric(3).kilobytes => 3072,
        numeric(3).kilobyte => 3072,
        numeric(3).gigabytes => 3_221_225_472,
        numeric(3).gigabyte => 3_221_225_472,
        numeric(3).terabytes => 3_298_534_883_328,
        numeric(3).terabyte => 3_298_534_883_328,
        numeric(3).petabytes => 3_377_699_720_527_872,
        numeric(3).petabyte => 3_377_699_720_527_872,
        numeric(3).exabytes => 3_458_764_513_820_540_928,
        numeric(3).exabyte => 3_458_764_513_820_540_928
      }
    end

    it 'defines equality of different units' do
      byte_unit_relationships.each { |left, right| expect(left).to eq(right) }
    end

    it 'represents units as bytes' do
      byte_unit_values.each { |value, bytes| expect(value).to eq(bytes) }
    end
  end
end
