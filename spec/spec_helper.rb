# require 'simplecov'
# SimpleCov.start
require 'bundler/setup'
Bundler.require

require './spec/support/file_macros'
require './spec/support/xml_macros'
require 'webmock/rspec'
require 'byebug'

WebMock.disable_net_connect!

SitemapGenerator.verbose = false

RSpec.configure do |config|
  config.include(FileMacros)
  config.include(XmlMacros)

  # run tests in random order
  config.order = :random
  Kernel.srand config.seed

  # disable monkey patching
  # see: https://rspec.info/features/3-12/rspec-core/configuration/zero-monkey-patching-mode/
  config.disable_monkey_patching!
end
