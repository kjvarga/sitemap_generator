require 'pathname'

module SitemapGenerator
  class Application
    def rails?
      defined?(Rails::Railtie)
    end

    # Returns a boolean indicating whether this environment is Rails 3
    #
    # @return [Boolean]
    def rails3?
      rails? && Rails.version.to_f >= 3
    rescue
      false # Rails.version defined in 2.1.0
    end

    def root
      Pathname.new(rails_root || Dir.getwd)
    end

    protected

    # Returns the root of the Rails application,
    # if this is running in a Rails context.
    # Returns `nil` if no such root is defined.
    #
    # @return [String, nil]
    def rails_root
      if defined?(::Rails.root)
        return ::Rails.root.to_s if ::Rails.root
        raise "ERROR: Rails.root is nil!"
      end
      return RAILS_ROOT.to_s if defined?(RAILS_ROOT)
      return nil
    end

    # Returns the environment of the Rails application,
    # if this is running in a Rails context.
    # Returns `nil` if no such environment is defined.
    #
    # @return [String, nil]
    def rails_env
      return ::Rails.env.to_s if defined?(::Rails.env)
      return RAILS_ENV.to_s if defined?(RAILS_ENV)
      return nil
    end
  end
end
