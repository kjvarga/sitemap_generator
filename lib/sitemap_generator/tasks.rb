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
    require 'sitemap_generator'
  end
  # In a Rails app, we need to boot Rails.
  # Ensure gem is required in case it wasn't automatically loaded.
  Rake::Task[:require].enhance([:environment]) if defined?(Rails)

  desc 'Install a default config/sitemap.rb file'
  task install: :require do
    SitemapGenerator::Utilities.install_sitemap_rb(verbose)
  end

  desc 'Delete all Sitemap files in public/ directory'
  task clean: :require do
    SitemapGenerator::Utilities.clean_files
  end

  desc 'Generate sitemaps and ping search engines.'
  task refresh: :create do
    SitemapGenerator::Sitemap.ping_search_engines
  end

  desc "Generate sitemaps but don't ping search engines."
  task 'refresh:no_ping' => :create

  desc "Generate sitemaps but don't ping search engines.  Alias for refresh:no_ping."
  task create: :require do
    SitemapGenerator::Interpreter.run(config_file: ENV['CONFIG_FILE'], verbose: verbose)
  end
end
