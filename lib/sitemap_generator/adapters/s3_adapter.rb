if !defined?(Fog::Storage)
  raise LoadError, "Error: `Fog::Storage` is not defined.\n\n"\
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
    def initialize(opts = {})
      @aws_access_key_id = opts[:aws_access_key_id] || ENV['AWS_ACCESS_KEY_ID']
      @aws_secret_access_key = opts[:aws_secret_access_key] || ENV['AWS_SECRET_ACCESS_KEY']
      @fog_provider = opts[:fog_provider] || ENV['FOG_PROVIDER']
      @fog_directory = opts[:fog_directory] || ENV['FOG_DIRECTORY']
      @fog_region = opts[:fog_region] || ENV['FOG_REGION']
      @fog_path_style = opts[:fog_path_style] || ENV['FOG_PATH_STYLE']
      @fog_storage_options = opts[:fog_storage_options] || {}
      fog_public = opts[:fog_public].nil? ? ENV['FOG_PUBLIC'] : opts[:fog_public]
      @fog_public = SitemapGenerator::Utilities.falsy?(fog_public) ? false : true
    end

    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      credentials = { :provider => @fog_provider }

      if @aws_access_key_id && @aws_secret_access_key
        credentials[:aws_access_key_id] = @aws_access_key_id
        credentials[:aws_secret_access_key] = @aws_secret_access_key
      else
        credentials[:use_iam_profile] = true
      end

      credentials[:region] = @fog_region if @fog_region
      credentials[:path_style] = @fog_path_style if @fog_path_style

      storage   = Fog::Storage.new(@fog_storage_options.merge(credentials))
      directory = storage.directories.new(:key => @fog_directory)
      directory.files.create(
        :key    => location.path_in_public,
        :body   => File.open(location.path),
        :public => @fog_public
      )
    end
  end
end
