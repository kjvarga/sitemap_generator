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

describe SitemapGenerator::Helpers::NumberHelper do
  include SitemapGenerator::Helpers::NumberHelper

  it "should number_with_delimiter" do
    number_with_delimiter(12345678).should == "12,345,678"
    number_with_delimiter(0).should == "0"
    number_with_delimiter(123).should == "123"
    number_with_delimiter(123456).should == "123,456"
    number_with_delimiter(123456.78).should == "123,456.78"
    number_with_delimiter(123456.789).should == "123,456.789"
    number_with_delimiter(123456.78901).should == "123,456.78901"
    number_with_delimiter(123456789.78901).should == "123,456,789.78901"
    number_with_delimiter(0.78901).should == "0.78901"
    number_with_delimiter("123456.78").should == "123,456.78"
  end

  it "should number_with_delimiter_with_options_hash" do
    number_with_delimiter(12345678, :delimiter => ' ').should == '12 345 678'
    number_with_delimiter(12345678.05, :separator => '-').should == '12,345,678-05'
    number_with_delimiter(12345678.05, :separator => ',', :delimiter => '.').should == '12.345.678,05'
    number_with_delimiter(12345678.05, :delimiter => '.', :separator => ',').should == '12.345.678,05'
  end

  it "should number_with_precision" do
    number_with_precision(-111.2346).should == "-111.235"
    number_with_precision(111.2346).should == "111.235"
    number_with_precision(31.825, :precision => 2).should == "31.83"
    number_with_precision(111.2346, :precision => 2).should == "111.23"
    number_with_precision(111, :precision => 2).should == "111.00"
    number_with_precision("111.2346").should == "111.235"
    number_with_precision("31.825", :precision => 2).should == "31.83"
    number_with_precision((32.6751 * 100.00), :precision => 0).should == "3268"
    number_with_precision(111.50, :precision => 0).should == "112"
    number_with_precision(1234567891.50, :precision => 0).should == "1234567892"
    number_with_precision(0, :precision => 0).should == "0"
    number_with_precision(0.001, :precision => 5).should == "0.00100"
    number_with_precision(0.00111, :precision => 3).should == "0.001"
    number_with_precision(9.995, :precision => 2).should == "10.00"
    number_with_precision(10.995, :precision => 2).should == "11.00"
  end

  it "should number_with_precision_with_custom_delimiter_and_separator" do
    number_with_precision(31.825, :precision => 2, :separator => ',').should == '31,83'
    number_with_precision(1231.825, :precision => 2, :separator => ',', :delimiter => '.').should == '1.231,83'
  end

  it "should number_with_precision_with_significant_digits" do
    number_with_precision(123987, :precision => 3, :significant => true).should == "124000"
    number_with_precision(123987876, :precision => 2, :significant => true ).should == "120000000"
    number_with_precision("43523", :precision => 1, :significant => true ).should == "40000"
    number_with_precision(9775, :precision => 4, :significant => true ).should == "9775"
    number_with_precision(5.3923, :precision => 2, :significant => true ).should == "5.4"
    number_with_precision(5.3923, :precision => 1, :significant => true ).should == "5"
    number_with_precision(1.232, :precision => 1, :significant => true ).should == "1"
    number_with_precision(7, :precision => 1, :significant => true ).should == "7"
    number_with_precision(1, :precision => 1, :significant => true ).should == "1"
    number_with_precision(52.7923, :precision => 2, :significant => true ).should == "53"
    number_with_precision(9775, :precision => 6, :significant => true ).should == "9775.00"
    number_with_precision(5.3929, :precision => 7, :significant => true ).should == "5.392900"
    number_with_precision(0, :precision => 2, :significant => true ).should == "0.0"
    number_with_precision(0, :precision => 1, :significant => true ).should == "0"
    number_with_precision(0.0001, :precision => 1, :significant => true ).should == "0.0001"
    number_with_precision(0.0001, :precision => 3, :significant => true ).should == "0.000100"
    number_with_precision(0.0001111, :precision => 1, :significant => true ).should == "0.0001"
    number_with_precision(9.995, :precision => 3, :significant => true).should == "10.0"
    number_with_precision(9.994, :precision => 3, :significant => true).should == "9.99"
    number_with_precision(10.995, :precision => 3, :significant => true).should == "11.0"
  end

  it "should number_with_precision_with_strip_insignificant_zeros" do
    number_with_precision(9775.43, :precision => 4, :strip_insignificant_zeros => true ).should == "9775.43"
    number_with_precision(9775.2, :precision => 6, :significant => true, :strip_insignificant_zeros => true ).should == "9775.2"
    number_with_precision(0, :precision => 6, :significant => true, :strip_insignificant_zeros => true ).should == "0"
  end

  it "should number_with_precision_with_significant_true_and_zero_precision" do
    # Zero precision with significant is a mistake (would always return zero),
    # so we treat it as if significant was false (increases backwards compatibily for number_to_human_size)
    number_with_precision(123.987, :precision => 0, :significant => true).should == "124"
    number_with_precision(12, :precision => 0, :significant => true ).should == "12"
    number_with_precision("12.3", :precision => 0, :significant => true ).should == "12"
  end

  it "should number_to_human_size" do
    number_to_human_size(0).should == '0 Bytes'
    number_to_human_size(1).should == '1 Byte'
    number_to_human_size(3.14159265).should == '3 Bytes'
    number_to_human_size(123.0).should == '123 Bytes'
    number_to_human_size(123).should == '123 Bytes'
    number_to_human_size(1234).should == '1.21 KB'
    number_to_human_size(12345).should == '12.1 KB'
    number_to_human_size(1234567).should == '1.18 MB'
    number_to_human_size(1234567890).should == '1.15 GB'
    number_to_human_size(1234567890123).should == '1.12 TB'
    number_to_human_size(terabytes(1026)).should == '1030 TB'
    number_to_human_size(kilobytes(444)).should == '444 KB'
    number_to_human_size(megabytes(1023)).should == '1020 MB'
    number_to_human_size(terabytes(3)).should == '3 TB'
    number_to_human_size(1234567, :precision => 2).should == '1.2 MB'
    number_to_human_size(3.14159265, :precision => 4).should == '3 Bytes'
    number_to_human_size('123').should == '123 Bytes'
    number_to_human_size(kilobytes(1.0123), :precision => 2).should == '1 KB'
    number_to_human_size(kilobytes(1.0100), :precision => 4).should == '1.01 KB'
    number_to_human_size(kilobytes(10.000), :precision => 4).should == '10 KB'
    number_to_human_size(1.1).should == '1 Byte'
    number_to_human_size(10).should == '10 Bytes'
  end

  it "should number_to_human_size_with_options_hash" do
    number_to_human_size(1234567, :precision => 2).should == '1.2 MB'
    number_to_human_size(3.14159265, :precision => 4).should == '3 Bytes'
    number_to_human_size(kilobytes(1.0123), :precision => 2).should == '1 KB'
    number_to_human_size(kilobytes(1.0100), :precision => 4).should == '1.01 KB'
    number_to_human_size(kilobytes(10.000), :precision => 4).should == '10 KB'
    number_to_human_size(1234567890123, :precision => 1).should == '1 TB'
    number_to_human_size(524288000, :precision=>3).should == '500 MB'
    number_to_human_size(9961472, :precision=>0).should == '10 MB'
    number_to_human_size(41010, :precision => 1).should == '40 KB'
    number_to_human_size(41100, :precision => 2).should == '40 KB'
    number_to_human_size(kilobytes(1.0123), :precision => 2, :strip_insignificant_zeros => false).should == '1.0 KB'
    number_to_human_size(kilobytes(1.0123), :precision => 3, :significant => false).should == '1.012 KB'
    number_to_human_size(kilobytes(1.0123), :precision => 0, :significant => true) #ignores significant it precision is 0.should == '1 KB'
  end

  it "should number_to_human_size_with_custom_delimiter_and_separator" do
   number_to_human_size(kilobytes(1.0123), :precision => 3, :separator => ',')                    .should == '1,01 KB'
   number_to_human_size(kilobytes(1.0100), :precision => 4, :separator => ',')                    .should == '1,01 KB'
   number_to_human_size(terabytes(1000.1), :precision => 5, :delimiter => '.', :separator => ',') .should == '1.000,1 TB'
  end

  it "should number_helpers_should_return_nil_when_given_nil" do
    number_with_delimiter(nil).should be_nil
    number_with_precision(nil).should be_nil
    number_to_human_size(nil).should be_nil
  end

  it "should number_helpers_should_return_non_numeric_param_unchanged" do
    number_with_delimiter("x").should == "x"
    number_with_precision("x.").should == "x."
    number_with_precision("x").should == "x"
    number_to_human_size('x').should == "x"
  end

  it "should number_helpers_should_raise_error_if_invalid_when_specified" do
    lambda do
      number_to_human_size("x", :raise => true)
    end.should raise_error(SitemapGenerator::Helpers::NumberHelper::InvalidNumberError)
    begin
      number_to_human_size("x", :raise => true)
    rescue SitemapGenerator::Helpers::NumberHelper::InvalidNumberError => e
      e.number.should == "x"
    end

    lambda do
      number_with_precision("x", :raise => true)
    end.should raise_error(SitemapGenerator::Helpers::NumberHelper::InvalidNumberError)
    begin
      number_with_precision("x", :raise => true)
    rescue SitemapGenerator::Helpers::NumberHelper::InvalidNumberError => e
      e.number.should == "x"
    end

    lambda do
      number_with_delimiter("x", :raise => true)
    end.should raise_error(SitemapGenerator::Helpers::NumberHelper::InvalidNumberError)
    begin
      number_with_delimiter("x", :raise => true)
    rescue SitemapGenerator::Helpers::NumberHelper::InvalidNumberError => e
      e.number.should == "x"
    end
  end
end
