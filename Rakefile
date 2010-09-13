require 'rake'
require 'rake/rdoctask'
require 'rubygems'
gem 'rspec', '1.3.0'
require 'spec/rake/spectask'
gem 'nokogiri'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "sitemap_generator"
    gem.summary = %Q{Easily generate enterprise class Sitemaps for your Rails site using a familiar Rails Routes-like DSL}
    gem.description = %Q{SitemapGenerator is a Rails gem that makes it easy to generate enterprise-class Sitemaps readable by all search engines.  Generated Sitemaps adhere to the Sitemap protocol specification.  When you generate new Sitemaps, SitemapGenerator can automatically ping the major search engines (including Google, Yahoo and Bing) to notify them.  SitemapGenerator includes rake tasks to easily manage your sitemaps.}
    gem.email = "kjvarga@gmail.com"
    gem.homepage = "http://github.com/kjvarga/sitemap_generator"
    gem.authors = ["Karl Varga", "Adam Salter"]
    gem.files =  FileList["[A-Z]*", "{bin,lib,rails,templates,tasks}/**/*"]
    gem.test_files = []
    gem.add_development_dependency "rspec"
    gem.add_development_dependency "nokogiri"
    gem.add_development_dependency "sqlite3-ruby"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

#
# Helper methods
#
module Helpers
  extend self

  # Return a full local path to path fragment <tt>path</tt>
  def local_path(path)
    File.join(File.dirname(__FILE__), path)
  end

  # Copy all of the local files into <tt>path</tt> after completely cleaning it
  def prepare_path(path)
    rm_rf path
    mkdir_p path
    cp_r(FileList["[A-Z]*", "{bin,lib,rails,templates,tasks}"], path)
  end
end

#
# Tasks
#
task :default => :test

namespace :test do
  #desc "Test as a gem, plugin and Rails 3 gem"
  #task :all => ['test:gem', 'test:plugin']

  task :gem => ['test:prepare:gem', 'multi_spec']
  task :plugin => ['test:prepare:plugin', 'multi_spec']
  task :rails3 => ['test:prepare:rails3', 'multi_spec']

  task :multi_spec do
    Rake::Task['spec'].invoke
    Rake::Task['spec'].reenable
  end

  namespace :prepare do
    task :gem do
      ENV["SITEMAP_RAILS"] = 'gem'
      Helpers.prepare_path(Helpers.local_path('spec/mock_app_gem/vendor/gems/sitemap_generator-1.2.3'))
      rm_rf(Helpers.local_path('spec/mock_app_gem/public/sitemap*'))
    end

    task :plugin do
      ENV["SITEMAP_RAILS"] = 'plugin'
      Helpers.prepare_path(Helpers.local_path('spec/mock_app_plugin/vendor/plugins/sitemap_generator-1.2.3'))
      rm_rf(Helpers.local_path('spec/mock_app_plugin/public/sitemap*'))
    end

    task :rails3 do
      ENV["SITEMAP_RAILS"] = 'rails3'
      rm_rf(Helpers.local_path('spec/mock_rails3_gem/public/sitemap*'))
    end
  end
end

desc "Run tests as a gem install"
task :test => ['test:gem']

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end
task :spec => :check_dependencies

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

desc 'Generate documentation'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'SitemapGenerator'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :release do

  desc "Release a new patch version"
  task :patch do
    Rake::Task['version:bump:patch'].invoke
    Rake::Task['release:current'].invoke
  end

  desc "Release the current version (e.g. after a version bump).  This rebuilds the gemspec, pushes the updated code, tags it and releases to RubyGems"
  task :current do
    Rake::Task['github:release'].invoke
    Rake::Task['git:release'].invoke
    Rake::Task['gemcutter:release'].invoke
  end
end