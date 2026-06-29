<!-- DRAFT: review and edit before committing -->

# Testing

## Philosophy

Tests verify that the gem produces correct XML output, respects configuration options, and that adapters interact correctly with their backends. Coverage is expected for all new code. Tests run in random order to surface hidden ordering dependencies.

## Test types

| Type | Location | What it covers |
|---|---|---|
| Unit specs | `spec/sitemap_generator/` | Individual classes: `LinkSet`, `SitemapFile`, `SitemapLocation`, adapters, helpers, core extensions. |
| Integration specs | `integration/spec/sitemap_generator/` | Full Rails app behaviour via Combustion: Railtie initializers, Rake tasks, `config.sitemap.*` options. |

There are no browser or end-to-end tests — the gem has no UI.

## What to mock vs. not

- **Mock:** HTTP calls to search engine ping URLs — use WebMock (already configured in `spec_helper.rb`). Real network calls are disabled globally (`WebMock.disable_net_connect!`).
- **Mock:** Cloud storage clients (`Aws::S3::Client`, Fog, GCS) in adapter unit tests — use `instance_double` or `allow/expect` stubs.
- **Do not mock:** `FileAdapter` writes — use the real filesystem with `tmp/test/` paths already set up in spec helpers.
- **Do not mock:** `LinkSet` / `SitemapFile` internals in integration specs — exercise the full stack.

## Running tests

```bash
# Full unit suite (default Rails version from Gemfile)
bundle exec rake spec

# Single spec file
bundle exec rspec spec/sitemap_generator/link_set_spec.rb

# Single example by description (partial match)
bundle exec rspec spec/sitemap_generator/link_set_spec.rb -e "default options"

# With coverage report (HTML output in coverage/)
COVERAGE=true bundle exec rake spec

# Against a specific Rails version
BUNDLE_GEMFILE=gemfiles/rails_8.1.gemfile bundle exec rake spec

# Integration specs (requires separate bundle install in integration/)
cd integration && bundle exec rspec
```

## Fixtures and factories

- No factories (FactoryBot). Test objects are constructed inline using `LinkSet.new(default_host: 'http://example.com')`.
- XML fixture files for schema validation live in `spec/support/schemas/`.
- Sample sitemap config files for integration tests live in `integration/spec/files/`.
- The `SitemapHelpers` module (in `spec/support/sitemap_helpers.rb`) provides helpers for resetting `SitemapGenerator::Sitemap` state between tests.

## Adding a new test

1. Create `spec/sitemap_generator/<matching_lib_path>_spec.rb` mirroring the lib path.
2. Add `require 'spec_helper'` at the top.
3. Use `RSpec.describe SitemapGenerator::ClassName` at the top level.
4. Use `describe '#method_name'` for instance methods, `describe '.method_name'` for class methods.
5. Use `context 'when <condition>'` for branches; `it 'returns/raises/writes ...'` in declarative present tense.
   - **Rule:** conditions belong in a `context` block, not embedded in the `it` description. Wrong: `it 'returns nil when user is absent'`. Right: `context 'when user is absent' do; it 'returns nil'`.
6. For adapter tests that write files, use a temp path under `tmp/test/` and clean up in an `after` hook.

Example skeleton:

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::MyClass do
  let(:subject) { described_class.new }

  describe '#my_method' do
    context 'when condition is true' do
      it 'returns the expected value' do
        expect(subject.my_method).to eq('expected')
      end
    end
  end
end
```

For an adapter spec, use `instance_double` for the location:

```ruby
# spec/sitemap_generator/adapters/my_adapter_spec.rb
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SitemapGenerator::MyAdapter do
  let(:adapter)  { described_class.new }
  let(:location) { instance_double(SitemapGenerator::SitemapLocation, path: '/tmp/sitemap.xml.gz', directory: '/tmp') }

  describe '#write' do
    context 'when the backend is available' do
      it 'writes the file' do
        expect { adapter.write(location, '<xml/>') }.not_to raise_error
      end
    end
  end
end
```

**Do not** use `should` in `it` descriptions — use declarative present tense ("raises", "writes", "returns").
