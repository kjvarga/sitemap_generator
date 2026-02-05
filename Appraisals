# frozen_string_literal: true

appraise 'rails_6.0' do
  gem 'rails', '~> 6.0.0'
  gem 'sqlite3', '~> 1.5.0'

  # Fix:
  # warning: drb was loaded from the standard library, but is not part of the default gems starting from Ruby 3.4.0.
  # You can add drb to your Gemfile or gemspec to silence this warning.
  install_if '-> { Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4.0") }' do
    gem 'drb'
    gem 'mutex_m'
  end
end

appraise 'rails_6.1' do
  gem 'rails', '~> 6.1.0'
  gem 'sqlite3', '~> 1.5.0'

  # Fix:
  # warning: drb was loaded from the standard library, but is not part of the default gems starting from Ruby 3.4.0.
  # You can add drb to your Gemfile or gemspec to silence this warning.
  install_if '-> { Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4.0") }' do
    gem 'drb'
    gem 'mutex_m'
  end
end

appraise 'rails_7.0' do
  gem 'rails', '~> 7.0.0'
  gem 'sqlite3', '~> 1.5.0'

  # Fix:
  # warning: drb was loaded from the standard library, but is not part of the default gems starting from Ruby 3.4.0.
  # You can add drb to your Gemfile or gemspec to silence this warning.
  install_if '-> { Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4.0") }' do
    gem 'drb'
    gem 'mutex_m'
  end
end

appraise 'rails_7.1' do
  gem 'rails', '~> 7.1.0'
  gem 'sqlite3', '~> 1.5.0'
end

appraise 'rails_7.2' do
  gem 'rails', '~> 7.2.0'
  gem 'sqlite3', '~> 1.5.0'
end

appraise 'rails_8.0' do
  gem 'rails', '~> 8.0.0'
end

appraise 'rails_8.1' do  
  gem 'rails', '8.1.0'
end
