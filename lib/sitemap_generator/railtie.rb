# frozen_string_literal: true

module SitemapGenerator
  class Railtie < Rails::Railtie # rubocop:disable Style/Documentation
    rake_tasks do
      load 'tasks/sitemap_generator_tasks.rake'
    end
  end
end
