begin
  require 'fog/storage'
rescue LoadError
  raise LoadError.new("Missing required 'fog-aws'.  Please 'gem install fog-aws' and require it in your application.")
end

module SitemapGenerator
  class S3Adapter

    def initialize(opts = {})
      @aws_access_key_id = opts[:aws_access_key_id] || ENV['AWS_ACCESS_KEY_ID']
      @aws_secret_access_key = opts[:aws_secret_access_key] || ENV['AWS_SECRET_ACCESS_KEY']
      @fog_provider = opts[:fog_provider] || ENV['FOG_PROVIDER']
      @fog_directory = opts[:fog_directory] || ENV['FOG_DIRECTORY']
      @fog_region = opts[:fog_region] || ENV['FOG_REGION']
      @fog_path_style = opts[:fog_path_style] || ENV['FOG_PATH_STYLE']
      @fog_storage_options = opts[:fog_storage_options] || {}
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
      directory = storage.directories.create(:key => @fog_directory)
      directory.files.create(
        :key    => location.path_in_public,
        :body   => File.open(location.path),
        :public => true
      )
    end

  end
end
