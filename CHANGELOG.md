# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [7.1.1] - 2026-07-27

### Fixed

- `clean_files` (used by `rake sitemap:clean`) now respects the configured `sitemaps_path`/`public_path` and also removes uncompressed `.xml` sitemaps, instead of only deleting hardcoded `public/sitemap*.xml.gz` files. [#474](https://github.com/kjvarga/sitemap_generator/issues/474) [#502](https://github.com/kjvarga/sitemap_generator/pull/502)
- `SitemapGenerator::Interpreter` now respects `ActionController::Base.default_url_options`, so Rails URL helpers honor globally configured defaults (e.g. `:protocol`, `:port`) instead of ignoring them. [#355](https://github.com/kjvarga/sitemap_generator/issues/355) [#507](https://github.com/kjvarga/sitemap_generator/pull/507)
- Non-ASCII characters in URL paths are now percent-encoded in the `<loc>` element, so generated sitemaps conform to the sitemap protocol. [#346](https://github.com/kjvarga/sitemap_generator/issues/346) [#506](https://github.com/kjvarga/sitemap_generator/pull/506)
- Relative alternate hreflang hrefs (starting with `/`) are now expanded to absolute URLs using the configured host, producing valid sitemap XML instead of broken relative links. [#343](https://github.com/kjvarga/sitemap_generator/issues/343) [#504](https://github.com/kjvarga/sitemap_generator/pull/504)
- `SitemapGenerator.verbose = false` is now respected by `rake sitemap:refresh` and other rake tasks, silencing output as configured. [#332](https://github.com/kjvarga/sitemap_generator/issues/332) [#503](https://github.com/kjvarga/sitemap_generator/pull/503)
- Sitemap file `lastmod` is now captured at write time rather than read back via `File.mtime`, fixing incorrect timestamps and improving compatibility with time-freezing test helpers. [#427](https://github.com/kjvarga/sitemap_generator/issues/427) [#508](https://github.com/kjvarga/sitemap_generator/pull/508)
- URL `lastmod` now defaults to `Time.zone.now` under Rails (falling back to `Time.now` otherwise), so the configured Rails timezone and time-freezing helpers like `travel_to` are respected instead of always using system local time. [#422](https://github.com/kjvarga/sitemap_generator/issues/422) [#427](https://github.com/kjvarga/sitemap_generator/issues/427) [#505](https://github.com/kjvarga/sitemap_generator/pull/505)

## [7.1.0] - 2026-07-03

### Changed

- **BREAKING**: `SitemapGenerator::FileAdapter#gzip` is now private. It was always an implementation detail; external callers should not need to invoke it directly. [#492](https://github.com/kjvarga/sitemap_generator/pull/492)

### Removed

- **BREAKING**: `SitemapGenerator::FileAdapter#plain` has been removed. It was an internal helper inlined into `#write` to fix a file descriptor leak; any code calling it directly should call `#write` instead. [#492](https://github.com/kjvarga/sitemap_generator/pull/492)

### Fixed

- `AwsSdkAdapter` and `S3Adapter` now derive the `Content-Type` header from the file extension (`.xml` → `application/xml`, `.xml.gz` → `application/x-gzip`) via the new `SitemapLocation#content_type` helper, rather than always sending `application/x-gzip`. [#329](https://github.com/kjvarga/sitemap_generator/issues/329) [#338](https://github.com/kjvarga/sitemap_generator/issues/338) [#495](https://github.com/kjvarga/sitemap_generator/pull/495)

## [7.0.3] - 2026-07-02

### Fixed

- Revert railtie enhancements (#478) that were unintentionally included in 7.0.2. Those changes introduced an `ArgumentError: Missing host to link to!` during `assets:precompile` and other Rails boot contexts where no host is configured (reported in [#488](https://github.com/kjvarga/sitemap_generator/issues/488)). The railtie is restored to its 7.0.1 behaviour: it loads rake tasks only. The enhancements will return in a future release with proper documentation and test coverage. [#489](https://github.com/kjvarga/sitemap_generator/pull/489)
- Restore sitemap generation on Ruby 2.x when `--enable=frozen-string-literal` is set globally. Ruby 2.6/2.7 freezes interpolated heredocs under that flag, causing `gsub!` to raise `FrozenError`. [#486](https://github.com/kjvarga/sitemap_generator/pull/486)

## [7.0.2] - 2026-06-29

### Changed

- Reduce string copies and improve compatibility with `frozen_string_literal`. [#456](https://github.com/kjvarga/sitemap_generator/pull/456)

## [7.0.1] - 2026-04-28

### Added

- Support AWS temporary credentials (`aws_session_token` / `AWS_SESSION_TOKEN`) for S3 uploads in AWS Lambda. [#415](https://github.com/kjvarga/sitemap_generator/pull/415)
- Add support for Rails 8.0. [#441](https://github.com/kjvarga/sitemap_generator/pull/441)
- Add support for Ruby 3.4. [#451](https://github.com/kjvarga/sitemap_generator/pull/451)
- Add support for Rails 8.1. [#461](https://github.com/kjvarga/sitemap_generator/pull/461)
- Add support for Ruby 4.0. [#466](https://github.com/kjvarga/sitemap_generator/pull/466)
- Add ActiveStorage adapter (`ActiveStorage::Blob`). [#467](https://github.com/kjvarga/sitemap_generator/pull/467)

### Changed

- **BREAKING**: Default search engines list is empty. `rake sitemap:refresh` and `ping_search_engines` perform no HTTP pings unless you configure engine URLs on `search_engines` or pass them into `ping_search_engines` (Google's ping endpoint is deprecated upstream). [#444](https://github.com/kjvarga/sitemap_generator/pull/444)
- **BREAKING**: `LinkSet#create` runs `finalize!` only when a block is given. Calling `create` without a block requires `finalize!` when you are done adding links (supported workflow for programmatic builds). [#463](https://github.com/kjvarga/sitemap_generator/pull/463)
- Add `frozen_string_literal: true` magic comments. [#430](https://github.com/kjvarga/sitemap_generator/pull/430)
- Replace CGI-based escaping with `URI.encode_www_form_component` for ping URLs; remove reliance on `cgi` (Ruby 4 compatibility). [#465](https://github.com/kjvarga/sitemap_generator/pull/465)

### Removed

- **BREAKING**: Drop support for Ruby 2.5 and Rails 5.2. [#438](https://github.com/kjvarga/sitemap_generator/pull/438)

### Fixed

- Fix uninitialized constant `ActiveSupport::LoggerThreadSafeLevel::Logger`. [#449](https://github.com/kjvarga/sitemap_generator/pull/449)

## [6.3.0] - 2022-08-09

### Added

- `SitemapGenerator::AwsSdkAdapter`: Support configuring ACL and caching on the uploaded files. [#409](https://github.com/kjvarga/sitemap_generator/pull/409)
- `SitemapGenerator::GoogleStorageAdapter`: Support configuring ACL on the uploaded files. [#410](https://github.com/kjvarga/sitemap_generator/pull/410)

### Removed

- Remove Bing's deprecated sitemap submission. [#400](https://github.com/kjvarga/sitemap_generator/pull/400)

## [6.2.1] - 2022-01-19

### Fixed

- Improve handling of deprecated options in `AwsSdkAdapter`. Fixes bug where `:region` was being set to `nil`. [#390](https://github.com/kjvarga/sitemap_generator/pull/390)

## [6.2.0] - 2022-01-17

### Added

- Raise `LoadError` when an adapter's dependency is missing to better support Sorbet. [#387](https://github.com/kjvarga/sitemap_generator/pull/387)
- `SitemapGenerator::S3Adapter`: Allow Fog `public` option to be configurable. [#359](https://github.com/kjvarga/sitemap_generator/pull/359)

### Changed

- Change default `changefreq` of the root URL from `always` to `weekly`. [#376](https://github.com/kjvarga/sitemap_generator/pull/376)

### Fixed

- Update the Bing notification URL. [#386](https://github.com/kjvarga/sitemap_generator/pull/386)
- `SitemapGenerator::GoogleStorageAdapter`: Support Ruby 3 kwarg changes. [#375](https://github.com/kjvarga/sitemap_generator/pull/375)

## [6.1.2] - 2020-06-03

### Fixed

- Resolve `NoMethodError` using `URI#open` for Ruby less than 2.5.0. [#353](https://github.com/kjvarga/sitemap_generator/pull/353)

## [6.1.1] - 2020-05-26

### Added

- Support S3 Endpoints for S3-compliant providers like DigitalOcean Spaces. [#325](https://github.com/kjvarga/sitemap_generator/pull/325)

### Fixed

- Resolve deprecation warning on using `Kernel#open` in Ruby 2.7 (use `URI.open` instead). [#342](https://github.com/kjvarga/sitemap_generator/pull/342)

## [6.1.0] - 2019-12-26

### Added

- Support uploading files to Google Cloud Storage. [#326](https://github.com/kjvarga/sitemap_generator/pull/326) [#340](https://github.com/kjvarga/sitemap_generator/pull/340)

## [6.0.2] - 2019-01-10

### Fixed

- Resolve `BigDecimal.new is deprecated` warnings in Ruby 2.5. [#305](https://github.com/kjvarga/sitemap_generator/pull/305)
- Resolve `instance variable not initialized`, `File.exists? is deprecated`, and `'*' interpreted as argument prefix` warnings. [#304](https://github.com/kjvarga/sitemap_generator/pull/304)

## [6.0.1] - 2018-01-13

### Fixed

- Use `yaml_tag` instead of `yaml_as`, which was deprecated in Ruby 2.4 and removed in 2.5. [#298](https://github.com/kjvarga/sitemap_generator/pull/298)

## [6.0.0] - 2017-10-11

### Changed

- **BREAKING**: Adapters (AWS SDK, S3, Fog & Wave) no longer load their dependencies. It is up to the user to `require` the appropriate libraries for the adapter to work.
- If Rails is defined but the application is not loaded, don't include the URL helpers.

### Removed

- **BREAKING**: Stop supporting Ruby < 2.0; test with Ruby 2.4.

### Fixed

- **BREAKING**: `AwsSdkAdapter`: Fixed [#279](https://github.com/kjvarga/sitemap_generator/issues/279) where sitemaps were incorrectly nested under a `sitemaps/` directory in S3.

## [5.3.1] - 2017-02-27

### Fixed

- Ensure files have 644 permissions when building, to try to address issue [#264](https://github.com/kjvarga/sitemap_generator/issues/264).

## [5.3.0] - 2017-02-21

### Added

- Add `max_sitemap_links` option support for limiting how many links each sitemap can hold. [#188](https://github.com/kjvarga/sitemap_generator/issues/188) [#262](https://github.com/kjvarga/sitemap_generator/pull/262)

### Changed

- Use `sitemap` namespace for Capistrano tasks (rather than `deploy`). [#241](https://github.com/kjvarga/sitemap_generator/pull/241)

### Removed

- Remove Geo sitemap support. Google no longer supports them. [#246](https://github.com/kjvarga/sitemap_generator/issues/246)
- Remove gem post-install message warning about incompatible changes in version 4.

### Fixed

- Use presence of `Rails::VERSION` to detect when running under Rails, rather than just the `Rails` constant. [#221](https://github.com/kjvarga/sitemap_generator/pull/221)

## [5.2.0] - 2016-09-23

### Added

- New `SitemapGenerator::AwsSdkAdapter` adapter using the bare aws-sdk gem.
- Support string option keys passed to `add`.

### Changed

- In Railtie, load the rake task instead of requiring them.

### Fixed

- Fix Bing ping url.

## [5.1.0] - 2015-07-15

### Added

- Implement `respond_to?` on the `SitemapGenerator::Sitemap` pseudo class.

### Changed

- Require only `fog-aws` instead of `fog` for the `S3Adapter` and support using an IAM profile instead of setting the access key & secret directly.
- Make `:lang` optional on alternate links so they can be used for [AppIndexing](https://developers.google.com/app-indexing/reference/deeplinks).

## [5.0.5] - 2014-07-30

### Added

- Allow any Fog storage options for the S3 adapter. [#167](https://github.com/kjvarga/sitemap_generator/pull/167)

### Changed

- Use MIT licence.

### Fixed

- Fix deploys with Capistrano 3. [#163](https://github.com/kjvarga/sitemap_generator/issues/163)

## [5.0.4] - 2014-05-16

### Fixed

- Don't include the `media` attribute on alternate links unless it's given.

## [5.0.3] - 2014-05-15

### Added

- Add support for Video sitemaps options `:live` and `:requires_subscription`.

## [5.0.2] - 2014-04-02

### Changed

- Set maximum filesize to 10,000,000 bytes rather than 10,485,760 bytes.

## [5.0.1] - 2014-03-04

### Added

- Include new `SitemapGenerator::FogAdapter`. [#138](https://github.com/kjvarga/sitemap_generator/pull/138)
- Include Capistrano 3.x tasks. [#141](https://github.com/kjvarga/sitemap_generator/pull/141)

### Fixed

- Fix usage of `attr_*` methods in `LinkSet`.
- Don't override custom getters/setters. [#144](https://github.com/kjvarga/sitemap_generator/pull/144)

## [5.0.0] - 2014-02-05

### Added

- Support new `:compress` option for customizing which files get compressed.
- Support `fog_path_style` option in the `SitemapGenerator::S3Adapter` so buckets with dots in the name work over HTTPS without SSL certificate problems.

### Removed

- Removed options to `LinkSet::add()`: `:sitemaps_namer` and `:sitemap_index_namer` (use `:namer` option).
- Removed `LinkSet::sitemaps_namer=`, `LinkSet::sitemaps_namer` (use `LinkSet::namer=` and `LinkSet::namer`).
- Removed `LinkSet::sitemaps_index_namer=`, `LinkSet::sitemaps_index_namer` (use `LinkSet::namer=` and `LinkSet::namer`).
- Removed the `SitemapGenerator::SitemapNamer` class (use `SitemapGenerator::SimpleNamer`).
- Removed `LinkSet::add_links()` (use `LinkSet::create()`).

## [4.3.1] - 2013-12-10

### Added

- Support integer timestamps.

## [4.3.0] - 2013-11-14

### Added

- Support `media` attribute on alternate links. [#125](https://github.com/kjvarga/sitemap_generator/issues/125)
- Support `url:expires` element. [#126](https://github.com/kjvarga/sitemap_generator/issues/126)

### Removed

- Remove Sitemap Writer from ping task. [#129](https://github.com/kjvarga/sitemap_generator/issues/129)

### Fixed

- Changed `SitemapGenerator::S3Adapter` to write files in a single operation, avoiding potential permissions errors when listing a directory prior to writing. [#130](https://github.com/kjvarga/sitemap_generator/issues/130)

## [4.2.0] - 2013-08-16

### Added

- Support Video `video:price` element. [#117](https://github.com/kjvarga/sitemap_generator/issues/117)
- Support symbols as well as strings for most arguments to `add()`. [#113](https://github.com/kjvarga/sitemap_generator/issues/113)

### Fixed

- Update Google ping URL.
- Quote the ping URL in the output.
- Ensure that `public_path` and `sitemaps_path` end with a slash (`/`).

## [4.1.1] - 2013-07-13

### Added

- Support setting the S3 region.
- Output the URL being pinged in the verbose output.

### Fixed

- Fixed bug where incorrect URL was being used in the ping to search engines - only affected sites with a single sitemap file and no index file.

## [4.1.0] - 2013-06-03

### Added

- [PageMap sitemap](https://developers.google.com/custom-search/docs/structured_data#pagemaps) support.

## [4.0.1] - 2013-05-03

### Added

- Add a post-install message regarding the naming convention change.

## [4.0] - 2013-05-02

### Added

- Define `SitemapGenerator::SimpleNamer` class for simpler custom namers compatible with the new naming conventions.
- Support `nofollow` option on alternate links.

### Changed

- **BREAKING**: `create_index` defaults to `:auto`.

### Deprecated

- Deprecate `sitemaps_namer`, `sitemap_index_namer`, and their respective namer classes.

### Fixed

- Fix formatting of `publication_date` in News sitemaps.

## [3.4] - 2012-10-03

### Added

- Support [alternate links](http://support.google.com/webmasters/bin/answer.py?hl=en&answer=2620865) for urls.
- Support configurable options in the `SitemapGenerator::S3Adapter`.

## [3.3] - 2012-10-03

### Added

- Support creating sitemaps with no index file.

## [3.2.1] - 2012-08-11

### Fixed

- Fix syntax error in `SitemapGenerator::S3Adapter`.

## [3.2] - 2012-08-09

### Added

- Support mobile tags.
- Add `SitemapGenerator::S3Adapter`, a simple S3 adapter which uses Fog and doesn't require CarrierWave.

### Changed

- [Turn off `include_index`](https://github.com/kjvarga/sitemap_generator/issues/70) by default.

### Removed

- Remove Ask from the sitemap ping because the service has been shut down.

### Fixed

- Fix the news XML namespace.
- Only include `autoplay` attribute if present.

## [3.1.1] - 2012-03-23

### Changed

- Groups inherit current adapter.

### Fixed

- Bugfix.

## [3.1.0] - 2012-03-22

### Added

- Add `add_to_index` method to add links to the sitemap index.
- Add `sitemap` method for accessing the `LinkSet` instance from within `create()`.

### Fixed

- Don't modify options hashes passed to methods. Fix and improve `yield_sitemap` option handling.

## [3.0.0] - 2012-01-22

### Added

- Show directory sitemaps are being generated into.
- Toggle output using VERBOSE environment variable.

### Changed

- **Framework agnostic!**
- Only show sitemap compressed file size.
- Simplify dependencies.

### Removed

- Remove tasks/ directory because it's deprecated in Rails 2.

### Fixed

- Fix alignment in output.

## [2.2.1] - 2012-01-07

### Added

- Support adding new search engines to ping and modifying the default search engines.
- Allow the URL of the sitemap index to be passed as an argument to `ping_search_engines`. See Pinging Search Engines in README.

## [2.1.8] - 2011-12-16

### Added

- Extend and improve Video Sitemap support, supporting all element attributes and properly formatting values.

## [2.1.7] - 2011-11-27

### Removed

- Remove Yahoo from ping - the Yahoo service has been shut down.

### Fixed

- Improve format of float priorities.

## [2.1.6] - 2011-10-29

### Fixed

- Fix the `lastmod` value on sitemap file links.

## [2.1.5] - 2011-10-18

### Fixed

- Fix verbose setting in the rake task, it should default to true.

## [2.1.4] - 2011-10-18

### Fixed

- Allow special characters in URLs (don't use `URI.join` to construct URLs).

## [2.1.3] - 2011-09-23

### Fixed

- Fix calling `create` with both `filename` and `sitemaps_namer` options.

## [2.1.2] - 2011-09-20

### Added

- Support multiple videos per url using the new `videos` option to `add()`.

## [2.1.1] - 2011-09-19

### Added

- Support calling `create()` multiple times in a sitemap config.

### Changed

- Support host names with path segments so you can use a `default_host` like `'http://mysite.com/subdirectory/'`.
- Turn off `include_index` when the `sitemaps_host` differs from `default_host`.

## [2.1.0] - 2011-08-31

### Added

- [News sitemap](https://support.google.com/news/publisher/topic/2527688?hl=en&ref_topic=4359874) support.

## [2.0.1.pre2] - 2011-08-03

### Fixed

- Fix uploading to the (bucket) root on a remote server.

## [2.0.1.pre1] - 2011-06-11

### Added

- Support read-only filesystems like Heroku by supporting uploading to a remote host.

## [2.0.1] - 2011-06-01

### Changed

- Minor improvements to verbose handling.

### Fixed

- Prevent missing `Timeout` issue.

## [2.0.0] - 2011-05-20

### Added

- Introducing a new simpler API, Sitemap Groups, Sitemap Namers, and more!

## [1.5.0] - 2011-03-30

### Added

- New options `include_root`, `include_index`.

## [1.4.0] - 2011-03-05

### Added

- Geo sitemap support.
- Multiple sitemap support via CONFIG_FILE rake option.

## [1.3.0] - 2010-11-02

### Added

- Support setting the sitemaps path.

## [1.2.0] - 2010-10-14

### Changed

- Verified working with Rails 3 stable release.

## [1.1.0] - 2010-09-16

### Added

- [Video sitemap](https://support.google.com/webmasters/answer/80471?hl=en&ref_topic=4581190) support.

## [0.2.6] - 2010-05-17

### Added

- [Image Sitemap](http://www.google.com/support/webmasters/bin/answer.py?answer=178636) support.

## [0.2.5] - 2010-04-19

### Added

- Rails 3 prerelease support (beta).

[Unreleased]: https://github.com/kjvarga/sitemap_generator/compare/v7.1.1...HEAD
[7.1.1]: https://github.com/kjvarga/sitemap_generator/compare/v7.1.0...v7.1.1
[7.1.0]: https://github.com/kjvarga/sitemap_generator/compare/v7.0.3...v7.1.0
[7.0.3]: https://github.com/kjvarga/sitemap_generator/compare/v7.0.2...v7.0.3
[7.0.2]: https://github.com/kjvarga/sitemap_generator/compare/v7.0.1...v7.0.2
[7.0.1]: https://github.com/kjvarga/sitemap_generator/compare/v6.3.0...v7.0.1
[6.3.0]: https://github.com/kjvarga/sitemap_generator/compare/v6.2.1...v6.3.0
[6.2.1]: https://github.com/kjvarga/sitemap_generator/compare/v6.2.0...v6.2.1
[6.2.0]: https://github.com/kjvarga/sitemap_generator/compare/v6.1.2...v6.2.0
[6.1.2]: https://github.com/kjvarga/sitemap_generator/compare/v6.1.1...v6.1.2
[6.1.1]: https://github.com/kjvarga/sitemap_generator/compare/v6.1.0...v6.1.1
[6.1.0]: https://github.com/kjvarga/sitemap_generator/compare/v6.0.2...v6.1.0
[6.0.2]: https://github.com/kjvarga/sitemap_generator/compare/v6.0.1...v6.0.2
[6.0.1]: https://github.com/kjvarga/sitemap_generator/compare/v6.0.0...v6.0.1
[6.0.0]: https://github.com/kjvarga/sitemap_generator/compare/v5.3.1...v6.0.0
[5.3.1]: https://github.com/kjvarga/sitemap_generator/compare/v5.3.0...v5.3.1
[5.3.0]: https://github.com/kjvarga/sitemap_generator/compare/v5.2.0...v5.3.0
[5.2.0]: https://github.com/kjvarga/sitemap_generator/compare/v5.1.0...v5.2.0
[5.1.0]: https://github.com/kjvarga/sitemap_generator/compare/v5.0.5...v5.1.0
[5.0.5]: https://github.com/kjvarga/sitemap_generator/compare/v5.0.4...v5.0.5
[5.0.4]: https://github.com/kjvarga/sitemap_generator/compare/v5.0.3...v5.0.4
[5.0.3]: https://github.com/kjvarga/sitemap_generator/compare/v5.0.2...v5.0.3
[5.0.2]: https://github.com/kjvarga/sitemap_generator/compare/v5.0.1...v5.0.2
[5.0.1]: https://github.com/kjvarga/sitemap_generator/compare/v5.0.0...v5.0.1
[5.0.0]: https://github.com/kjvarga/sitemap_generator/compare/v4.3.1...v5.0.0
[4.3.1]: https://github.com/kjvarga/sitemap_generator/compare/v4.3.0...v4.3.1
[4.3.0]: https://github.com/kjvarga/sitemap_generator/compare/v4.2.0...v4.3.0
[4.2.0]: https://github.com/kjvarga/sitemap_generator/compare/v4.1.1...v4.2.0
[4.1.1]: https://github.com/kjvarga/sitemap_generator/compare/v4.1.0...v4.1.1
[4.1.0]: https://github.com/kjvarga/sitemap_generator/compare/v4.0.1...v4.1.0
[4.0.1]: https://github.com/kjvarga/sitemap_generator/compare/v4.0...v4.0.1
[4.0]: https://github.com/kjvarga/sitemap_generator/compare/v3.4...v4.0
[3.4]: https://github.com/kjvarga/sitemap_generator/compare/v3.3...v3.4
[3.3]: https://github.com/kjvarga/sitemap_generator/compare/v3.2.1...v3.3
[3.2.1]: https://github.com/kjvarga/sitemap_generator/compare/v3.2...v3.2.1
[3.2]: https://github.com/kjvarga/sitemap_generator/compare/v3.1.1...v3.2
[3.1.1]: https://github.com/kjvarga/sitemap_generator/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/kjvarga/sitemap_generator/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/kjvarga/sitemap_generator/compare/v2.2.1...v3.0.0
[2.2.1]: https://github.com/kjvarga/sitemap_generator/compare/v2.1.8...v2.2.1
[2.1.8]: https://github.com/kjvarga/sitemap_generator/compare/v2.1.7...v2.1.8
[2.1.7]: https://github.com/kjvarga/sitemap_generator/compare/v2.1.6...v2.1.7
[2.1.6]: https://github.com/kjvarga/sitemap_generator/compare/v2.1.5...v2.1.6
[2.1.5]: https://github.com/kjvarga/sitemap_generator/compare/v2.1.4...v2.1.5
[2.1.4]: https://github.com/kjvarga/sitemap_generator/compare/v2.1.3...v2.1.4
[2.1.3]: https://github.com/kjvarga/sitemap_generator/compare/v2.1.2...v2.1.3
[2.1.2]: https://github.com/kjvarga/sitemap_generator/compare/v2.1.1...v2.1.2
[2.1.1]: https://github.com/kjvarga/sitemap_generator/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/kjvarga/sitemap_generator/compare/v2.0.1.pre2...v2.1.0
[2.0.1.pre2]: https://github.com/kjvarga/sitemap_generator/compare/v2.0.1.pre1...v2.0.1.pre2
[2.0.1.pre1]: https://github.com/kjvarga/sitemap_generator/compare/v2.0.1...v2.0.1.pre1
[2.0.1]: https://github.com/kjvarga/sitemap_generator/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/kjvarga/sitemap_generator/compare/v1.5.0...v2.0.0
[1.5.0]: https://github.com/kjvarga/sitemap_generator/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/kjvarga/sitemap_generator/compare/c322296...v1.4.0
[1.3.0]: https://github.com/kjvarga/sitemap_generator/compare/v1.2.0...c322296
[1.2.0]: https://github.com/kjvarga/sitemap_generator/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/kjvarga/sitemap_generator/compare/v0.2.6...v1.1.0
[0.2.6]: https://github.com/kjvarga/sitemap_generator/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/kjvarga/sitemap_generator/compare/v0.2.4...v0.2.5
