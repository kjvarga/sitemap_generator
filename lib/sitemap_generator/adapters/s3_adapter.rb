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
      @fog_key_prefix = opts[:fog_key_prefix] || ""
    end

    # Call with a SitemapLocation and string data
    def write(location, raw_data)

      # write to a temporary file
      file_name = File.basename(location.path)
      temp_file = Tempfile.new(file_name.split('.', 2))

      if location.path.to_s =~ /.gz$/
        temp_file.binmode
        gz = Zlib::GzipWriter.new(temp_file)
        gz.write raw_data
        gz.close
      else
        temp_file.write raw_data
        temp_file.close
      end

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

      key = [@fog_key_prefix, location.path_in_public].join
      directory.files.create(
        :key    => key, 
        :body   => File.open(temp_file.path),
        :public => true
      )
      # delete the temporary file
      temp_file.unlink
    end

  end
end
