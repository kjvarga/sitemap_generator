# frozen_string_literal: true

module SitemapGenerator
  # Loads sitemap_generator rake tasks automatically when the gem is used in a Rails app.
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/sitemap_generator_tasks.rake'
    end
  end
end
