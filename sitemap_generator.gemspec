# encoding: utf-8

Gem::Specification.new do |s|
  s.name = 'sitemap_generator'
  s.version = File.read('VERSION').chomp
  s.platform = Gem::Platform::RUBY
  s.authors = ['Karl Varga']
  s.email = 'kjvarga@gmail.com'
  s.homepage = 'https://github.com/kjvarga/sitemap_generator'
  s.summary = 'Easily generate XML Sitemaps'
  s.description = 'SitemapGenerator is a framework-agnostic XML Sitemap generator written in Ruby with automatic Rails integration.  It supports Video, News, Image, Mobile, PageMap and Alternate Links sitemap extensions and includes Rake tasks for managing your sitemaps, as well as many other great features.'
  s.license = 'MIT'
  s.add_dependency 'builder', '~> 3.0'
  s.add_development_dependency 'aws-sdk-core'
  s.add_development_dependency 'aws-sdk-s3'
  s.add_development_dependency 'fog-aws'
  s.add_development_dependency 'google-cloud-storage'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec_junit_formatter'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'webmock'
  s.files = Dir.glob('{lib,rails,templates}/**/*') + %w(CHANGES.md MIT-LICENSE README.md VERSION)
end
