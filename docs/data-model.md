<!-- DRAFT: review and edit before committing -->

# Data Model

This gem has no database. The "data model" is the set of in-memory objects that represent a sitemap generation run.

---

### LinkSet

Purpose: Top-level configuration and orchestration object for one sitemap generation run.

Key fields:
- `default_host` — required base URL for all link `<loc>` values
- `sitemaps_host` — optional override for the host used in index `<loc>` entries
- `sitemaps_path` — subdirectory under `public_path` for output files
- `adapter` — the write backend (defaults to `FileAdapter`)
- `filename` — base name for generated files (default `:sitemap`)
- `namer` — `SimpleNamer` instance; auto-created from `filename` if not set
- `compress` — `true` / `false` / `:all_but_first`
- `create_index` — `:auto` / `true` / `false`
- `max_sitemap_links` — cap per sitemap file (default 50,000)

Relationships:
- owns one `SitemapIndexFile` (the current index)
- owns one `SitemapFile` at a time (the current sitemap being built)
- delegates writes to an `Adapter`

Invariants:
- `default_host` must be set before `add` is called
- Once `finalize!` is called, the `LinkSet` state is complete — calling `create` again calls `reset!` first

---

### SitemapFile

Purpose: Represents one `.xml.gz` file being built. Buffers `<url>` entries and finalizes when full.

Key fields:
- `location` — a `SitemapLocation` resolving the file path and URL
- `link_count` — number of `<url>` entries written so far
- `news_count` — number of `<news:news>` entries (capped at 1,000)
- `filesize` — current uncompressed byte size

Invariants:
- Raises `SitemapFullError` when `link_count >= MAX_SITEMAP_LINKS` (50,000) or `filesize >= MAX_SITEMAP_FILESIZE` (50 MB)
- Raises `SitemapFinalizedError` after `finalize!` is called
- After `finalize!` the object is frozen

---

### SitemapIndexFile

Purpose: Represents the index XML file that lists all sitemap files. Shares structure with `SitemapFile` but writes `<sitemap>` entries instead of `<url>` entries.

Invariants:
- At most `MAX_SITEMAP_FILES` (50,000) entries
- Written last, after all `SitemapFile` instances are finalized

---

### SitemapLocation

Purpose: Value object (a `Hash` subclass) that resolves the filesystem path, URL, and adapter for one file.

Key fields:
- `host` — the host used in the file's public URL
- `public_path` — base filesystem directory (e.g. `Rails.public_path`)
- `sitemaps_path` — subdirectory within `public_path`
- `filename` / `namer` — the file's base name or namer instance
- `adapter` — the write backend for this file
- `compress` — whether to gzip this file
- `verbose` — whether to print a summary line when writing

Derived values:
- `path` — full filesystem path (`public_path + sitemaps_path + filename`)
- `url` — full public URL (`host + sitemaps_path + filename`)
- `directory` — parent directory of `path`

---

### SimpleNamer

Purpose: Generates a sequence of filenames for sitemap files.

Sequence: `sitemap.xml.gz`, `sitemap1.xml.gz`, `sitemap2.xml.gz`, ...

The first name has no numeric suffix; subsequent names increment from 1. The namer is shared between the `LinkSet` and its `SitemapLocation` instances.

---

### Adapter (interface)

Purpose: Defines the write contract for storage backends.

Required method: `write(location, raw_data)` where `location` is a `SitemapLocation` and `raw_data` is the uncompressed XML string. The adapter is responsible for compression (or may delegate to `FileAdapter` for local writes before uploading).
