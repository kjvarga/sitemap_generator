require "spec_helper"

def with_max_links(num)
  original = SitemapGenerator::Sitemap.max_sitemap_links
  SitemapGenerator::Sitemap.max_sitemap_links = num

  begin
    yield
  ensure
    SitemapGenerator::Sitemap.max_sitemap_links = original
  end
end

describe "Sitemap Groups" do
  let(:linkset) { ::SitemapGenerator::LinkSet.new(:default_host => 'http://test.com') }

  before :each do
    FileUtils.rm_rf(SitemapGenerator.app.root + 'public/')
  end

  it "should not finalize the default sitemap if using groups" do
    linkset.create do
      group(:filename => :sitemap_en) do
        add '/en'
      end
    end
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap_en.xml.gz')
    file_should_not_exist(SitemapGenerator.app.root + 'public/sitemap1.xml.gz')
  end

  it "should not write out empty groups" do
    linkset.create do
      group(:filename => :sitemap_en) { }
    end
    file_should_not_exist(SitemapGenerator.app.root + 'public/sitemap_en.xml.gz')
  end

  it "should add default links if no groups are created" do
    linkset.create do
    end
    linkset.link_count.should == 1
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap.xml.gz')
    file_should_not_exist(SitemapGenerator.app.root + 'public/sitemap1.xml.gz')
  end

  it "should add links to the default sitemap" do
    linkset.create do
      add '/before'
      group(:filename => :sitemap_en) do
        add '/link'
      end
      add '/after'
    end
    linkset.link_count.should == 4
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap1.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap_en.xml.gz')
  end

  it "should rollover when sitemaps are full" do
    with_max_links(1) {
      linkset.include_index = false
      linkset.include_root = false
      linkset.create do
        add '/before'
        group(:filename => :sitemap_en, :sitemaps_path => 'en/') do
          add '/one'
          add '/two'
        end
        add '/after'
      end
    }
    linkset.link_count.should == 4
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap1.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap2.xml.gz')
    file_should_not_exist(SitemapGenerator.app.root + 'public/sitemap3.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/en/sitemap_en.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/en/sitemap_en1.xml.gz')
    file_should_not_exist(SitemapGenerator.app.root + 'public/en/sitemap_en2.xml.gz')
  end

  it "should support multiple groups" do
    linkset.create do
      group(:filename => :sitemap_en, :sitemaps_path => 'en/') do
        add '/one'
      end
      group(:filename => :sitemap_fr, :sitemaps_path => 'fr/') do
        add '/one'
      end
    end
    linkset.link_count.should == 2
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/en/sitemap_en.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/fr/sitemap_fr.xml.gz')
  end

  it "the sitemap shouldn't be finalized until the end if the groups don't conflict" do
    linkset.create do
      add 'one'
      group(:filename => :first) { add '/two' }
      add 'three'
      group(:filename => :second) { add '/four' }
      add 'five'
    end
    linkset.link_count.should == 6
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap1.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/first.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/second.xml.gz')
    gzipped_xml_file_should_validate_against_schema(SitemapGenerator.app.root + 'public/sitemap.xml.gz', 'siteindex')
    gzipped_xml_file_should_validate_against_schema(SitemapGenerator.app.root + 'public/sitemap1.xml.gz', 'sitemap')
  end

  it "groups should share the sitemap if the sitemap location is unchanged" do
    linkset.create do
      add 'one'
      group(:default_host => 'http://newhost.com') { add '/two' }
      add 'three'
      group(:default_host => 'http://betterhost.com') { add '/four' }
      add 'five'
    end
    linkset.link_count.should == 6
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap.xml.gz')
    file_should_not_exist(SitemapGenerator.app.root + 'public/sitemap1.xml.gz')
    gzipped_xml_file_should_validate_against_schema(SitemapGenerator.app.root + 'public/sitemap.xml.gz', 'sitemap')
  end

  it "sitemaps should be finalized if virtual location settings are changed" do
    linkset.create do
      add 'one'
      group(:sitemaps_path => :en) { add '/two' }
      add 'three'
      group(:sitemaps_host => 'http://newhost.com') { add '/four' }
      add 'five'
    end
    linkset.link_count.should == 6
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap1.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap2.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/sitemap3.xml.gz')
    file_should_not_exist(SitemapGenerator.app.root + 'public/sitemap4.xml.gz')
    file_should_exist(SitemapGenerator.app.root + 'public/en/sitemap.xml.gz')
  end
end
