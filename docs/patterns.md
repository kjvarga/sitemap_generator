# Patterns

## Writing a new adapter

Use when you need to persist sitemap files to a storage backend not already supported.

Implement a single `write(location, raw_data)` method. The `FileAdapter` is the canonical example:

```ruby
# lib/sitemap_generator/adapters/my_adapter.rb
# frozen_string_literal: true

module SitemapGenerator
  class MyAdapter
    def write(location, raw_data)
      # location.path  => Pathname to the file (e.g. /var/app/public/sitemap1.xml.gz)
      # location.directory => parent directory
      # raw_data       => uncompressed XML string
      #
      # If location.path ends in .gz, compress before writing.
      SitemapGenerator::FileAdapter.new.write(location, raw_data)  # write locally first
      # ... then upload raw_data to your backend
    end
  end
end
```

**Do not:** add a `require` for the backend gem at the top of the adapter file. Instead, raise `LoadError` with a clear message if the constant is undefined (pattern from `AwsSdkAdapter`):

```ruby
unless defined?(MyBackend::Client)
  raise LoadError, "Please `require 'my-backend-gem'` before using MyAdapter."
end
```

---

## Adding a link to a sitemap

Use inside a `create` block to add URLs with metadata.

```ruby
SitemapGenerator::Sitemap.default_host = 'https://example.com'
SitemapGenerator::Sitemap.create do
  add '/articles', changefreq: 'daily', priority: 0.9
  add '/contact',  changefreq: 'monthly', lastmod: Time.now
  add '/photo',    images: [{ loc: 'https://cdn.example.com/photo.jpg', title: 'A photo' }]
end
```

**Do not** call `finalize!` yourself inside a `create` block — the block form calls it automatically.

---

## Programmatic (blockless) sitemap creation

Use when you need to add links outside a block (e.g. in a background job with streaming records).

```ruby
SitemapGenerator::Sitemap.default_host = 'https://example.com'
SitemapGenerator::Sitemap.create  # no block — does NOT call finalize!

Article.find_each do |article|
  SitemapGenerator::Sitemap.add article_path(article), lastmod: article.updated_at
end

SitemapGenerator::Sitemap.finalize!  # must be called explicitly
```

**Do not** omit `finalize!` — sitemaps will not be written.

---

## Grouping sitemaps

Use when you want separate sitemap files per section (different path, filename, or host).

```ruby
SitemapGenerator::Sitemap.create do
  group(filename: :sitemap_en, sitemaps_path: 'en/') do
    add '/en/home'
  end
  group(filename: :sitemap_fr, sitemaps_path: 'fr/') do
    add '/fr/accueil'
  end
end
```

---

## Configuring the adapter (S3 example)

Set the adapter on `Sitemap` before calling `create`:

```ruby
SitemapGenerator::Sitemap.adapter = SitemapGenerator::AwsSdkAdapter.new(
  'my-bucket',
  region: 'us-east-1',
  acl: 'public-read'
)
```

In Rails, set it via `config.sitemap.adapter` in `config/application.rb` — the Railtie resolves symbols and strings to adapter classes via `Utilities.find_adapter`:

```ruby
config.sitemap.adapter = :aws_sdk  # resolves to SitemapGenerator::AwsSdkAdapter
```

---

## Writing a spec for a new class

See [docs/testing.md](testing.md) for the spec skeleton, structure rules, and examples.
