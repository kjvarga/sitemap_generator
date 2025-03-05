# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# Dev libs
gem 'appraisal', git: 'https://github.com/thoughtbot/appraisal.git'
gem 'aws-sdk-core'
gem 'aws-sdk-s3'
gem 'combustion'
gem 'fog-aws'
gem 'google-cloud-storage'
gem 'rails'
gem 'rake'
gem 'rspec'
gem 'rspec_junit_formatter'
gem 'rspec-rails'
gem 'simplecov'
gem 'sqlite3', '~> 2.1.0'
gem 'webmock'

if RUBY_VERSION.match?(/2.5.*/)
  gem 'nokogiri', '1.12.5'
else
  gem 'nokogiri'
end

group :test do
  gem 'byebug'
end

# Dev tools / linter
gem 'rubocop',             require: false
gem 'rubocop-performance', require: false
gem 'rubocop-rake',        require: false
gem 'rubocop-rspec',       require: false
