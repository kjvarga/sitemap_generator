
# Conventions

## File and directory naming

- Ruby source files use `snake_case.rb`.
- Adapter files live in `lib/sitemap_generator/adapters/` and are named `<backend>_adapter.rb`.
- Builder files (per-file and index) live in `lib/sitemap_generator/builder/`.
- Spec files mirror the lib path: `lib/sitemap_generator/foo.rb` → `spec/sitemap_generator/foo_spec.rb`.
- Integration specs (Rails app) live under `integration/spec/sitemap_generator/`.
- Rake task files live in `lib/tasks/` (plain Ruby) and `lib/sitemap_generator/tasks.rb`.
- Templates (e.g. the generated `sitemap.rb`) live in `templates/`.

## Naming conventions

- Classes and modules: `PascalCase` under the `SitemapGenerator` namespace.
- Methods and variables: `snake_case`.
- Constants: `SCREAMING_SNAKE_CASE` (e.g. `MAX_SITEMAP_LINKS`).
- Adapter class names must end with `Adapter` (e.g. `AwsSdkAdapter`).
- Spec describe blocks use `RSpec.describe ClassName` at the top level; nested blocks use `describe '#method_name'` for instance methods and `describe '.method_name'` for class methods.

## Error handling

- Domain errors subclass `SitemapGenerator::SitemapError` (itself a `StandardError`):
  - `SitemapFullError` — raised when adding a link to a finalized or full sitemap.
  - `SitemapFinalizedError` — raised when mutating a finalized sitemap file.
- Adapters raise `LoadError` (not a custom error) when their required dependency gem is not loaded — include a descriptive message telling the user which gem to `require`.
- Errors propagate up to the caller; the library does not swallow exceptions internally.

## Logging

- No logging library — output goes to `$stdout` via `puts` when `verbose` is truthy.
- Verbosity is controlled by `SitemapGenerator.verbose` (defaults to `nil`, checked against the `VERBOSE` env var).
- Output format: one line per file written, a summary line at the end (link count / file count / elapsed time).
- Do not add `puts` outside of the verbose output path.

## Preferred libraries

| Task | Library |
|---|---|
| XML generation | `builder` (~> 3.0) — already a runtime dependency |
| Compression | Ruby stdlib `zlib` |
| HTTP pings | Ruby stdlib `open-uri` / `URI` |
| Testing | RSpec + WebMock |
| Linting | RuboCop with rubocop-performance, rubocop-rake, rubocop-rspec |
| Multi-version testing | Appraisal |

- Do not add new runtime gem dependencies without strong justification — the gem's only runtime dependency is `builder`.
- Do not use `CGI` for URL encoding (removed for Ruby 4 compatibility); use `URI.encode_www_form_component` instead.
