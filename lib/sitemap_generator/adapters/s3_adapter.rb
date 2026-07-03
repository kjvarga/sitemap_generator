# frozen_string_literal: true

unless defined?(Fog::Storage)
  raise LoadError, "Error: `Fog::Storage` is not defined.\n\n" \
                   "Please `require 'fog-aws'` - or another library that defines this class."
end

module SitemapGenerator
  # Class for uploading sitemaps to an S3 bucket using the Fog gem.
  class S3Adapter
    # Requires Fog::Storage to be defined.
    #
    # @param [Hash] opts Fog configuration options
    # @option :aws_access_key_id [String] Your AWS access key id
    # @option :aws_secret_access_key [String] Your AWS secret access key
    # @option :fog_provider [String]
    # @option :fog_directory [String]
    # @option :fog_region [String]
    # @option :fog_path_style [String]
    # @option :fog_storage_options [Hash] Other options to pass to `Fog::Storage`
    # @option :fog_public [Boolean] Whether the file is publicly accessible
    #
    # Alternatively you can use an environment variable to configure each option (except `fog_storage_options`).
    # The environment variables have the same name but capitalized, e.g. `FOG_PATH_STYLE`.
    def initialize(opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @aws_access_key_id = opts[:aws_access_key_id] || ENV.fetch('AWS_ACCESS_KEY_ID', nil)
      @aws_secret_access_key = opts[:aws_secret_access_key] || ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
      @aws_session_token = opts[:aws_session_token] || ENV.fetch('AWS_SESSION_TOKEN', nil)
      @fog_provider = opts[:fog_provider] || ENV.fetch('FOG_PROVIDER', nil)
      @fog_directory = opts[:fog_directory] || ENV.fetch('FOG_DIRECTORY', nil)
      @fog_region = opts[:fog_region] || ENV.fetch('FOG_REGION', nil)
      @fog_path_style = opts[:fog_path_style] || ENV.fetch('FOG_PATH_STYLE', nil)
      @fog_storage_options = opts[:fog_storage_options] || {}
      fog_public = opts[:fog_public].nil? ? ENV.fetch('FOG_PUBLIC', nil) : opts[:fog_public]
      @fog_public = !SitemapGenerator::Utilities.falsy?(fog_public)
    end

    # Call with a SitemapLocation and string data
    def write(location, raw_data) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      credentials = { provider: @fog_provider }

      if @aws_access_key_id && @aws_secret_access_key
        credentials[:aws_access_key_id] = @aws_access_key_id
        credentials[:aws_secret_access_key] = @aws_secret_access_key
        credentials[:aws_session_token] = @aws_session_token if @aws_session_token
      else
        credentials[:use_iam_profile] = true
      end

      credentials[:region] = @fog_region if @fog_region
      credentials[:path_style] = @fog_path_style if @fog_path_style

      storage   = Fog::Storage.new(@fog_storage_options.merge(credentials))
      directory = storage.directories.new(key: @fog_directory)
      directory.files.create(
        key: location.path_in_public,
        body: File.open(location.path),
        public: @fog_public,
        content_type: /\.gz$/.match?(location.path_in_public.to_s) ? 'application/x-gzip' : 'application/xml'
      )
    end
  end
end
