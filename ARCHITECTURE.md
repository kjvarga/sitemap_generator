# Architecture

## System overview

`sitemap_generator` accepts a user-supplied Ruby block describing which URLs to include in a sitemap, builds Sitemap 0.9-compliant XML (optionally gzipped), and writes the output via a pluggable adapter — to the local filesystem by default, or to a remote store like S3, GCS, or Fog. Inputs are URLs and metadata (changefreq, priority, images, video, news, etc.); outputs are `.xml.gz` sitemap files plus a sitemap index file.

## Components

| Component | File(s) | Responsibility |
|---|---|---|
| `SitemapGenerator::Sitemap` | `lib/sitemap_generator.rb` | Top-level singleton (a `Config` instance); delegates all method calls to an internal `LinkSet` via `method_missing`. |
| `LinkSet` | `lib/sitemap_generator/link_set.rb` | Orchestrates sitemap creation: owns configuration (host, path, adapter), drives the `Interpreter`, and coordinates `SitemapFile` / `SitemapIndexFile` lifecycle. |
| `Interpreter` | `lib/sitemap_generator/interpreter.rb` | Evaluates the user's sitemap config block; includes Rails URL helpers when available; exposes `add` and `group`. |
| `SitemapFile` | `lib/sitemap_generator/builder/sitemap_file.rb` | Builds one sitemap file (compressed or uncompressed); buffers `<url>` entries until full (50k links or 50 MB), then calls `finalize!`. |
| `SitemapIndexFile` | `lib/sitemap_generator/builder/sitemap_index_file.rb` | Builds the index file listing all sitemap files; finalized after all sitemaps are written. |
| `SitemapLocation` | `lib/sitemap_generator/sitemap_location.rb` | Value object combining public path, host, filename, and compression flag into a resolved file path + URL. |
| Adapters | `lib/sitemap_generator/adapters/` | Pluggable write backends: `FileAdapter` (default), `AwsSdkAdapter`, `S3Adapter`, `FogAdapter`, `GoogleStorageAdapter`, `ActiveStorageAdapter`, `WaveAdapter`. Each must implement `write(location, raw_data)`. |
| `Railtie` | `lib/sitemap_generator/railtie.rb` | Hooks into Rails boot to infer `default_host`, `sitemaps_host`, `compress`, and `public_path` from existing Rails config; loads Rake tasks. |
| `Templates` | `lib/sitemap_generator/templates.rb` | Provides the `sitemap.rb` template written by `rake sitemap:install`. |
| `Application` | `lib/sitemap_generator/application.rb` | Detects whether Rails is loaded and its version. |
| `Utilities` | `lib/sitemap_generator/utilities.rb` | Shared helpers: `reverse_merge`, `truthy?/falsy?`, adapter resolution. |

## Data flow

1. User calls `SitemapGenerator::Sitemap.create { add '/path', ... }` (or Rake runs `sitemap:refresh`).
1. `Sitemap` delegates to `LinkSet#create` via `method_missing`.
1. `LinkSet` resets state, applies options, then passes the block to `Interpreter#eval`.
1. `Interpreter` includes Rails URL helpers (if on Rails) and calls `LinkSet#add` for each link.
1. `LinkSet#add` appends the link to the current `SitemapFile`; when the file is full it is finalized and a new one started.
1. When the block exits, `LinkSet#finalize!` closes the final `SitemapFile` and writes the `SitemapIndexFile`.
1. Each file's raw XML is passed to the configured adapter's `write(location, raw_data)`, which persists it.

## Key decisions

- **Adapter pattern for storage** — keeping write logic out of `LinkSet` allows the gem to support any storage backend without coupling to a specific SDK. Adapters are autoloaded so unused backends don't pull in their SDKs.
- **`method_missing` delegation on `Sitemap`** — `Sitemap` is a singleton that wraps a `LinkSet` instance. The delegation via `method_missing` / `respond_to_missing?` avoids re-exposing every `LinkSet` method and allows the internal `LinkSet` to be replaced on `reset!` without callers noticing.
- **`frozen_string_literal: true` everywhere** — reduces object allocations and guards against accidental string mutation; required on all source files.
- **No runtime Rails dependency** — the gem detects Rails at load time and loads the Railtie only when Rails is present, keeping it usable in non-Rails scripts.
- **Appraisal for multi-Rails testing** — rather than relying on a single Rails version in CI, Appraisal generates per-version lockfiles so the full Ruby × Rails matrix is tested.

## What to avoid

- **Do not add runtime `require` statements for adapter dependencies** — adapters raise `LoadError` with a clear message if their dependency is missing; loading eagerly would impose the dependency on all users.
- **Do not call `SitemapGenerator::Sitemap.class`** — `Sitemap` is an instance of the anonymous `Config` class. Reference it only as `SitemapGenerator::Sitemap`.
- **Do not bypass `finalize!`** — writing to a `SitemapFile` after it has been finalized raises `SitemapFinalizedError`. Always let `LinkSet#create` manage the lifecycle, or call `finalize!` explicitly when building programmatically.
