if !defined?(Google::Cloud::Storage)
  raise LoadError, "Error: `Google::Cloud::Storage` is not defined.\n\n"\
        "Please `require 'google/cloud/storage'` - or another library that defines this class."
end

module SitemapGenerator
  # Class for uploading sitemaps to a Google Storage using `google-cloud-storage` gem.
  class GoogleStorageAdapter
    # Requires Google::Cloud::Storage to be defined.
    #
    # @param [Hash] opts Google::Cloud::Storage configuration options.
    # @option :bucket [String] Required. Name of Google Storage Bucket where the file is to be uploaded.
    # @option :acl [String] Optional. Access control which is applied to the uploaded file(s).  Default value is 'public'.
    #
    # All options other than the `:bucket` and `:acl` options are passed to the `Google::Cloud::Storage.new`
    # initializer.  See https://googleapis.dev/ruby/google-cloud-storage/latest/file.AUTHENTICATION.html
    # for all the supported environment variables and https://github.com/googleapis/google-cloud-ruby/blob/master/google-cloud-storage/lib/google/cloud/storage.rb
    # for supported options.
    #
    # Suggested Options:
    # @option :credentials [String] Path to Google service account JSON file, or JSON contents.
    # @option :project_id [String] Google Accounts project id where the storage bucket resides.
    def initialize(opts = {})
      opts = opts.clone
      @bucket = opts.delete(:bucket)
      @acl = opts.has_key?(:acl) ? opts.delete(:acl) : 'public'
      @storage_options = opts
    end

    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      storage = Google::Cloud::Storage.new(**@storage_options)
      bucket = storage.bucket(@bucket)
      bucket.create_file(location.path, location.path_in_public, acl: @acl)
    end
  end
end
