# frozen_string_literal: true

module SitemapGenerator
  class Railtie < Rails::Railtie
    # Top level options object to namespace all settings
    config.sitemap = ActiveSupport::OrderedOptions.new

    rake_tasks do
      load 'tasks/sitemap_generator_tasks.rake'
    end

    # Recognize existing Rails options as defaults for config.sitemap.*
    initializer 'sitemap_generator.set_configs' do |app|
      # routes.default_url_options takes precedence, falling back to configs
      url_opts = (app.default_url_options || {})
                 .with_defaults(config.try(:action_controller).try(:default_url_options) || {})
                 .with_defaults(config.try(:action_mailer).try(:default_url_options) || {})
                 .with_defaults(config.try(:active_job).try(:default_url_options) || {})

      config.sitemap.default_host ||= ActionDispatch::Http::URL.full_url_for(url_opts) if url_opts.key?(:host)

      # Rails defaults action_controller.asset_host and action_mailer.asset_host
      # to the top-level config.asset_host so we get that for free here.
      config.sitemap.sitemaps_host ||= [
        config.try(:action_controller).try(:asset_host),
        config.try(:action_mailer).try(:asset_host)
      ].grep(String).first

      config.sitemap.compress = config.try(:assets).try(:gzip) if config.sitemap.compress.nil?

      config.sitemap.public_path ||= app.paths['public'].first

      # "Compile" config.sitemap options onto the Sitemap class.
      config.after_initialize do
        ActiveSupport.on_load(:sitemap_generator, yield: true) do |sitemap|
          config.sitemap.except(:adapter).each { |k, v| sitemap.public_send("#{k}=", v) }
        end
      end
    end

    # Allow setting the CONFIG_FILE without relying on env var;
    # (e.g in config/application or environments/*.rb)
    initializer 'sitemap_generator.config_file' do
      if (config_file = config.sitemap.delete(:config_file).presence) && ENV['CONFIG_FILE'].blank?
        ENV['CONFIG_FILE'] = config_file
      end
    end

    # Allow lazily setting the adapter class without forcing an autoload.
    # (ie. string or symbol name; or Callable (proc/lambda/etc))
    initializer 'sitemap_generator.adapter' do |app|
      config.to_prepare do
        ActiveSupport.on_load(:sitemap_generator) do
          self.adapter = Utilities.find_adapter app.config.sitemap.adapter
        end
      end
    end
  end

  ActiveSupport.run_load_hooks(:sitemap_generator, Sitemap)
end
