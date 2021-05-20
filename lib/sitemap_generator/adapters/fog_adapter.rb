if !defined?(Fog::Storage)
  raise LoadError, "Error: `Fog::Storage` is not defined.\n\n"\
        "Please `require 'fog'` - or another library that defines this class."
end

module SitemapGenerator
  # Class for uploading sitemaps to a Fog supported endpoint.
  class FogAdapter
    # Requires Fog::Storage to be defined.
    #
    # @param [Hash] opts Fog configuration options
    # @option :fog_credentials [Hash] Credentials for connecting to the remote server
    # @option :fog_directory [String] Your AWS S3 bucket or similar directory name
    def initialize(opts = {})
      @fog_credentials = opts[:fog_credentials]
      @fog_directory = opts[:fog_directory]
    end

    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      storage   = Fog::Storage.new(@fog_credentials)
      directory = storage.directories.new(:key => @fog_directory)
      directory.files.create(
        :key    => location.path_in_public,
        :body   => File.open(location.path),
        :public => true
      )
    end
  end
end
