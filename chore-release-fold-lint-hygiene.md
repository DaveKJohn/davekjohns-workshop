### Release/fold/lint hygiene: dead-link coverage + Get-TouchedPlugins + fold/cut-release cleanups (#103) · Chore · 2026-07-21

A batch of release/fold/lint hygiene fixes from issue #103 (Victor's earlier code-review
findings #3-#7, plus a dead-link-scan coverage gap):

- **Dead-link scan coverage.** `check-plugin-integrity.ps1`'s scan now also covers the per-plugin
  `claude-code-plugins/claude-specialists/*/CHANGELOG.md`s, the family
  `claude-code-plugins/claude-specialists/README.md`, and its `QUICKSTART.md` — none of these were
  in the scanned set before. No existing dead links surfaced from the widened scan.
- **`Get-TouchedPlugins` as a pure function (Victor #3).** The inline plugin-detection logic in
  `fold-changelog-entry.ps1` (deriving the `Plugins:` line from the PR's touched files) is now the
  pure, testable `Get-TouchedPlugins -Files <paths>` in `scripts/lib/release-lib.ps1` — same
  connectors-exclusion and lowercase-slug rule, no behavior change. Since `release-lib.ps1` is
  deliberately not mirrored to the plugin (unlike `fold-changelog-entry.ps1` itself), the fold
  script now guards the dot-source with a `Test-Path` check: in the workshop root it's found and
  used; in a consumer repo running the plugin mirror it's simply absent, and the `Plugins:`
  enrichment is skipped — functionally identical there, since
  `claude-code-plugins/claude-specialists/<plugin>/` paths never exist outside this repo anyway.
- **One `gh` call instead of two (Victor #4).** `gh pr list --json` supports the `files` field
  directly (verified against the live `gh` CLI), so the second `gh pr view --json files` call is
  gone; `gh pr list` alone now supplies number, url, and files in one round trip.
- **Sharpened the `Add-PluginChangelogSection` insertion match (Victor #5).** The insertion point
  used to match any `(?m)^## ` heading; it now matches specifically a version heading
  (`## vX.Y.Z ...`, the exact shape `Build-PluginChangelogSection` writes), so a manually added
  non-version `## `-heading in a plugin CHANGELOG can no longer misdirect where the new release
  section is inserted. Verified with a smoke test against a synthetic CHANGELOG carrying a
  `## Notes` heading ahead of the first version heading.
- **LF-vs-`$nl` newline hygiene (Victor #6).** `Build-PluginChangelogSection` and
  `Build-ReleaseNotes` are documented as deliberately LF-pure output (self-contained regenerated
  files, unlike the root `CHANGELOG.md`, which detects and keeps its own CRLF via `$nl`) — but they
  were passing through entry bodies verbatim from that CRLF root `CHANGELOG.md`, which produced
  mixed CRLF/LF line endings in the generated per-plugin `CHANGELOG.md`/`RELEASE.md` files and the
  `releases/development/**` notes (confirmed on disk before this fix). Both functions now normalize
  incoming entry text to LF before assembling, so the documented "pure LF output" promise actually
  holds; `Build-PluginReleaseCard` inherits the fix via `Build-PluginChangelogSection`.
- **Merged the two `$manifests` loops in `cut-release.ps1` (Victor #7).** The per-plugin CHANGELOG
  loop and the RELEASE.md loop shared the same `$pluginEntries` selection (`Get-EntryPlugins` filter
  and `Remove-EntryPluginsLine`) computed twice; merged into a single loop per plugin that computes
  the shared selection once and then does both writes (CHANGELOG only when the plugin has entries
  this release, RELEASE.md unconditionally, matching prior behavior) — same output, better
  readability.

Regenerated the `fold-changelog-entry.ps1` plugin mirror (`build-shared-scripts.ps1`); updated one
outdated assertion in `shared-scripts.tests.ps1` that still expected the now-removed `gh pr view`
call. `check-plugin-integrity.ps1` is green (0 errors) and all `scripts/tests/*.tests.ps1` suites
pass. `Get-TouchedPlugins`, the sharpened `Add-PluginChangelogSection` match, and the LF
normalization are covered by automated tests added to `release-lib.tests.ps1` in this pass.
