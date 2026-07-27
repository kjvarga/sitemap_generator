# frozen_string_literal: true

require 'spec_helper'
require 'sitemap_generator/helpers/number_helper'

def kilobytes(number)
  number * 1024
end

def megabytes(number)
  kilobytes(number) * 1024
end

def gigabytes(number)
  megabytes(number) * 1024
end

def terabytes(number)
  gigabytes(number) * 1024
end

RSpec.describe SitemapGenerator::Helpers::NumberHelper do
  include described_class

  it 'formats a number with a delimiter' do
    number_with_delimiter_cases.each { |input, expected| expect(number_with_delimiter(input)).to eq(expected) }
  end

  def number_with_delimiter_cases
    {
      12_345_678 => '12,345,678',
      0 => '0',
      123 => '123',
      123_456 => '123,456',
      123_456.78 => '123,456.78'
    }.merge(more_number_with_delimiter_cases)
  end

  def more_number_with_delimiter_cases
    {
      123_456.789 => '123,456.789',
      123_456.78901 => '123,456.78901',
      123_456_789.78901 => '123,456,789.78901',
      0.78901 => '0.78901',
      '123456.78' => '123,456.78'
    }
  end

  it 'formats a number with a delimiter using custom options' do
    number_with_delimiter_option_cases.each do |args, expected|
      expect(number_with_delimiter(*args)).to eq(expected)
    end
  end

  def number_with_delimiter_option_cases
    {
      [12_345_678, { delimiter: ' ' }] => '12 345 678',
      [12_345_678.05, { separator: '-' }] => '12,345,678-05',
      [12_345_678.05, { separator: ',', delimiter: '.' }] => '12.345.678,05',
      [12_345_678.05, { delimiter: '.', separator: ',' }] => '12.345.678,05'
    }
  end

  it 'formats a number with precision' do
    number_with_precision_cases.each { |args, expected| expect(number_with_precision(*args)).to eq(expected) }
  end

  def number_with_precision_cases
    {
      [-111.2346] => '-111.235',
      [111.2346] => '111.235',
      [31.825, { precision: 2 }] => '31.83',
      [111.2346, { precision: 2 }] => '111.23',
      [111, { precision: 2 }] => '111.00',
      ['111.2346'] => '111.235',
      ['31.825', { precision: 2 }] => '31.83',
      # Odd difference between Ruby versions when rounding up a five
      [9.995, { precision: 2 }] => RUBY_VERSION < '1.9.3' ? '9.99' : '10.00'
    }.merge(more_number_with_precision_cases)
  end

  def more_number_with_precision_cases
    {
      [32.6751 * 100.00, { precision: 0 }] => '3268',
      [111.50, { precision: 0 }] => '112',
      [1_234_567_891.50, { precision: 0 }] => '1234567892',
      [0, { precision: 0 }] => '0',
      [0.001, { precision: 5 }] => '0.00100',
      [0.00111, { precision: 3 }] => '0.001',
      [10.995, { precision: 2 }] => '11.00'
    }
  end

  it 'formats a number with precision using a custom delimiter and separator' do
    {
      [31.825, { precision: 2, separator: ',' }] => '31,83',
      [1231.825, { precision: 2, separator: ',', delimiter: '.' }] => '1.231,83'
    }.each { |args, expected| expect(number_with_precision(*args)).to eq(expected) }
  end

  it 'formats a number with precision using significant digits' do
    significant_digit_precision_cases.each { |args, expected| expect(number_with_precision(*args)).to eq(expected) }
  end

  def significant_digit_precision_cases
    {
      [123_987, { precision: 3, significant: true }] => '124000',
      [123_987_876, { precision: 2, significant: true }] => '120000000',
      ['43523', { precision: 1, significant: true }] => '40000',
      [9775, { precision: 4, significant: true }] => '9775',
      [5.3923, { precision: 2, significant: true }] => '5.4',
      [5.3923, { precision: 1, significant: true }] => '5',
      [1.232, { precision: 1, significant: true }] => '1'
    }.merge(more_significant_digit_precision_cases)
  end

  def more_significant_digit_precision_cases
    {
      [7, { precision: 1, significant: true }] => '7',
      [1, { precision: 1, significant: true }] => '1',
      [52.7923, { precision: 2, significant: true }] => '53',
      [9775, { precision: 6, significant: true }] => '9775.00',
      [5.3929, { precision: 7, significant: true }] => '5.392900',
      [0, { precision: 2, significant: true }] => '0.0',
      [0, { precision: 1, significant: true }] => '0'
    }.merge(even_more_significant_digit_precision_cases)
  end

  def even_more_significant_digit_precision_cases
    {
      [0.0001, { precision: 1, significant: true }] => '0.0001',
      [0.0001, { precision: 3, significant: true }] => '0.000100',
      [0.0001111, { precision: 1, significant: true }] => '0.0001',
      [9.995, { precision: 3, significant: true }] => '10.0',
      [9.994, { precision: 3, significant: true }] => '9.99',
      [10.995, { precision: 3, significant: true }] => '11.0'
    }
  end

  it 'strips insignificant zeros when formatting with precision' do
    {
      [9775.43, { precision: 4, strip_insignificant_zeros: true }] => '9775.43',
      [9775.2, { precision: 6, significant: true, strip_insignificant_zeros: true }] => '9775.2',
      [0, { precision: 6, significant: true, strip_insignificant_zeros: true }] => '0'
    }.each { |args, expected| expect(number_with_precision(*args)).to eq(expected) }
  end

  it 'treats significant as false when precision is zero' do
    # Zero precision with significant is a mistake (would always return zero),
    # so we treat it as if significant was false (increases backwards compatibily for number_to_human_size)
    {
      [123.987, { precision: 0, significant: true }] => '124',
      [12, { precision: 0, significant: true }] => '12',
      ['12.3', { precision: 0, significant: true }] => '12'
    }.each { |args, expected| expect(number_with_precision(*args)).to eq(expected) }
  end

  it 'formats a number as a human-readable size' do
    human_size_cases.each { |input, expected| expect(number_to_human_size(input)).to eq(expected) }
  end

  def human_size_cases
    {
      0 => '0 Bytes',
      1 => '1 Byte',
      3.14159265 => '3 Bytes',
      123.0 => '123 Bytes',
      123 => '123 Bytes',
      1234 => '1.21 KB',
      12_345 => '12.1 KB'
    }.merge(more_human_size_cases)
  end

  def more_human_size_cases
    {
      1_234_567 => '1.18 MB',
      1_234_567_890 => '1.15 GB',
      1_234_567_890_123 => '1.12 TB',
      terabytes(1026) => '1030 TB',
      kilobytes(444) => '444 KB'
    }.merge(even_more_human_size_cases)
  end

  def even_more_human_size_cases
    {
      megabytes(1023) => '1020 MB',
      terabytes(3) => '3 TB',
      '123' => '123 Bytes',
      1.1 => '1 Byte',
      10 => '10 Bytes'
    }
  end

  it 'formats a human-readable size using custom options' do
    human_size_option_cases.each { |args, expected| expect(number_to_human_size(*args)).to eq(expected) }
  end

  def human_size_option_cases
    {
      [1_234_567, { precision: 2 }] => '1.2 MB',
      [3.14159265, { precision: 4 }] => '3 Bytes',
      [kilobytes(1.0123), { precision: 2 }] => '1 KB',
      [kilobytes(1.0100), { precision: 4 }] => '1.01 KB',
      [kilobytes(10.000), { precision: 4 }] => '10 KB',
      [1_234_567_890_123, { precision: 1 }] => '1 TB',
      [524_288_000, { precision: 3 }] => '500 MB'
    }.merge(more_human_size_option_cases)
  end

  def more_human_size_option_cases
    {
      [9_961_472, { precision: 0 }] => '10 MB',
      [41_010, { precision: 1 }] => '40 KB',
      [41_100, { precision: 2 }] => '40 KB',
      [kilobytes(1.0123), { precision: 2, strip_insignificant_zeros: false }] => '1.0 KB',
      [kilobytes(1.0123), { precision: 3, significant: false }] => '1.012 KB',
      # significant is ignored when precision is 0
      [kilobytes(1.0123), { precision: 0, significant: true }] => '1 KB'
    }
  end

  it 'formats a human-readable size using a custom delimiter and separator' do
    human_size_delimiter_cases.each { |args, expected| expect(number_to_human_size(*args)).to eq(expected) }
  end

  def human_size_delimiter_cases
    {
      [kilobytes(1.0123), { precision: 3, separator: ',' }] => '1,01 KB',
      [kilobytes(1.0100), { precision: 4, separator: ',' }] => '1,01 KB',
      [terabytes(1000.1), { precision: 5, delimiter: '.', separator: ',' }] => '1.000,1 TB'
    }
  end

  it 'returns nil when given nil' do
    results = [number_with_delimiter(nil), number_with_precision(nil), number_to_human_size(nil)]
    expect(results).to all(be_nil)
  end

  it 'returns non-numeric input unchanged' do
    results = [number_with_delimiter('x'), number_with_precision('x.'), number_with_precision('x'),
               number_to_human_size('x')]
    expect(results).to eq(['x', 'x.', 'x', 'x'])
  end

  it 'raises an error for invalid input when raise is specified' do
    expect_raises_invalid_number { number_to_human_size('x', raise: true) }
    expect_raises_invalid_number { number_with_precision('x', raise: true) }
    expect_raises_invalid_number { number_with_delimiter('x', raise: true) }
  end

  def expect_raises_invalid_number(&block)
    expect(&block).to raise_error(SitemapGenerator::Helpers::NumberHelper::InvalidNumberError)
    yield
  rescue SitemapGenerator::Helpers::NumberHelper::InvalidNumberError => e
    expect(e.number).to eq('x')
  end
end
