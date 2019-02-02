if !defined?(Azure::Storage::Blob)
  raise "Error: `Azure::Storage::Blob` is not defined.\n\n"\
        "Please `require 'azure/storage/blob'` - or another library that defines this class."
end


module SitemapGenerator
  # Class for uploading sitemaps to Azure blobs using azure-storage-blob gem.
  class AzureAdapter
    #
    # @param [Hash] opts Azure credentials
    # @option :storage_account_name [String] Your Azure access key id
    # @option :storage_access_key [String] Your Azure secret access key
    # @option :container [String] Name of Azure container for
    def initialize(opts = {})
      @storage_account_name = opts[:azure_storage_account_name] || ENV['AZURE_STORAGE_ACCOUNT_NAME']
      @storage_access_key = opts[:azure_storage_access_key] || ENV['AZURE_STORAGE_ACCESS_KEY']
      @container_name = opts[:azure_storage_sitemaps_container] || ENV['AZURE_STORAGE_SITEMAPS_CONTAINER']
    end

    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      credentials = {
        storage_account_name: @storage_account_name,
        storage_access_key: @storage_access_key
      }

      client = Azure::Storage::Blob::BlobService.create(credentials)
      container_name = @container_name
      content = ::File.open(location.path, 'rb') { |file| file.read }
      client.create_block_blob(container_name, location.filename, content)
    end
  end
end