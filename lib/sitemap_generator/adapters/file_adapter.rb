module SitemapGenerator
  class FileAdapter
    def write(location, raw_data)
      # Ensure that the directory exists
      dir = location.directory
      if !File.exists?(dir)
        FileUtils.mkdir_p(dir)
      elsif !File.directory?(dir)
        raise SitemapError.new("#{dir} should be a directory!")
      end

      stream = open(location.path, 'wb')
      if location.path.ends_with? '.gz'
        gzip(stream, raw_data)
      else
        plain(stream, raw_data)
      end
    end

    def gzip(stream, data)
      gz = Zlib::GzipWriter.new(stream)
      gz.write data
      gz.close
    end

    def plain(stream, data)
      stream.write data
      stream.close
    end
  end
end
