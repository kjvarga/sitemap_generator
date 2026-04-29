# frozen_string_literal: true

raise LoadError, <<~MSG unless defined?(ActiveStorage)
  Error: 'ActiveStorage' is not defined.

  Please `require 'active_storage'` - or another library that defines this class.
MSG

module SitemapGenerator
  # Class for uploading sitemaps to ActiveStorage.
  class ActiveStorageAdapter
    def initialize(prefix: nil)
      @prefix = Pathname.new prefix.to_s
    end

    def write(location, raw_data)
      FileAdapter.new.write(location, raw_data)

      ActiveStorage::Blob.transaction do
        ActiveStorage::Blob.destroy_by(key: key(location))

        ActiveStorage::Blob.create_and_upload!(
          key: key(location),
          io: File.open(location.path),
          filename: location.filename,
          content_type: content_type(location),
          identify: false
        )
      end
    end

    private

    def key(location)
      (@prefix / location.path_in_public).to_s
    end

    def content_type(location)
      # Using .gz matching to be consistent with FileAdapter
      # but this logic is brittle and needs refactored
      "application/#{location.path.match?(/.gz$/) ? 'gzip' : 'xml'}"
    end
  end
end
