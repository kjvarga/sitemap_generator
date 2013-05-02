require 'aws-sdk'

module SitemapGenerator
  class AwsAdapter
    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      # Check to see if s3.yml exists
      begin
        s3config = YAML::load(File.open("#{Rails.root}/config/s3.yml"))
      rescue
        e.message << " (s3.yml is missing)"
        raise e
      end
      # Check to make sure keys are good.
      begin
        s3 = AWS::S3.new(
        :access_key_id     => s3config[Rails.env.to_s]["access_key_id"],
        :secret_access_key => s3config[Rails.env.to_s]["secret_access_key"]
        )
        bucket = s3.buckets[s3config[Rails.env.to_s]["bucket"]]
      rescue
        e.message << "Failed To Connct to S3"
        raise e
      end

      file = SitemapGenerator::FileAdapter.new.write(location, raw_data)
      filename = file.path.split("/").last
      obj = bucket.objects[SitemapGenerator::Sitemap.sitemaps_path + filename]
      content = File.read(file.path)
      obj.write(content)
      obj.acl=:public_read
    end
  end
end
