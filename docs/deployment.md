
# Deployment

`sitemap_generator` is a RubyGem published to [RubyGems.org](https://rubygems.org/gems/sitemap_generator). There are no servers or environments to deploy in the traditional sense.

## Releasing a new version

### Prerequisites

- You must be an owner of the `sitemap_generator` gem on RubyGems.org.
- MFA is required on RubyGems.org (`rubygems_mfa_required` is set in the gemspec).
- You must be on the `master` branch.

### Steps

1. Ensure all CI checks pass on `master`.
2. **Audit commits since the last release.** Run `git log vX.Y.Z..HEAD --oneline` (substituting the previous release tag) and confirm every commit is intentional and accounted for. PRs can accumulate on `master` between releases without being noticed — this step prevents unintentional changes from shipping as patch releases.
3. Update `VERSION` (e.g. `7.0.2`).
4. Add a `### X.Y.Z` section to `CHANGES.md` describing every change identified in step 2.
5. Commit both files: `git commit -m "Release X.Y.Z"`.
6. Run `bundle exec rake release`.
7. Push the gem to RubyGems: `gem push pkg/sitemap_generator-X.Y.Z.gem`

`rake release` does the following:
- Builds `pkg/sitemap_generator-X.Y.Z.gem`
- Creates git tag `vX.Y.Z` (skipped if the tag already exists at HEAD)
- Pushes the branch and tag to `origin`

**Note:** `rake release` does **not** push to RubyGems. Step 6 is a separate manual command.

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

1. Yank the bad version: `gem yank sitemap_generator -v X.Y.Z` — this removes it from `gem install` but preserves the download history.
2. Prepare a fix: cut a new patch release (`X.Y.Z+1`) that reverts or corrects the problem.
3. If the bad release introduced a breaking change unintentionally, bump the major version and document the revert in `CHANGES.md`.
