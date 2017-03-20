# this adapter never writes to a file.  However, it exposes the entire sitemap file as a string that can be cached using rails caching or any other means
# this should only be used with small sitemaps.  Can also be useful for multi tenant applications where you want to generate a sitemap for each tenant independently
#

# in your controller
#     data = Rails.cache.fetch("sitemap", expires_in: 12.hours) do
#
#       adapter = SitemapGenerator::NeverWriteAdapter.new
#
#       SitemapGenerator::Sitemap.create(
#              :default_host => 'http://example.com',
#              :adapter => adapter) do
#          # your custom model queries
#          Listing.where(deleted: false, open: true, community_id: 1).find_each do |listing|
#            add listing_path(listing), :lastmod => listing.updated_at
#          end
#       end
#       data = adapter.get_data
#     end
#     # do what you want with data


module SitemapGenerator
  class NeverWriteAdapter
    @data 
    def write(location, raw_data)
      # never write
      @data = raw_data
    end

    def plain(stream, data)
      # never write

    end
    def gzip(stream, data)
      # never write
    end

    def get_data
      @data
    end
  end
end
