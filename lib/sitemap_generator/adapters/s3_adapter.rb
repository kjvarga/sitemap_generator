require 'fog'

module SitemapGenerator
  class S3Adapter

    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)
      
      credentials = { 
        :aws_access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
        :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
        :provider              => ENV['FOG_PROVIDER'],
      }
      
      storage   = Fog::Storage.new(credentials)
      directory = storage.directories.get(ENV['FOG_DIRECTORY'])
      directory.files.create(
        :key    => location.path_in_public, 
        :body   => File.open(location.path),
        :public => true
      )
    end
  end
end
