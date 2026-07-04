# frozen_string_literal: true

raise LoadError, "ActiveStorage is not available. Add 'activestorage' to your Gemfile." unless defined?(ActiveStorage)

module SitemapGenerator
  # Class for uploading sitemaps to ActiveStorage.
  class ActiveStorageAdapter
    def write(location, raw_data) # rubocop:disable Metrics/MethodLength
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      key = location.path_in_public
      ActiveStorage::Blob.transaction do
        ActiveStorage::Blob.where(key: key).destroy_all

        File.open(location.path, 'rb') do |io|
          ActiveStorage::Blob.create_and_upload!(
            key: key,
            io: io,
            filename: location.filename.to_s,
            content_type: location.content_type,
            identify: false
          )
        end
      end
    end
  end
end
