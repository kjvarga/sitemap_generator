module SitemapGenerator
	class Config
		def initialize(data={})
			@data = {}
			update!(data)
		end

		def update!(data)
			data.each do |key, value|
				self[key] = value
			end
		end

		def [](key)
			@data[key.to_sym]
		end

		def []=(key, value)
			if value.class == Hash
				@data[key.to_sym] = Config.new(value)
			else
				@data[key.to_sym] = value
			end
		end

		def method_missing(sym, *args)
			if sym.to_s =~ /(.+)=$/
				self[$1] = args.first
			else
				self[sym]
			end
		end

		def to_hash
			data = {}
			@data.each do |k,v|
				data[k] = v.kind_of?(Config) ? v.to_hash : v
			end

			return data
		end
		
	end
end