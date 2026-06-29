
# Glossary

### Sitemap

An XML file listing URLs on a website along with metadata (last modified date, change frequency, priority). Adheres to the [Sitemap 0.9 protocol](https://www.sitemaps.org/protocol.html). In this gem, a sitemap is represented by `SitemapGenerator::Builder::SitemapFile`.

### Sitemap Index

A special XML file that lists multiple sitemap files rather than page URLs. Generated automatically when more than one sitemap file is needed (controlled by `create_index`). Represented by `SitemapGenerator::Builder::SitemapIndexFile`.

### LinkSet

The central orchestration object (`SitemapGenerator::LinkSet`). Owns configuration (host, adapter, paths) and manages the lifecycle of sitemap files from creation through finalization.

### Adapter

A write backend that persists sitemap files. Any class with a `write(location, raw_data)` method qualifies. Built-in adapters: `FileAdapter` (local disk), `AwsSdkAdapter` (S3 via aws-sdk-s3), `S3Adapter` (S3 via fog), `FogAdapter`, `GoogleStorageAdapter`, `ActiveStorageAdapter`, `WaveAdapter`.

### Location (`SitemapLocation`)

A value object (backed by a `Hash` subclass) that resolves the full filesystem path and public URL of a sitemap file given a host, public path, sitemaps path, and filename/namer.

### Namer (`SimpleNamer`)

Generates sequential sitemap filenames: `sitemap.xml.gz`, `sitemap1.xml.gz`, `sitemap2.xml.gz`, etc. Configurable via the `:filename` option (base name) or `:namer` option (custom `SimpleNamer` instance).

### Finalize / `finalize!`

Closes a `SitemapFile` or `SitemapIndexFile`, writes it through the adapter, and freezes it against further modification. After finalization, the file object raises `SitemapFinalizedError` if you attempt to add links to it.

### Group

A scoped set of sitemap files within a `create` block, created via `LinkSet#group`. A group shares the parent's sitemap index but can have its own filename, path, host, and adapter. Groups are finalized when their block exits.

### Interpreter

The object (`SitemapGenerator::Interpreter`) that evaluates the user's sitemap config block. It includes Rails URL helpers (when running under Rails) so that `article_path(article)` etc. work inside the block.

### `default_host`

The base URL (scheme + host) prepended to relative paths when generating sitemap `<loc>` entries. Required; must be set before calling `create`. Example: `'https://www.example.com'`.

### `sitemaps_host`

The host where the sitemap files themselves are served, if different from `default_host` (e.g. an S3 or CDN URL). Used in the sitemap index `<loc>` entries that point to each sitemap file. Setting this automatically disables `include_index`.

### `sitemaps_path`

A subdirectory under `public_path` where sitemaps are written (e.g. `'sitemaps/'`). Useful to organise sitemaps away from the webroot.

### `compress`

Controls gzip compression of output files. Accepted values: `true` (compress all — default), `false` (no compression), `:all_but_first` (leave the first sitemap file uncompressed for direct URL access, compress the rest).

### `create_index`

Controls whether a sitemap index file is generated. Values: `:auto` (default — only when more than one sitemap file exists), `true` (always), `false` (never).

### `include_root`

Boolean (default `true`). When `true`, the root URL `'/'` is automatically added as the first entry in the sitemap. Set to `false` to suppress it.

### `include_index`

Boolean (default `false`). When `true`, a link to the sitemap index file is added to the sitemap itself. Automatically disabled when `sitemaps_host` differs from `default_host`.

### `ping_search_engines`

A method that sends HTTP GET pings to configured search engine URLs, notifying them that the sitemap has been updated. Since Google deprecated its ping endpoint, the default `search_engines` hash is now empty — configure manually if needed.

### Appraisal

A testing tool (gem) used to run the spec suite against multiple Gemfile variants. Each `gemfiles/rails_X.Y.gemfile` pin a specific Rails version. Used to validate the Ruby × Rails compatibility matrix in CI.
