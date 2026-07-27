# frozen_string_literal: true

module FileMacros
  def expect_files_to_be_identical(first, second)
    expect(identical_files?(first, second)).to be(true)
  end

  def expect_files_not_to_be_identical(first, second)
    expect(identical_files?(first, second)).to be(false)
  end

  def expect_file_to_exist(file)
    expect(File.exist?(file)).to be(true), "File #{file} should exist"
  end

  def expect_directory_to_exist(dir)
    expect(File.exist?(dir)).to be(true), "Directory #{dir} should exist"
    expect(File.directory?(dir)).to be(true), "#{dir} should be a directory"
  end

  def expect_directory_not_to_exist(dir)
    expect(File.exist?(dir)).to be(false), "Directory #{dir} should not exist"
  end

  def expect_file_not_to_exist(file)
    expect(File.exist?(file)).to be(false), "File #{file} should not exist"
  end

  def identical_files?(first, second)
    expect_file_to_exist(first)
    expect_file_to_exist(second)
    expect(File.read(second)).to eq(File.read(first))
  end

  def rails_path(file)
    SitemapGenerator.app.root + file
  end

  def copy_sitemap_file_to_rails_app(extension)
    FileUtils.cp(File.join(SitemapGenerator.root, "spec/files/sitemap.#{extension}.rb"),
                 rails_path('config/sitemap.rb'))
  end

  def delete_sitemap_file_from_rails_app
    FileUtils.remove(rails_path('config/sitemap.rb'))
  rescue StandardError
    nil
  end

  def clean_sitemap_files_from_rails_app
    FileUtils.rm_rf(rails_path('public/'))
    FileUtils.mkdir_p(rails_path('public/'))
  end

  def execute_sitemap_config(opts = {})
    SitemapGenerator::Interpreter.run(opts)
  end
end
