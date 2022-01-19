### 6.2.1

* Bugfix: Improve handling of deprecated options in `AwsSdkAdapter`.  Fixes bug where `:region` was being set to `nil`. [#390](https://github.com/kjvarga/sitemap_generator/pull/390).

### 6.2.0

* Raise `LoadError` when an adapter's dependency is missing to better support Sorbet [#387](https://github.com/kjvarga/sitemap_generator/pull/387).
* Update the Bing notification URL [#386](https://github.com/kjvarga/sitemap_generator/pull/386).
* Setup integration testing against a matrix of Ruby and Rails versions; test against Ruby 3.1 and Rails 7.
* Change default `changefreq` of the root URL from `always` to `weekly` [#376](https://github.com/kjvarga/sitemap_generator/pull/376).
* `SitemapGenerator::GoogleStorageAdapter`: Support ruby 3 kwarg changes [#375](https://github.com/kjvarga/sitemap_generator/pull/375).
* `SitemapGenerator::S3Adapter`: Allow Fog `public` option to be Configurable [#359](https://github.com/kjvarga/sitemap_generator/pull/359).

### 6.1.2

* Resolve NoMethodError using URI#open for Ruby less than 2.5.0 [#353](https://github.com/kjvarga/sitemap_generator/pull/353)

### 6.1.1

* Resolve deprecation warning on using Kernel#open in Ruby 2.7 (use URI.open instead) [#342](https://github.com/kjvarga/sitemap_generator/pull/342)
* Support S3 Endpoints for S3 Compliant Providers like DigitalOcean Spaces [#325](https://github.com/kjvarga/sitemap_generator/pull/325)

### 6.1.0

* Support uploading files to Google Cloud Storage [#326](https://github.com/kjvarga/sitemap_generator/pull/326) and [#340](https://github.com/kjvarga/sitemap_generator/pull/340)

### 6.0.2

* Resolve `BigDecimal.new is deprecated` warnings in Ruby 2.5 [#305](https://github.com/kjvarga/sitemap_generator/pull/305).
* Resolve `instance variable not initialized`, `File.exists? is deprecated` and `'*' interpreted as argument prefix` warnings [#304](https://github.com/kjvarga/sitemap_generator/pull/304).

### 6.0.1

* Use `yaml_tag` instead of `yaml_as`, which was deprecated in Ruby 2.4, and removed in 2.5 [#298](https://github.com/kjvarga/sitemap_generator/pull/298).

### 6.0.0

*Backwards incompatible changes*

* Adapters (AWS SDK, S3, Fog & Wave) no longer load their dependencies.  It is up to the user
  to `require` the appropriate libraries for the adapter to work.
* AwsSdkAdapter: Fixed [#279](https://github.com/kjvarga/sitemap_generator/issues/279) where sitemaps were incorrectly nested under a `sitemaps/` directory in S3
* Stop supporting Ruby < 2.0, test with Ruby 2.4.

*Other changes*

* If Rails is defined but the application is not loaded, don't include the URL helpers.

### 5.3.1

* Ensure files have 644 permissions when building to try to address issue [#264](https://github.com/kjvarga/sitemap_generator/issues/264)
* Use HTTPS in the Gemfile (PR #[#263](https://github.com/kjvarga/sitemap_generator/pull/263))

### 5.3.0

* Add `max_sitemap_links` option support for limiting how many links each sitemap can hold.  Issue [#188](https://github.com/kjvarga/sitemap_generator/issues/188) PR [#262](https://github.com/kjvarga/sitemap_generator/pull/262)
* Upgrade development dependencies
* Modernize Gemfile & gemspec
* Bring specs up to RSpec 3.5
* Remove Geo sitemap support.  Google no longer supports them. Issue [#246](https://github.com/kjvarga/sitemap_generator/issues/246)
* Use `sitemap` namespace for Capistrano tasks (rather than `deploy`). PR [#241](https://github.com/kjvarga/sitemap_generator/pull/241)
* Use presence of `Rails::VERSION` to detect when running under Rails, rather than just `Rails` constant.  PR [#221](https://github.com/kjvarga/sitemap_generator/pull/221)
* Remove gem post-install message warning about incompatible changes in version 4

### 5.2.0

* New `SitemapGenerator::AwsSdkAdapter` adapter using the bare aws-sdk gem.
* Fix Bing ping url.
* Support string option keys passed to `add`.
* In Railtie, Load the rake task instead of requiring them.

### 5.1.0

* Require only `fog-aws` instead of `fog` for the `S3Adapter` and support using IAM profile instead of setting access key & secret directly.
* Implement `respond_to?` on the `SitemapGenerator::Sitemap` pseudo class.
* Make `:lang` optional on alternate links so they can be used for [AppIndexing](https://developers.google.com/app-indexing/reference/deeplinks).
* Documented Mobile Sitemaps `:mobile` option.

### 5.0.5

* Use MIT licence.
* Fix deploys with Capistrano 3 ([#163](https://github.com/kjvarga/sitemap_generator/issues/163)).
* Allow any Fog storage options for S3 adapter ([#167](https://github.com/kjvarga/sitemap_generator/pull/167)).

### 5.0.4

* Don't include the `media` attribute on alternate links unless it's given

### 5.0.3

* Add support for Video sitemaps options `:live` and ':requires_subscription'

### 5.0.2

* Set maximum filesize to 10,000,000 bytes rather than 10,485,760 bytes.

### 5.0.1

* Include new `SitemapGenerator::FogAdapter` ([#138](https://github.com/kjvarga/sitemap_generator/pull/138)).
* Fix usage of attr_* methods in `LinkSet`
* Don't override custom getters/setters ([#144](https://github.com/kjvarga/sitemap_generator/pull/144)).
* Fix breaking spec in Ruby 2 ([#142](https://github.com/kjvarga/sitemap_generator/pull/142)).
* Include Capistrano 3.x tasks ([#141](https://github.com/kjvarga/sitemap_generator/pull/141)).

### 5.0.0

* Support new `:compress` option for customizing which files get compressed.
* Remove old deprecated methods:
    * Removed options to `LinkSet::add()`: `:sitemaps_namer` and `:sitemap_index_namer` (use `:namer` option)
    * Removed `LinkSet::sitemaps_namer=`, `LinkSet::sitemaps_namer` (use `LinkSet::namer=` and `LinkSet::namer`)
    * Removed `LinkSet::sitemaps_index_namer=`, `LinkSet::sitemaps_index_namer` (use `LinkSet::namer=` and `LinkSet::namer`)
    * Removed the `SitemapGenerator::SitemapNamer` class (use `SitemapGenerator::SimpleNamer`)
    * Removed `LinkSet::add_links()` (use `LinkSet::create()`)
* Support `fog_path_style` option in the `SitemapGenerator::S3Adapter` so buckets with dots in the name work over HTTPS without SSL certificate problems.

### 4.3.1

* Support integer timestamps.
* Update README for new features added in last release.

### 4.3.0

* Support `media` attibute on alternate links ([#125](https://github.com/kjvarga/sitemap_generator/issues/125)).
* Changed `SitemapGenerator::S3Adapter` to write files in a single operation, avoiding potential permissions errors when listing a directory prior to writing ([#130](https://github.com/kjvarga/sitemap_generator/issues/130)).
* Remove Sitemap Writer from ping task ([#129](https://github.com/kjvarga/sitemap_generator/issues/129)).
* Support `url:expires` element ([#126](https://github.com/kjvarga/sitemap_generator/issues/126)).

### 4.2.0

* Update Google ping URL.
* Quote the ping URL in the output.
* Support Video `video:price` element ([#117](https://github.com/kjvarga/sitemap_generator/issues/117)).
* Support symbols as well as strings for most arguments to `add()` ([#113](https://github.com/kjvarga/sitemap_generator/issues/113)).
* Ensure that `public_path` and `sitemaps_path` end with a slash (`/`) ([#113](https://github.com/kjvarga/sitemap_generator/issues/118)).

### 4.1.1

* Support setting the S3 region.
* Fixed bug where incorrect URL was being used in the ping to search engines - only affected sites with a single sitemap file and no index file.
* Output the URL being pinged in the verbose output.
* Test in Rails 4.

### 4.1.0

* [PageMap sitemap][using_pagemaps] support.
* Tested with Rails 4 pre-release.

### 4.0.1

* Add a post install message regarding the naming convention change.

### 4.0

* **NEW, NON-BACKWARDS COMPATIBLE CHANGES.**
* `create_index` defaults to `:auto`.
* Define `SitemapGenerator::SimpleNamer` class for simpler custom namers compatible with the new naming conventions.
* Deprecate `sitemaps_namer`, `sitemap_index_namer` and their respective namer classes.
* Support `nofollow` option on alternate links.
* Fix formatting of `publication_date` in News sitemaps.

### 3.4

* Support [alternate links][alternate_links] for urls
* Support configurable options in the `SitemapGenerator::S3Adapter`

### 3.3

* Support creating sitemaps with no index file

### 3.2.1

* Fix syntax error in `SitemapGenerator::S3Adapter`

### 3.2

* Support mobile tags
* Add `SitemapGenerator::S3Adapter`, a simple S3 adapter which uses Fog and doesn't require CarrierWave
* Remove Ask from the sitemap ping because the service has been shutdown
* [Turn off `include_index`][include_index_change] by default
* Fix the news XML namespace
* Only include `autoplay` attribute if present

### 3.1.1

* Bugfix
* Groups inherit current adapter

### 3.1.0

* Add `add_to_index` method to add links to the sitemap index.
* Add `sitemap` method for accessing the `LinkSet instance from within `create()`.
* Don't modify options hashes passed to methods.  Fix and improve `yield_sitemap` option handling.

### 3.0.0

* **Framework agnostic!**
* Fix alignment in output
* Show directory sitemaps are being generated into
* Only show sitemap compressed file size
* Toggle output using VERBOSE environment variable
* Remove tasks/ directory because it's deprecated in Rails 2
* Simplify dependencies.

### 2.2.1

* Support adding new search engines to ping and modifying the default search engines.
* Allow the URL of the sitemap index to be passed as an argument to `ping_search_engines`. See Pinging Search Engines in README.

### 2.1.8

* Extend and improve Video Sitemap support.
* Include sitemap docs in the README, support all element attributes, properly format values.

### 2.1.7

* Improve format of float priorities
* Remove Yahoo from ping - the Yahoo service has been shut down.

### 2.1.6

* Fix the `lastmod` value on sitemap file links

### 2.1.5

* Fix verbose setting in the rake task, it should default to true

### 2.1.4

* Allow special characters in URLs (don't use `URI.join` to construct URLs)

### 2.1.3

* Fix calling `create` with both `filename` and `sitemaps_namer` options

### 2.1.2

* Support multiple videos per url using the new `videos` option to `add()`.

### 2.1.1

* Support calling `create()` multiple times in a sitemap config
* Support host names with path segments so you can use a `default_host` like `'http://mysite.com/subdirectory/'`
* Turn off `include_index` when the `sitemaps_host` differs from `default_host`
* Add docs about how to upload to remote hosts.

### 2.1.0

* [News sitemap][sitemap_news] support

### 2.0.1.pre2

* Fix uploading to the (bucket) root on a remote server

### 2.0.1.pre1

* Support read-only filesystems like Heroku by supporting uploading to remote host

### 2.0.1

* Minor improvements to verbose handlig
* Prevent missing `Timeout` issue

### v2.0.0

* Introducing a new simpler API, Sitemap Groups, Sitemap Namers and more!

### 1.5.0

* New options `include_root`, `include_index`
* Major testing & refactoring

### 1.4.0

* [Geo sitemap][geo_tags] support
* Multiple sitemap support via CONFIG_FILE rake option

### 1.3.0

* Support setting the sitemaps path

### 1.2.0

* Verified working with Rails 3 stable release

### 1.1.0

* [Video sitemap][sitemap_video] support

### 0.2.6

* [Image Sitemap][sitemap_images] support

### 0.2.5

* Rails 3 prerelease support (beta)

[geo_tags]:http://www.google.com/support/webmasters/bin/answer.py?hl=en&answer=94555
[sitemap_images]:http://www.google.com/support/webmasters/bin/answer.py?answer=178636
[sitemap_video]:https://support.google.com/webmasters/answer/80471?hl=en&ref_topic=4581190
[sitemap_news]:https://support.google.com/news/publisher/topic/2527688?hl=en&ref_topic=4359874
[include_index_change]:https://github.com/kjvarga/sitemap_generator/issues/70
[alternate_links]:http://support.google.com/webmasters/bin/answer.py?hl=en&answer=2620865
[using_pagemaps]:https://developers.google.com/custom-search/docs/structured_data#pagemaps
