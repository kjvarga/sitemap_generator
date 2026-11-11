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
    # If `path` is a symlink, its target is replaced and the symlink is kept. As when writing in
    # place, the mode and, if permitted, the owner of the previous file are kept.
    def write_atomically(path, &block)
      path = resolve_symlinks(path)
      # Hidden, so that a web server or a directory listing does not show it while it is written.
      temp_name = ".#{File.basename(path)}.#{Process.pid}.#{Thread.current.object_id}.tmp"
      temp_path = File.join(File.dirname(path), temp_name)
      File.open(temp_path, 'wb', &block)
      copy_permissions(path, temp_path)
      File.rename(temp_path, path)
    ensure
      FileUtils.rm_f(temp_path) if temp_path
    end

    # Follow `path` through symlinks, including a dangling one, to the file to write.
    def resolve_symlinks(path)
      40.times do # the usual operating system limit (ELOOP)
        return path unless File.symlink?(path)

        path = File.expand_path(File.readlink(path), File.dirname(path))
      end
      raise Errno::ELOOP, path
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
        # Only root can give a file to another user: keep the current user, as File.atomic_write does.
      end
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
