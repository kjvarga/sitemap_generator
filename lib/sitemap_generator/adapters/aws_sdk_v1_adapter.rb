begin
  require 'aws-sdk-v1'
rescue LoadError
  raise LoadError.new("Missing required 'aws-sdk-v1'.  Please 'gem install "\
                      "aws-sdk-v1' and require it in your application, or "\
                      "add: gem 'aws-sdk-v1' to your Gemfile.")
end

module SitemapGenerator
  # Class for uploading the sitemaps to an S3 bucket using the plain AWS SDK gem
  class AwsSdkAdapter
    # @param [String] bucket name of the S3 bucket
    # @param [Hash]   opts   alternate means of configuration other than ENV
    # @option opts  [String] :aws_access_key_id instead of ENV['AWS_ACCESS_KEY_ID']
    # @option opts  [String] :aws_secret_access_key instead of ENV['AWS_SECRET_ACCESS_KEY']
    # @option opts  [String] :path use this prefix on the object key instead of 'sitemaps/'
    def initialize(bucket, opts = {})
      @bucket = bucket

      @aws_access_key_id = opts[:aws_access_key_id] || ENV['AWS_ACCESS_KEY_ID']
      @aws_secret_access_key = opts[:aws_secret_access_key] || ENV['AWS_SECRET_ACCESS_KEY']

      @path = opts[:path] || 'sitemaps/'
    end

    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      s3 = AWS::S3.new(
        access_key_id: @aws_access_key_id,
        secret_access_key: @aws_secret_access_key
      )

      s3_object_key = "#{@path}#{location.filename}"
      bucket = s3.buckets[@bucket]

      begin
        object = bucket.objects[s3_object_key]
        object.write(file: location.path)
      rescue Exception => e
        raise e
      end
    end
  end
end
