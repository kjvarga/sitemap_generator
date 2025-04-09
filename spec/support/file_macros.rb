module FileMacros
  def files_should_be_identical(first, second)
    expect(identical_files?(first, second)).to be(true)
  end

  def files_should_not_be_identical(first, second)
    expect(identical_files?(first, second)).to be(false)
  end

  def file_should_exist(file)
    expect(File.exist?(file)).to be(true), 'File #{file} should exist'
  end

  def directory_should_exist(dir)
    expect(File.exist?(dir)).to be(true), 'Directory #{dir} should exist'
    expect(File.directory?(dir)).to be(true), '#{dir} should be a directory'
  end

  def directory_should_not_exist(dir)
    expect(File.exist?(dir)).to be(false), 'Directory #{dir} should not exist'
  end

  def file_should_not_exist(file)
    expect(File.exist?(file)).to be(false), 'File #{file} should not exist'
  end

  def identical_files?(first, second)
    file_should_exist(first)
    file_should_exist(second)
    expect(open(second, 'r').read).to eq(open(first, 'r').read)
  end

  def rails_path(file)
    SitemapGenerator.app.root + file
  end

  def copy_sitemap_file_to_rails_app(extension)
    FileUtils.cp(File.join(SitemapGenerator.root, "spec/files/sitemap.#{extension}.rb"), rails_path('config/sitemap.rb'))
  end

  def delete_sitemap_file_from_rails_app
    FileUtils.remove(rails_path('config/sitemap.rb'))
  rescue
    nil
  end

  def clean_sitemap_files_from_rails_app
    FileUtils.rm_rf(rails_path('public/'))
    FileUtils.mkdir_p(rails_path('public/'))
  end

  def execute_sitemap_config(opts={})
   SitemapGenerator::Interpreter.run(opts)
  end
end
