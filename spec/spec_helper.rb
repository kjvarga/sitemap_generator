# Load dev/test libs
require 'byebug'
require 'webmock/rspec'

# Load support files
require_relative 'support/file_macros'
require_relative 'support/xml_macros'

# Load simplecov
# require 'simplecov'
# SimpleCov.start

# Configure webmock
WebMock.disable_net_connect!

# Configure rspec
RSpec.configure do |config|
  config.include(FileMacros)
  config.include(XmlMacros)

  # run tests in random order
  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # disable monkey patching
  # see: https://rspec.info/features/3-12/rspec-core/configuration/zero-monkey-patching-mode/
  config.disable_monkey_patching!
end

# Load our own gem
require 'sitemap_generator'
SitemapGenerator.verbose = false
