
# Contributing

## Branch naming

`<username>/<verb-first-kebab-description>` — e.g. `kvarga/fix-aws-upload-deprecation`

If the change is associated with a GitHub issue, suffix the branch with the issue number: `kvarga/fix-aws-upload-deprecation-464`.

## Commit format

Use [Conventional Commits](https://www.conventionalcommits.org/) — `<type>(<scope>): <description>` — lowercase, no trailing period:

```
fix(adapters): replace deprecated S3 upload path with TransferManager
feat(railtie): infer default_host from Rails url_options
chore: bump VERSION to 7.0.2
docs: add CLAUDE.md and architecture docs
```

Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`. Scope is optional but useful for adapters, railtie, builder, etc.

For release commits the convention is `chore: release X.Y.Z`.

## Opening a PR

Before opening a PR:
- All specs pass: `bundle exec rake spec`
- Lint is clean: `bundle exec rubocop`
- New behaviour is covered by tests
- `CHANGES.md` is updated with a bullet under the next version heading
- `VERSION` is bumped if this is a release PR

PR title: use semantic commit style — `<type>(<scope>): <description>` — matching the commit format above.

PR description: what the change does and why; link to the relevant issue if applicable.

## Review process

Maintainer review is required before merging. Reviews focus on:
- Correctness across the Ruby × Rails version matrix
- No new runtime gem dependencies
- `frozen_string_literal: true` present on new Ruby files (enforced by RuboCop)
- Adapter changes don't eagerly `require` backend gems
- Public API changes are documented in `CHANGES.md`
- Breaking changes are clearly called out in `CHANGES.md` under `**Breaking:**` and require a major version bump
- Backwards compatibility is preserved across all supported Ruby and Rails versions

## Getting merged

The maintainer merges accepted PRs. Squash merging is preferred to keep history clean.

## Releasing a new version

See [docs/deployment.md](docs/deployment.md) for the full release process.
