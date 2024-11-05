# frozen_string_literal: true

module SitemapGenerator
  # Provide convenient access to template files.  E.g.
  #
  #   SitemapGenerator.templates.sitemap_index
  #
  # Lazy-load and cache for efficient access.
  # Define an accessor method for each template file.
  class Templates
    FILES = {
      :sitemap_sample => 'sitemap.rb',
    }

    # Dynamically define accessors for each key defined in <tt>FILES</tt>
    attr_writer(*FILES.keys)

    FILES.each_key do |name|
      eval(<<-ACCESSOR, binding, __FILE__ , __LINE__ + 1)
        define_method(:#{name}) do
          @#{name} ||= read_template(:#{name})
        end
      ACCESSOR
    end

    def initialize(root = SitemapGenerator.root)
      @root = root
    end

    # Return the full path to a template.
    #
    # <tt>file</tt> template symbol e.g. <tt>:sitemap_sample</tt>
    def template_path(template)
      File.join(@root, 'templates', self.class::FILES[template])
    end

    protected

    # Read the template file and return its contents.
    def read_template(template)
      File.read(template_path(template))
    end
  end
end
