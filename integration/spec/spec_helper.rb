# Load combustion gem
require 'combustion'

# Setting load_schema: false results in "uninitialized constant ActiveRecord::MigrationContext" error
Combustion.initialize! :active_record, :action_view, database_reset: false
Combustion::Application.load_tasks

# Load rspec gem
require 'rspec/rails'

# Load support files
require_relative 'support/sitemap_macros'
require_relative '../../spec/support/file_macros'
require_relative '../../spec/support/xml_macros'

# Configure rspec
RSpec.configure do |config|
  config.include(FileMacros)
  config.include(XmlMacros)
  config.include(SitemapMacros)

  config.after(:all) do
    clean_sitemap_files_from_rails_app
    copy_sitemap_file_to_rails_app(:create)
  end
end

module Helpers
  extend self

  # Invoke and then re-enable the task so it can be called multiple times.
  # KJV: Tasks are only being run once despite being re-enabled.
  #
  # <tt>task</tt> task symbol/string
  def invoke_task(task)
    Rake.send(:verbose, false)
    Rake::Task[task.to_s].invoke
    Rake::Task[task.to_s].reenable
  end
end

# Load our own gem
require 'sitemap_generator/tasks' # Combusition fails to load these tasks
SitemapGenerator.verbose = false
