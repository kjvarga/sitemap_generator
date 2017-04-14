# any number of storage method sub-gems, ex. fog-rackspace, could define this without
# requiring the whole (large) fog project. If not, though, try loading everything.
if !defined?(Fog::Storage)
  begin
    require 'fog'
  rescue LoadError
    raise LoadError.new("Missing required 'fog'.  Please 'gem install fog' and require it in your application.")
  end
end

module SitemapGenerator
  class FogAdapter

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
