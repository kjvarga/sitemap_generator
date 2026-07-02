
## Project overview

`sitemap_generator` is a Ruby gem for generating XML Sitemaps adhering to the Sitemap 0.9 protocol. It supports Rails (via a Railtie) and standalone Ruby, and can write sitemaps locally or upload them to S3, GCS, or other cloud storage via adapters. It is used by Ruby and Rails applications that need automated, configurable sitemap generation.

## Tech stack

- Ruby 2.6–4.0; gem runtime dependency: `builder ~> 3.0`
- Rails 6.0–8.1 (optional; loaded via `SitemapGenerator::Railtie`)
- RSpec + Appraisal for a Ruby × Rails test matrix
- RuboCop (+ rubocop-performance, rubocop-rake, rubocop-rspec) for linting

## Common commands

```bash
# Install dependencies
bundle install

# Run the full test suite
bundle exec rake spec

# Run a single spec file
bundle exec rspec spec/sitemap_generator/link_set_spec.rb

# Run specs for a specific Rails version
BUNDLE_GEMFILE=gemfiles/rails_8.1.gemfile bundle exec rake spec

# Lint
bundle exec rubocop

# Build the gem
bundle exec rake build

# Release (tag + push to Git; then push gem manually)
bundle exec rake release
```

## Code style

- `# frozen_string_literal: true` is required on every Ruby file.
- Follow RuboCop config at `.rubocop.yml`; spec files are excluded from Cop enforcement.
- Avoid string mutation; prefer `+` or interpolation over `<<` on frozen-safe paths.

## Conventions

- Adapters live in `lib/sitemap_generator/adapters/`; each wraps a storage backend and must implement `write(location, raw_data)`.
- Rake tasks are defined in `lib/sitemap_generator/tasks.rb`; the Rails Railtie loads them automatically.
- The `SitemapGenerator::Sitemap` top-level object is an anonymous class (named `Config` internally) — do not reference it by a class constant.
- Integration specs (Rails app tests) live under `integration/`; they use Combustion and have their own `Gemfile`.
- Version is sourced from `VERSION` file — do not hardcode it anywhere else.

## Gotchas

- The test matrix uses Appraisal gemfiles (`gemfiles/rails_*.gemfile`). Running `bundle exec rake spec` without a `BUNDLE_GEMFILE` override uses the default `Gemfile` (latest Rails).
- `rake release` tags and pushes; if the tag already exists and points at HEAD it is silently skipped — if it points elsewhere the task aborts.
- `pkg/` contains old built gems; do not edit files under `pkg/`.
- See [ARCHITECTURE.md](ARCHITECTURE.md), [docs/conventions.md](docs/conventions.md), and [docs/testing.md](docs/testing.md) for deeper detail.
