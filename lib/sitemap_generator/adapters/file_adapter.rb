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
      # Replace the target of a symlink, even a dangling one, and keep the symlink. realdirpath resolves
      # a relative target from the real directory of the link, as the operating system does.
      write_atomically(File.realdirpath(location.path)) do |stream|
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
    # As when writing in place, the mode and, if permitted, the owner of the previous file are kept.
    def write_atomically(path)
      temp_path = temp_path_for(path)
      created = false
      # EXCL: never write through, nor remove, a file or a symlink already at that name.
      File.open(temp_path, File::WRONLY | File::CREAT | File::EXCL, binmode: true) do |stream|
        created = true
        yield stream
      end
      copy_permissions(path, temp_path)
      File.rename(temp_path, path)
    ensure
      FileUtils.rm_f(temp_path) if created
    end

    # Hidden, so that a web server or a directory listing does not show it while it is written.
    def temp_path_for(path)
      File.join(File.dirname(path), ".#{File.basename(path)}.#{Process.pid}.#{rand(1 << 32).to_s(36)}.tmp")
    end

    # Give `temp_path` the mode and, if permitted, the owner and group of `path` when it exists.
    def copy_permissions(path, temp_path)
      stat = File.stat(path)
    rescue Errno::ENOENT
      nil
    else
      File.chmod(stat.mode, temp_path)
      begin
        File.chown(stat.uid, stat.gid, temp_path)
      rescue Errno::EPERM, Errno::EACCES
        # Only root can give a file to another user: keep the current user, and the group if permitted.
        keep_group(stat.gid, temp_path)
      end
    end

    def keep_group(gid, temp_path)
      File.chown(nil, gid, temp_path)
    rescue Errno::EPERM, Errno::EACCES
      nil
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
