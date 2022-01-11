SitemapGenerator::Sitemap.default_host = "http://www.example.com"

SitemapGenerator::Sitemap.create(
    :include_root => true, :include_index => true,
    :filename => :new_sitemaps, :sitemaps_path => 'fr/') do

  add('/one', :priority => 0.7, :changefreq => 'daily')

  # Test a new location and filename and sitemaps host
  group(:sitemaps_path => 'en/', :filename => :xxx,
      :sitemaps_host => "http://newhost.com") do

    add '/two'
    add '/three'
  end

  # Test a simple namer.
  group(:namer => SitemapGenerator::SimpleNamer.new(:abc, :start => 4, :zero => 3)) do
    add '/four'
    add '/five'
    add '/six'
  end

  # Test a simple namer
  group(:namer => SitemapGenerator::SimpleNamer.new(:def)) do
    add '/four'
    add '/five'
    add '/six'
  end

  add '/seven'

  # This should be in a file of its own.
  # Not technically valid to have a link with a different host, but people like
  # to do strange things sometimes.
  group(:sitemaps_host => "http://exceptional.com") do
    add '/eight'
    add '/nine'
  end

  add '/ten'

  # Not technically valid to have a link with a different host, but people like
  # to do strange things sometimes
  add "/merchant_path", :host => "https://www.merchanthost.com"
end
