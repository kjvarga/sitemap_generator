<!-- DRAFT: review and edit before committing -->

# Public API

`sitemap_generator` is a Ruby gem; its "API" is the public Ruby interface exposed to gem consumers.

---

## `SitemapGenerator::Sitemap` (singleton)

All options set on `Sitemap` are delegated to an internal `LinkSet` instance via `method_missing`.

### Configuration options

Set before or during `create`:

| Option | Type | Default | Description |
|---|---|---|---|
| `default_host=` | String | — | **Required.** Base URL for all link `<loc>` values (e.g. `'https://www.example.com'`). |
| `sitemaps_host=` | String | `default_host` | Host where sitemap files are served, if different (e.g. an S3 URL). |
| `sitemaps_path=` | String | `nil` | Subdirectory under `public_path` (e.g. `'sitemaps/'`). |
| `public_path=` | String | `'public/'` | Directory to write sitemaps into. |
| `adapter=` | Adapter | `FileAdapter` | Write backend. |
| `filename=` | Symbol | `:sitemap` | Base name for output files. |
| `compress=` | Boolean/Symbol | `true` | `true`, `false`, or `:all_but_first`. |
| `create_index=` | Symbol/Boolean | `:auto` | `:auto`, `true`, or `false`. |
| `include_root=` | Boolean | `true` | Auto-add `'/'` as the first link. |
| `include_index=` | Boolean | `false` | Add a link to the sitemap index inside the sitemap. |
| `max_sitemap_links=` | Integer | `50_000` | Max links per sitemap file. |
| `search_engines=` | Hash | `{}` | Map of engine name → ping URL. Empty by default. |
| `verbose=` | Boolean | `nil` | Print progress to stdout. |

---

### `create(opts = {}, &block)`

Generates the sitemap. When called with a block, `finalize!` is called automatically at the end. When called without a block, `finalize!` must be called manually.

```ruby
SitemapGenerator::Sitemap.default_host = 'https://example.com'
SitemapGenerator::Sitemap.create do
  add '/about'
  add '/contact', changefreq: 'monthly', priority: 0.8
end
```

Returns `self` (the `LinkSet`).

---

### `add(path, options = {})`

Adds a URL to the current sitemap. Called inside a `create` block.

| Option | Type | Default | Description |
|---|---|---|---|
| `host` | String | `default_host` | Override the host for this link only. |
| `lastmod` | Time/Date/String | `nil` | Last-modified date. |
| `changefreq` | String | `nil` | `'always'`, `'hourly'`, `'daily'`, `'weekly'`, `'monthly'`, `'yearly'`, `'never'`. |
| `priority` | Float | `nil` | 0.0–1.0. |
| `images` | Array | `[]` | Array of image hashes (`loc`, `title`, `caption`, `geo_location`, `license`). |
| `videos` | Array | `[]` | Array of video hashes (see [README](../README.md#video-sitemaps)). |
| `news` | Hash | `nil` | Google News sitemap entry. |
| `mobile` | Boolean | `false` | Include mobile namespace. |
| `pagemap` | Hash | `nil` | Google PageMap data block. |
| `alternates` | Array | `[]` | Alternate language links (`href`, `lang`). |

---

### `group(opts = {}, &block)`

Creates a scoped group of sitemap files with different settings. All options accepted by `LinkSet.new` are valid except `:public_path`. The group shares the parent's sitemap index.

```ruby
SitemapGenerator::Sitemap.create do
  group(filename: :sitemap_en, sitemaps_path: 'en/') do
    add '/en/home'
  end
end
```

---

### `finalize!`

Closes and writes the current sitemap file and the sitemap index. Called automatically at the end of a `create` block. Must be called manually in blockless usage.

---

### `ping_search_engines(engines = search_engines)`

Sends HTTP GET pings to the URLs in `search_engines`. No-op if `search_engines` is empty (the default). Pass a hash of `name => url` to override.

---

### `reset!`

Resets the internal `LinkSet` to a fresh state. Called automatically at the start of each `create` call.

---

## Rake tasks

Available automatically in Rails (via Railtie); can be loaded manually with `require 'sitemap_generator/tasks'`.

| Task | Description |
|---|---|
| `rake sitemap:install` | Copy the sample `config/sitemap.rb` template. |
| `rake sitemap:refresh` | Generate the sitemap, then ping search engines. Calls `create` then `ping_search_engines`. |
| `rake sitemap:refresh:no_ping` | Generate the sitemap without pinging. |
| `rake sitemap:clean` | Remove generated sitemap files from `public/`. |

Environment variable `CONFIG_FILE` overrides the default config path (`config/sitemap.rb` in Rails, `sitemap.rb` otherwise).

---

## Error classes

| Class | Superclass | When raised |
|---|---|---|
| `SitemapGenerator::SitemapError` | `StandardError` | Base class for all sitemap errors. |
| `SitemapGenerator::SitemapFullError` | `SitemapError` | A link was added to a sitemap file that is already at capacity. |
| `SitemapGenerator::SitemapFinalizedError` | `SitemapError` | A link was added to a sitemap file after it was finalized. |
