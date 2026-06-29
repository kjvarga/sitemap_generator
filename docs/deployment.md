<!-- DRAFT: review and edit before committing -->

# Deployment

`sitemap_generator` is a RubyGem published to [RubyGems.org](https://rubygems.org/gems/sitemap_generator). There are no servers or environments to deploy in the traditional sense.

## Releasing a new version

### Prerequisites

- You must be an owner of the `sitemap_generator` gem on RubyGems.org.
- MFA is required on RubyGems.org (`rubygems_mfa_required` is set in the gemspec).
- You must be on the `master` branch.

### Steps

1. Ensure all CI checks pass on `master`.
2. Update `VERSION` (e.g. `7.0.2`).
3. Add a `### X.Y.Z` section to `CHANGES.md` describing changes since the last release.
4. Commit both files: `git commit -m "Release X.Y.Z"`.
5. Run `bundle exec rake release`.

`rake release` does the following:
- Builds `pkg/sitemap_generator-X.Y.Z.gem`
- Creates git tag `vX.Y.Z` (skipped if the tag already exists at HEAD)
- Pushes the branch and tag to `origin`
- Pushes the built gem to RubyGems.org

### Versioning

Follows [Semantic Versioning](https://semver.org/):
- **Patch** (`X.Y.Z+1`) — bug fixes, no API changes
- **Minor** (`X.Y+1.0`) — new features, backwards-compatible
- **Major** (`X+1.0.0`) — breaking changes (document under `**Breaking:**` in `CHANGES.md`)

## Config and secrets

- No application config files or `.env` files.
- RubyGems credentials are stored in `~/.gem/credentials` (set up via `gem signin`).
- No secrets are committed to the repository.

## CI

GitHub Actions runs the full Ruby × Rails matrix on every push and PR (see `.github/workflows/ci.yml`). A monthly scheduled run catches compatibility regressions with new Ruby/Rails releases.

## Rollback

A bad gem release cannot be deleted from RubyGems.org (yanking is discouraged and only removes the gem from search/install by default). Instead:
- Cut a patch release (`X.Y.Z+1`) that reverts or fixes the problem.
- If the release introduced a breaking change unintentionally, bump the major version and document the revert.
