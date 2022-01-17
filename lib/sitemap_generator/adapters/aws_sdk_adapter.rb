if !defined?(Aws::S3::Resource) or !defined?(Aws::Credentials)
  raise LoadError, "Error: `Aws::S3::Resource` and/or `Aws::Credentials` are not defined.\n\n"\
        "Please `require 'aws-sdk'` - or another library that defines these classes."
end

module SitemapGenerator
  # Class for uploading sitemaps to an S3 bucket using the AWS SDK gem.
  class AwsSdkAdapter
    # Specify your AWS bucket name, credentials, and/or region.  By default
    # the AWS SDK will auto-detect your credentials and region, but you can use
    # the options to configure them manually.
    #
    # Requires Aws::S3::Resource and Aws::Credentials to be defined.
    #
    # @param bucket [String] Name of the S3 bucket
    # @param options [Hash] Options passed directly to AWS to control the Resource created.  See Options below.
    #
    # Options:
    #   **Deprecated, use :access_key_id instead** :access_key_id [String] Your AWS access key id
    #   **Deprecated, use :secret_access_key instead** :aws_secret_access_key [String] Your AWS secret access key
    #   **Deprecated, use :region instead** :aws_region [String] Your AWS region
    #
    #   All other options you provide are passed directly to the AWS client.
    #   See https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/S3/Client.html#initialize-instance_method
    #   for a full list of supported options.
    def initialize(bucket, aws_access_key_id: nil, aws_secret_access_key: nil, aws_region: nil, **options)
      @bucket = bucket
      @options = options
      @options[:credentials] = Aws::Credentials.new(
        aws_access_key_id,
        aws_secret_access_key
      ) if aws_access_key_id && aws_secret_access_key
      @options[:region] = aws_region
    end

    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)
      s3_object = s3_resource.bucket(@bucket).object(location.path_in_public)
      s3_object.upload_file(location.path,
        acl: 'public-read',
        cache_control: 'private, max-age=0, no-cache',
        content_type: location[:compress] ? 'application/x-gzip' : 'application/xml'
      )
    end

    private

    def s3_resource
      @s3_resource ||= Aws::S3::Resource.new(@options)
    end
  end
end
