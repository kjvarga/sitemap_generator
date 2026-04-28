require 'spec_helper'

RSpec.describe "SitemapGenerator::Railtie" do
  let(:app) { Rails.application }
  let(:config) { app.config }
  let(:initializers) { app.initializers.index_by(&:name) }

  it "adds a top-level configuration namespace" do
    expect(config.sitemap).to be_a ActiveSupport::OrderedOptions
  end

  after { config.sitemap.clear }

  describe "set_configs initializer" do
    subject(:initializer) { initializers["sitemap_generator.set_configs"] }

    describe ".default_host" do
      after { app.routes.default_url_options = config.action_controller.default_url_options = {} }

      it "ignores Rails if set directly" do
        app.routes.default_url_options = { host: "from_routes.test" }
        config.sitemap.default_host = "http://custom.test"

        initializer.run(app)

        expect(config.sitemap.default_host).to eq "http://custom.test"
      end

      it "is inferred from Rails' routes default_url_options" do
        app.routes.default_url_options = { host: "from_routes.test" }

        initializer.run(app)

        expect(config.sitemap.default_host).to eq "http://from_routes.test"
      end

      it "falls back to action_mailer, action_controller, and active_job" do
        config.action_controller.default_url_options = { host: "from_action_controller.test" }

        initializer.run(app)

        expect(config.sitemap.default_host).to eq "http://from_action_controller.test"
      end

      it "doesn't construct a default_host if missing :host" do
        config.action_controller.default_url_options = { trailing_slash: true }

        initializer.run(app)

        expect(config.sitemap.default_host).to be_nil
      end
    end

    describe ".sitemaps_host" do
      after { config.asset_host = config.action_controller.asset_host = nil }

      it "can be set directly" do
        config.action_controller.asset_host = "http://from_action_controller.test"
        config.sitemap.sitemaps_host = "http://custom.test"

        initializer.run(app)

        expect(config.sitemap.sitemaps_host).to eq "http://custom.test"
      end

      it "is inferred from action_controller/assets_host" do
        config.action_controller.asset_host = "http://from_action_controller.test"

        initializer.run(app)

        expect(config.sitemap.sitemaps_host).to eq "http://from_action_controller.test"
      end

      it "doesn't accept procs" do
        config.action_controller.asset_host = -> { "dynamically construct hsot" }

        initializer.run(app)

        expect(config.sitemap.sitemaps_host).to be_nil
      end
    end

    describe ".compress" do
      # config.assets provided by Propshaft or Sprockets
      before { config.assets = ActiveSupport::OrderedOptions[{gzip: true}] }
      after { config.assets = nil }

      it "is inferred from config.assets.gzip" do
        initializer.run(app)

        expect(config.sitemap.compress).to be true
      end

      it "can be set directly (nil != false)" do
        config.sitemap.compress = false

        initializer.run(app)

        expect(config.sitemap.compress).to be false
      end
    end

    describe ".public_path" do
      after { app.paths["public"] = "public" }

      it "can be set directly" do
        config.sitemap.public_path = "custom"

        initializer.run(app)

        expect(config.sitemap.public_path).to eq "custom"
      end

      it "is inferred from Rails paths" do
        app.paths["public"].unshift "inferred"

        initializer.run(app)

        expect(config.sitemap.public_path).to match "/inferred"
      end
    end
  end

  describe "config_file initializer" do
    subject(:initializer) { initializers["sitemap_generator.config_file"] }

    after { ENV.delete "CONFIG_FILE" }

    it "sets CONFIG_FILE" do
      config.sitemap.config_file = "custom.rb"

      expect { initializer.run(app) }
        .to change { ENV["CONFIG_FILE"] }.to("custom.rb")
        .and change(config, :sitemap).from have_key(:config_file)
    end

    it "does not override CONFIG_FILE" do
      ENV["CONFIG_FILE"] = "existing.rb"
      config.sitemap.config_file = "override.rb"

      expect { initializer.run(app) }
        .to_not change { ENV["CONFIG_FILE"] }.from("existing.rb")
    end
  end
end
