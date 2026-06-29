<!-- DRAFT: review and edit before committing -->

# Contributing

## Branch naming

`<username>/<verb-first-kebab-description>` — e.g. `kvarga/fix-aws-upload-deprecation`

If the change is associated with a GitHub issue, suffix the branch with the issue number: `kvarga/fix-aws-upload-deprecation-464`.

## Commit format

No enforced convention. Write clear, present-tense imperative messages describing the effect:

```
Fix AWS SDK upload deprecation in AwsSdkAdapter
Enhance Rails railtie to respect existing rails configuration
Add support for Ruby 4.0
```

Avoid commit messages that only describe what changed (not why), e.g. `Update aws_sdk_adapter.rb`.

For release commits, the convention is `Release X.Y.Z` (see `rake release`).

## Opening a PR

Before opening a PR:
- All specs pass: `bundle exec rake spec`
- Lint is clean: `bundle exec rubocop`
- New behaviour is covered by tests
- `CHANGES.md` is updated with a bullet under the next version heading
- `VERSION` is bumped if this is a release PR

PR title: short imperative phrase describing the effect (not the files changed).

PR description: what the change does and why; link to the relevant issue if applicable.

## Review process

Maintainer review is required before merging. Reviews focus on:
- Correctness across the Ruby × Rails version matrix
- No new runtime gem dependencies
- `frozen_string_literal: true` present on new Ruby files
- Adapter changes don't eagerly `require` backend gems
- Public API changes are documented in `CHANGES.md`

## Getting merged

The maintainer merges accepted PRs. Squash merging is preferred to keep history clean.

## Releasing a new version

1. Update `VERSION` with the new version string.
2. Add a section to `CHANGES.md` describing what changed.
3. Commit: `git commit -m "Release X.Y.Z"`.
4. Run `bundle exec rake release` — this builds the gem, creates the git tag, pushes to GitHub, and publishes to RubyGems.

If the tag already exists and points at HEAD, the release task skips tagging and continues.
