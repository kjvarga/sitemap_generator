module SitemapGenerator
  # Class for uploading sitemaps to ActiveStorage.
  class ActiveStorageAdapter
    attr_reader :key, :filename

    def initialize key: :sitemap, filename: 'sitemap.xml.gz'
      @key, @filename = key, filename
    end

    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      ActiveStorage::Blob.transaction do
        ActiveStorage::Blob.where(key: key).destroy_all

        ActiveStorage::Blob.create_and_upload!(
          key: key,
          io: open(location.path, 'rb'),
          filename: filename,
          content_type: 'application/gzip',
          identify: false
        )
      end
    end
  end
end
