# frozen_string_literal: true

module SitemapGenerator
  # Class for writing out data to a file.
  class FileAdapter
    # Write data to a file.
    # @param location - File object giving the full path and file name of the file.
    #    If the location specifies a directory(ies) which does not exist, the directory(ies)
    #    will be created for you.  If the location path ends with `.gz` the data will be
    #    compressed prior to being written out.  Otherwise the data will be written out
    #    unchanged.
    # @param raw_data - data to write to the file.
    def write(location, raw_data)
      # Ensure that the directory exists
      dir = location.directory
      if !File.exist?(dir)
        FileUtils.mkdir_p(dir)
      elsif !File.directory?(dir)
        raise SitemapError.new("#{dir} should be a directory!")
      end

      stream = open(location.path, 'wb')
      if location.path.to_s =~ /.gz$/
        gzip(stream, raw_data)
      else
        plain(stream, raw_data)
      end
    end

    # Write `data` to a stream, passing the data through a GzipWriter
    # to compress it.
    def gzip(stream, data)
      gz = Zlib::GzipWriter.new(stream)
      gz.write data
      gz.close
    end

    # Write `data` to a stream as is.
    def plain(stream, data)
      stream.write data
      stream.close
    end
  end
end
