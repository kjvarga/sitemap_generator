# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sitemap Groups' do # rubocop:disable RSpec/DescribeClass -- feature-level spec, not scoped to one class
  let(:linkset) { SitemapGenerator::LinkSet.new(default_host: 'http://test.com') }

  before do
    FileUtils.rm_rf(SitemapGenerator.app.root.join('public/'))
  end

  def public_file(path)
    SitemapGenerator.app.root.join("public/#{path}")
  end

  def expect_public_files(exist: [], not_exist: [])
    exist.each { |path| expect_file_to_exist(public_file(path)) }
    not_exist.each { |path| expect_file_not_to_exist(public_file(path)) }
  end

  it 'does not finalize the default sitemap if using groups' do
    linkset.create { group(filename: :sitemap_en) { add '/en' } }
    expect_public_files(exist: %w[sitemap.xml.gz sitemap_en.xml.gz], not_exist: %w[sitemap1.xml.gz])
  end

  it 'does not write out empty groups' do
    linkset.create { group(filename: :sitemap_en) { nil } }
    expect_public_files(not_exist: %w[sitemap_en.xml.gz])
  end

  it 'adds default links if no groups are created' do
    linkset.create { nil }
    expect(linkset.link_count).to eq(1)
    expect_public_files(exist: %w[sitemap.xml.gz], not_exist: %w[sitemap1.xml.gz])
  end

  # rubocop:disable RSpec/ExampleLength -- distinct add-before/group/add-after steps are the scenario under test
  it 'adds links to the default sitemap' do
    linkset.create do
      add '/before'
      group(filename: :sitemap_en) { add '/link' }
      add '/after'
    end
    expect(linkset.link_count).to eq(4)
    expect_public_files(exist: %w[sitemap.xml.gz sitemap1.xml.gz sitemap_en.xml.gz])
  end
  # rubocop:enable RSpec/ExampleLength

  # rubocop:disable RSpec/ExampleLength -- exercises a full max_sitemap_links rollover scenario across 2 groups
  it 'rolls over when sitemaps are full' do
    linkset.max_sitemap_links = 1
    linkset.include_index = false
    linkset.include_root = false
    linkset.create do
      add '/before'
      group(filename: :sitemap_en, sitemaps_path: 'en/') do
        add '/one'
        add '/two'
      end
      add '/after'
    end
    expect(linkset.link_count).to eq(4)
    expect_public_files(
      exist: %w[sitemap.xml.gz sitemap1.xml.gz sitemap2.xml.gz en/sitemap_en.xml.gz en/sitemap_en1.xml.gz],
      not_exist: %w[sitemap3.xml.gz en/sitemap_en2.xml.gz]
    )
  end
  # rubocop:enable RSpec/ExampleLength

  # rubocop:disable RSpec/ExampleLength -- exercises 2 independent groups plus the resulting file layout
  it 'supports multiple groups' do
    linkset.create do
      group(filename: :sitemap_en, sitemaps_path: 'en/') { add '/one' }
      group(filename: :sitemap_fr, sitemaps_path: 'fr/') { add '/one' }
    end
    expect(linkset.link_count).to eq(2)
    expect_public_files(exist: %w[sitemap.xml.gz en/sitemap_en.xml.gz fr/sitemap_fr.xml.gz])
  end
  # rubocop:enable RSpec/ExampleLength

  # rubocop:disable RSpec/ExampleLength -- exercises 2 non-conflicting groups interleaved with top-level adds
  it 'the sitemap shouldn\'t be finalized until the end if the groups don\'t conflict' do
    linkset.create do
      add 'one'
      group(filename: :first) { add '/two' }
      add 'three'
      group(filename: :second) { add '/four' }
      add 'five'
    end
    expect(linkset.link_count).to eq(6)
    expect_public_files(exist: %w[sitemap.xml.gz sitemap1.xml.gz first.xml.gz second.xml.gz])
    expect_valid_sitemap_index_and_page(public_file('sitemap.xml.gz'), public_file('sitemap1.xml.gz'))
  end
  # rubocop:enable RSpec/ExampleLength

  # rubocop:disable RSpec/ExampleLength -- exercises 2 groups with differing hosts interleaved with top-level adds
  it 'groups should share the sitemap if the sitemap location is unchanged' do
    linkset.create do
      add 'one'
      group(default_host: 'http://newhost.com') { add '/two' }
      add 'three'
      group(default_host: 'http://betterhost.com') { add '/four' }
      add 'five'
    end
    expect(linkset.link_count).to eq(6)
    expect_public_files(exist: %w[sitemap.xml.gz sitemap1.xml.gz sitemap2.xml.gz sitemap3.xml.gz],
                        not_exist: %w[sitemap4.xml.gz])
    expect_valid_sitemap_index_and_pages('sitemap1.xml.gz', 'sitemap2.xml.gz', 'sitemap3.xml.gz')
  end
  # rubocop:enable RSpec/ExampleLength

  # rubocop:disable RSpec/ExampleLength -- exercises 2 groups with differing virtual locations interleaved with adds
  it 'sitemaps should be finalized if virtual location settings are changed' do
    linkset.create do
      add 'one'
      group(sitemaps_path: :en) { add '/two' }
      add 'three'
      group(sitemaps_host: 'http://newhost.com') { add '/four' }
      add 'five'
    end
    expect(linkset.link_count).to eq(6)
    expect_public_files(exist: %w[sitemap.xml.gz sitemap1.xml.gz sitemap2.xml.gz sitemap3.xml.gz en/sitemap.xml.gz],
                        not_exist: %w[sitemap4.xml.gz])
  end
  # rubocop:enable RSpec/ExampleLength

  def expect_valid_sitemap_index_and_page(index_file, sitemap_file)
    expect_gzipped_xml_file_to_validate_against_schema(index_file, 'siteindex')
    expect_gzipped_xml_file_to_validate_against_schema(sitemap_file, 'sitemap')
  end

  def expect_valid_sitemap_index_and_pages(*sitemap_paths)
    expect_gzipped_xml_file_to_validate_against_schema(public_file('sitemap.xml.gz'), 'siteindex')
    sitemap_paths.each do |path|
      expect_gzipped_xml_file_to_validate_against_schema(public_file(path), 'sitemap')
    end
  end
end
