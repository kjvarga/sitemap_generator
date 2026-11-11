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
    #
    #    The data is written to a temporary file in the same directory which is then renamed,
    #    so the file is replaced atomically: readers (a web server, a crawler) never see a
    #    partially written file, and the previous file is kept if writing fails.
    # @param raw_data - data to write to the file.
    def write(location, raw_data)
      ensure_directory(location.directory)
      write_atomically(location.path) do |stream|
        if location.gzip?
          gzip(stream, raw_data)
        else
          stream.write raw_data
        end
      end
    end

    private

    # Create `dir` if it does not exist.
    def ensure_directory(dir)
      if !File.exist?(dir)
        FileUtils.mkdir_p(dir)
      elsif !File.directory?(dir)
        raise SitemapError, "#{dir} should be a directory!"
      end
    end

    # Yield a stream to a temporary file in the same directory as `path`, then rename it to `path`.
    # If `path` is a symlink, its target is replaced and the symlink is kept.
    def write_atomically(path, &block)
      path = File.realpath(path) if File.symlink?(path) && File.exist?(path)
      temp_path = "#{path}.#{Process.pid}.#{Thread.current.object_id}.tmp"
      File.open(temp_path, 'wb', &block)
      File.rename(temp_path, path)
    ensure
      FileUtils.rm_f(temp_path)
    end

    # Write `data` to a stream, passing the data through a GzipWriter
    # to compress it.
    def gzip(stream, data)
      gz = Zlib::GzipWriter.new(stream)
      gz.write data
      gz.close
    end
  end
end
