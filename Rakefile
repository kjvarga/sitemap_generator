# frozen_string_literal: true

require 'bundler/setup'
Bundler.require

desc 'Default: run spec tests.'
task default: :spec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = Dir.glob(['spec/sitemap_generator/**/*'])
  spec.rspec_opts = ['--backtrace']
end

#
# Helpers
#

def name
  @name ||= Dir['*.gemspec'].first.split('.').first
end

def version
  File.read('VERSION').chomp
end

def gemspec_file
  "#{name}.gemspec"
end

def gem_file
  "#{name}-#{version}.gem"
end

#
# Release Tasks.  To be run from the directory of this file.
# @see https://github.com/mojombo/rakegem
#

desc "Build and prepare #{gem_file} into the pkg/ directory"
task build: [:prepare] do
  sh 'mkdir -p pkg'
  sh "gem build #{gemspec_file}"
  sh "mv #{gem_file} pkg"
  sh 'bundle --local'
end

desc 'Chmod all files to be world readable'
task :prepare do
  sh 'chmod -R a+r *.* *'
end

desc "Create tag v#{version}, build the gem and push to Git"
task release: [:build] do
  unless /^\* master$/.match?(`git branch`)
    puts 'You must be on the master branch to release!'
    exit!
  end
  sh "git tag v#{version}"
  sh 'git push origin master --tags'
end
