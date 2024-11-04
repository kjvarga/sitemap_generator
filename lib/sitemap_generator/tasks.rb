# frozen_string_literal: true

# require this file to load the tasks
require 'rake'

# Require sitemap_generator at runtime.  If we don't do this the ActionView helpers are included
# before the Rails environment can be loaded by other Rake tasks, which causes problems
# for those tasks when rendering using ActionView.
namespace :sitemap do
  # Require sitemap_generator only.  When installed as a plugin the require will fail, so in
  # that case, load the environment first.
  task :require do
    begin
      require 'sitemap_generator'
    rescue LoadError => e
      if defined?(Rails::VERSION)
        Rake::Task['sitemap:require_environment'].invoke
      else
        raise e
      end
    end
  end

  # Require sitemap_generator after loading the Rails environment.  We still need the require
  # in case we are installed as a gem and are setup to not automatically be required.
  task :require_environment do
    if defined?(Rails::VERSION)
      Rake::Task['environment'].invoke
    end
    require 'sitemap_generator'
  end

  desc "Install a default config/sitemap.rb file"
  task :install => ['sitemap:require'] do
    SitemapGenerator::Utilities.install_sitemap_rb(verbose)
  end

  desc "Delete all Sitemap files in public/ directory"
  task :clean => ['sitemap:require'] do
    SitemapGenerator::Utilities.clean_files
  end

  desc "Generate sitemaps and ping search engines."
  task :refresh => ['sitemap:create'] do
    SitemapGenerator::Sitemap.ping_search_engines
  end

  desc "Generate sitemaps but don't ping search engines."
  task 'refresh:no_ping' => ['sitemap:create']

  desc "Generate sitemaps but don't ping search engines.  Alias for refresh:no_ping."
  task :create => ['sitemap:require_environment'] do
    SitemapGenerator::Interpreter.run(:config_file => ENV["CONFIG_FILE"], :verbose => verbose)
  end
end
