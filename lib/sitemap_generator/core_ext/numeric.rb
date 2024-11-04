# frozen_string_literal: true

class SitemapGenerator::Numeric
  KILOBYTE = 1024
  MEGABYTE = KILOBYTE * 1024
  GIGABYTE = MEGABYTE * 1024
  TERABYTE = GIGABYTE * 1024
  PETABYTE = TERABYTE * 1024
  EXABYTE  = PETABYTE * 1024

  def initialize(number)
    @number = number
  end

  # Enables the use of byte calculations and declarations, like 45.bytes + 2.6.megabytes
  def bytes
    @number
  end
  alias :byte :bytes

  def kilobytes
    @number * KILOBYTE
  end
  alias :kilobyte :kilobytes

  def megabytes
    @number * MEGABYTE
  end
  alias :megabyte :megabytes

  def gigabytes
    @number * GIGABYTE
  end
  alias :gigabyte :gigabytes

  def terabytes
    @number * TERABYTE
  end
  alias :terabyte :terabytes

  def petabytes
    @number * PETABYTE
  end
  alias :petabyte :petabytes

  def exabytes
    @number * EXABYTE
  end
  alias :exabyte :exabytes
end
