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
  include SitemapGenerator::Helpers::NumberHelper

  it 'should number_with_delimiter' do
    expect(number_with_delimiter(12345678)).to eq('12,345,678')
    expect(number_with_delimiter(0)).to eq('0')
    expect(number_with_delimiter(123)).to eq('123')
    expect(number_with_delimiter(123456)).to eq('123,456')
    expect(number_with_delimiter(123456.78)).to eq('123,456.78')
    expect(number_with_delimiter(123456.789)).to eq('123,456.789')
    expect(number_with_delimiter(123456.78901)).to eq('123,456.78901')
    expect(number_with_delimiter(123456789.78901)).to eq('123,456,789.78901')
    expect(number_with_delimiter(0.78901)).to eq('0.78901')
    expect(number_with_delimiter('123456.78')).to eq('123,456.78')
  end

  it 'should number_with_delimiter_with_options_hash' do
    expect(number_with_delimiter(12345678, :delimiter => ' ')).to eq('12 345 678')
    expect(number_with_delimiter(12345678.05, :separator => '-')).to eq('12,345,678-05')
    expect(number_with_delimiter(12345678.05, :separator => ',', :delimiter => '.')).to eq('12.345.678,05')
    expect(number_with_delimiter(12345678.05, :delimiter => '.', :separator => ',')).to eq('12.345.678,05')
  end

  it 'should number_with_precision' do
    expect(number_with_precision(-111.2346)).to eq('-111.235')
    expect(number_with_precision(111.2346)).to eq('111.235')
    expect(number_with_precision(31.825, :precision => 2)).to eq('31.83')
    expect(number_with_precision(111.2346, :precision => 2)).to eq('111.23')
    expect(number_with_precision(111, :precision => 2)).to eq('111.00')
    expect(number_with_precision('111.2346')).to eq('111.235')
    expect(number_with_precision('31.825', :precision => 2)).to eq('31.83')
    expect(number_with_precision((32.6751 * 100.00), :precision => 0)).to eq('3268')
    expect(number_with_precision(111.50, :precision => 0)).to eq('112')
    expect(number_with_precision(1234567891.50, :precision => 0)).to eq('1234567892')
    expect(number_with_precision(0, :precision => 0)).to eq('0')
    expect(number_with_precision(0.001, :precision => 5)).to eq('0.00100')
    expect(number_with_precision(0.00111, :precision => 3)).to eq('0.001')
    # Odd difference between Ruby versions
    if RUBY_VERSION < '1.9.3'
      expect(number_with_precision(9.995, :precision => 2)).to eq('9.99')
    else
      expect(number_with_precision(9.995, :precision => 2)).to eq('10.00')
    end
    expect(number_with_precision(10.995, :precision => 2)).to eq('11.00')
  end

  it 'should number_with_precision_with_custom_delimiter_and_separator' do
    expect(number_with_precision(31.825, :precision => 2, :separator => ',')).to eq('31,83')
    expect(number_with_precision(1231.825, :precision => 2, :separator => ',', :delimiter => '.')).to eq('1.231,83')
  end

  it 'should number_with_precision_with_significant_digits' do
    expect(number_with_precision(123987, :precision => 3, :significant => true)).to eq('124000')
    expect(number_with_precision(123987876, :precision => 2, :significant => true )).to eq('120000000')
    expect(number_with_precision('43523', :precision => 1, :significant => true )).to eq('40000')
    expect(number_with_precision(9775, :precision => 4, :significant => true )).to eq('9775')
    expect(number_with_precision(5.3923, :precision => 2, :significant => true )).to eq('5.4')
    expect(number_with_precision(5.3923, :precision => 1, :significant => true )).to eq('5')
    expect(number_with_precision(1.232, :precision => 1, :significant => true )).to eq('1')
    expect(number_with_precision(7, :precision => 1, :significant => true )).to eq('7')
    expect(number_with_precision(1, :precision => 1, :significant => true )).to eq('1')
    expect(number_with_precision(52.7923, :precision => 2, :significant => true )).to eq('53')
    expect(number_with_precision(9775, :precision => 6, :significant => true )).to eq('9775.00')
    expect(number_with_precision(5.3929, :precision => 7, :significant => true )).to eq('5.392900')
    expect(number_with_precision(0, :precision => 2, :significant => true )).to eq('0.0')
    expect(number_with_precision(0, :precision => 1, :significant => true )).to eq('0')
    expect(number_with_precision(0.0001, :precision => 1, :significant => true )).to eq('0.0001')
    expect(number_with_precision(0.0001, :precision => 3, :significant => true )).to eq('0.000100')
    expect(number_with_precision(0.0001111, :precision => 1, :significant => true )).to eq('0.0001')
    expect(number_with_precision(9.995, :precision => 3, :significant => true)).to eq('10.0')
    expect(number_with_precision(9.994, :precision => 3, :significant => true)).to eq('9.99')
    expect(number_with_precision(10.995, :precision => 3, :significant => true)).to eq('11.0')
  end

  it 'should number_with_precision_with_strip_insignificant_zeros' do
    expect(number_with_precision(9775.43, :precision => 4, :strip_insignificant_zeros => true )).to eq('9775.43')
    expect(number_with_precision(9775.2, :precision => 6, :significant => true, :strip_insignificant_zeros => true )).to eq('9775.2')
    expect(number_with_precision(0, :precision => 6, :significant => true, :strip_insignificant_zeros => true )).to eq('0')
  end

  it 'should number_with_precision_with_significant_true_and_zero_precision' do
    # Zero precision with significant is a mistake (would always return zero),
    # so we treat it as if significant was false (increases backwards compatibily for number_to_human_size)
    expect(number_with_precision(123.987, :precision => 0, :significant => true)).to eq('124')
    expect(number_with_precision(12, :precision => 0, :significant => true )).to eq('12')
    expect(number_with_precision('12.3', :precision => 0, :significant => true )).to eq('12')
  end

  it 'should number_to_human_size' do
    expect(number_to_human_size(0)).to eq('0 Bytes')
    expect(number_to_human_size(1)).to eq('1 Byte')
    expect(number_to_human_size(3.14159265)).to eq('3 Bytes')
    expect(number_to_human_size(123.0)).to eq('123 Bytes')
    expect(number_to_human_size(123)).to eq('123 Bytes')
    expect(number_to_human_size(1234)).to eq('1.21 KB')
    expect(number_to_human_size(12345)).to eq('12.1 KB')
    expect(number_to_human_size(1234567)).to eq('1.18 MB')
    expect(number_to_human_size(1234567890)).to eq('1.15 GB')
    expect(number_to_human_size(1234567890123)).to eq('1.12 TB')
    expect(number_to_human_size(terabytes(1026))).to eq('1030 TB')
    expect(number_to_human_size(kilobytes(444))).to eq('444 KB')
    expect(number_to_human_size(megabytes(1023))).to eq('1020 MB')
    expect(number_to_human_size(terabytes(3))).to eq('3 TB')
    expect(number_to_human_size(1234567, :precision => 2)).to eq('1.2 MB')
    expect(number_to_human_size(3.14159265, :precision => 4)).to eq('3 Bytes')
    expect(number_to_human_size('123')).to eq('123 Bytes')
    expect(number_to_human_size(kilobytes(1.0123), :precision => 2)).to eq('1 KB')
    expect(number_to_human_size(kilobytes(1.0100), :precision => 4)).to eq('1.01 KB')
    expect(number_to_human_size(kilobytes(10.000), :precision => 4)).to eq('10 KB')
    expect(number_to_human_size(1.1)).to eq('1 Byte')
    expect(number_to_human_size(10)).to eq('10 Bytes')
  end

  it 'should number_to_human_size_with_options_hash' do
    expect(number_to_human_size(1234567, :precision => 2)).to eq('1.2 MB')
    expect(number_to_human_size(3.14159265, :precision => 4)).to eq('3 Bytes')
    expect(number_to_human_size(kilobytes(1.0123), :precision => 2)).to eq('1 KB')
    expect(number_to_human_size(kilobytes(1.0100), :precision => 4)).to eq('1.01 KB')
    expect(number_to_human_size(kilobytes(10.000), :precision => 4)).to eq('10 KB')
    expect(number_to_human_size(1234567890123, :precision => 1)).to eq('1 TB')
    expect(number_to_human_size(524288000, :precision=>3)).to eq('500 MB')
    expect(number_to_human_size(9961472, :precision=>0)).to eq('10 MB')
    expect(number_to_human_size(41010, :precision => 1)).to eq('40 KB')
    expect(number_to_human_size(41100, :precision => 2)).to eq('40 KB')
    expect(number_to_human_size(kilobytes(1.0123), :precision => 2, :strip_insignificant_zeros => false)).to eq('1.0 KB')
    expect(number_to_human_size(kilobytes(1.0123), :precision => 3, :significant => false)).to eq('1.012 KB')
    number_to_human_size(kilobytes(1.0123), :precision => 0, :significant => true) #ignores significant it precision is 0.should == '1 KB'
  end

  it 'should number_to_human_size_with_custom_delimiter_and_separator' do
   expect(number_to_human_size(kilobytes(1.0123), :precision => 3, :separator => ','))                    .to eq('1,01 KB')
   expect(number_to_human_size(kilobytes(1.0100), :precision => 4, :separator => ','))                    .to eq('1,01 KB')
   expect(number_to_human_size(terabytes(1000.1), :precision => 5, :delimiter => '.', :separator => ',')) .to eq('1.000,1 TB')
  end

  it 'should number_helpers_should_return_nil_when_given_nil' do
    expect(number_with_delimiter(nil)).to be_nil
    expect(number_with_precision(nil)).to be_nil
    expect(number_to_human_size(nil)).to be_nil
  end

  it 'should number_helpers_should_return_non_numeric_param_unchanged' do
    expect(number_with_delimiter('x')).to eq('x')
    expect(number_with_precision('x.')).to eq('x.')
    expect(number_with_precision('x')).to eq('x')
    expect(number_to_human_size('x')).to eq('x')
  end

  it 'should number_helpers_should_raise_error_if_invalid_when_specified' do
    expect do
      number_to_human_size('x', :raise => true)
    end.to raise_error(SitemapGenerator::Helpers::NumberHelper::InvalidNumberError)
    begin
      number_to_human_size('x', :raise => true)
    rescue SitemapGenerator::Helpers::NumberHelper::InvalidNumberError => e
      expect(e.number).to eq('x')
    end

    expect do
      number_with_precision('x', :raise => true)
    end.to raise_error(SitemapGenerator::Helpers::NumberHelper::InvalidNumberError)
    begin
      number_with_precision('x', :raise => true)
    rescue SitemapGenerator::Helpers::NumberHelper::InvalidNumberError => e
      expect(e.number).to eq('x')
    end

    expect do
      number_with_delimiter('x', :raise => true)
    end.to raise_error(SitemapGenerator::Helpers::NumberHelper::InvalidNumberError)
    begin
      number_with_delimiter('x', :raise => true)
    rescue SitemapGenerator::Helpers::NumberHelper::InvalidNumberError => e
      expect(e.number).to eq('x')
    end
  end
end
