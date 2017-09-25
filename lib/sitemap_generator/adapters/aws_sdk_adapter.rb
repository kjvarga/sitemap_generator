begin
  require 'aws-sdk-s3'
rescue LoadError
  raise LoadError.new("Missing required 'aws-sdk-s3'.  Please 'gem install "\
                      "aws-sdk-s3' and require it in your application, or "\
                      "add: gem 'aws-sdk-s3' to your Gemfile.")
end

module SitemapGenerator
  # Class for uploading the sitemaps to an S3 bucket using the plain AWS SDK gem
  class AwsSdkAdapter
    # @param [String] bucket name of the S3 bucket
    # @param [Hash]   opts   alternate means of configuration other than ENV
    # @option opts  [String] :aws_access_key_id instead of ENV['AWS_ACCESS_KEY_ID']
    # @option opts  [String] :aws_region instead of ENV['AWS_REGION']
    # @option opts  [String] :aws_secret_access_key instead of ENV['AWS_SECRET_ACCESS_KEY']
    # @option opts  [String] :path use this prefix on the object key instead of 'sitemaps/'
    def initialize(bucket, opts = {})
      @bucket = bucket

      @aws_access_key_id = opts[:aws_access_key_id]
      @aws_region = opts[:aws_region]
      @aws_secret_access_key = opts[:aws_secret_access_key]

      @path = opts[:path] || 'sitemaps/'
    end

    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      s3_object_key = "#{@path}#{location.path_in_public}"
      s3_object = s3_resource.bucket(@bucket).object(s3_object_key)

      content_type = location[:compress] ? 'application/x-gzip' : 'application/xml'
      s3_object.upload_file(location.path,
                            acl: 'public-read',
                            cache_control: 'private, max-age=0, no-cache',
                            content_type: content_type)
    end

    private

    def s3_resource
      @s3_resource ||= Aws::S3::Resource.new(s3_resource_option)
    end

    def s3_resource_option
      option = {}
      if has_specific_region?
        option[:region] = @aws_region
      end
      if has_specific_credential?
        option[:credentials] = Aws::Credentials.new(
          @aws_access_key_id,
          @aws_secret_access_key
        )
      end
      option
    end

    def has_specific_region?
      !@aws_region.nil?
    end

    def has_specific_credential?
      !@aws_access_key_id.nil? && !@aws_secret_access_key.nil?
    end
  end
end
