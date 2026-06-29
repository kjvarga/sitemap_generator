# encoding: utf-8
# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'sitemap_generator'
  s.version = File.read('VERSION').chomp
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.6'
  s.authors = ['Karl Varga']
  s.email = 'kjvarga@gmail.com'
  s.homepage = 'https://github.com/kjvarga/sitemap_generator'
  s.summary = 'Easily generate XML Sitemaps'
  s.description = 'SitemapGenerator is a framework-agnostic XML Sitemap generator written in Ruby with automatic Rails integration.  It supports Video, News, Image, Mobile, PageMap and Alternate Links sitemap extensions and includes Rake tasks for managing your sitemaps, as well as many other great features.'
  s.license = 'MIT'
  s.metadata = { 'rubygems_mfa_required' => 'true' }
  s.add_dependency 'builder', '~> 3.0'
  s.files = Dir.glob('{lib,rails,templates}/**/*') + %w[CHANGES.md MIT-LICENSE README.md VERSION]
end
