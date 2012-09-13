require 'fog'

module SitemapGenerator
	class FogAdapter
		include Singleton

		@configuration = Config.new
		@storage = nil

		def self.configure(&block)
			block.call @configuration
			return self
		end

		# Call with a SitemapLocation and string data
		def self.write(location, raw_data)
			SitemapGenerator::FileAdapter.new.write(location, raw_data)

			@storage = self.connect if !@storage
			directory = @storage.directories.get(@configuration.fog_directory)

			directory.files.create(
				:key    => location.path_in_public, 
				:body   => File.open(location.path),
				:public => true
			)
		end

		private

		def self.connect
			@connection = Fog::Storage.new(@configuration.credentials.to_hash)
		end
	end
end
