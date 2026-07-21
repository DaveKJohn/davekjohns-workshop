# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#contributing--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #127 · Release/fold/lint hygiene: dead-link coverage + Get-TouchedPlugins + fold/cut-release cleanups (#103) · Chore · 2026-07-21

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

Plugins: specialists

[PR #127](https://github.com/DaveKJohn/davekjohns-workshop/pull/127)

---

### #126 · Shopify theme work is dev-first (shopify theme dev); a pushed preview theme is the fallback · Feat · 2026-07-21

Shopify theme work is now framed dev-first in the core doctrine: theme work is by default developed
and tested locally via `shopify theme dev`; a pushed preview theme is the fallback, used only when
something demonstrably can't be tested through the dev server (e.g. Shopify Markets/currency-specific
behavior, or a third-party integration that needs the real published storefront). Updated in
[Sandra #21](claude-code-plugins/claude-specialists/specialists-shopify/manuals/05-21-manual.md)
(primary owner of the preview/push flow),
[Steven #22](claude-code-plugins/claude-specialists/specialists-shopify/manuals/05-22-manual.md)
(CLI reference — repositions `shopify theme dev` as the default workflow), and
[Liam #20](claude-code-plugins/claude-specialists/specialists-shopify/manuals/04-20-manual.md)
(the theme builder — builds and tests dev-first, with the preview push as the fallback), so the
doctrine runs consistently across both the build and the push role. The live-theme,
preview-cleanup, and cross-browser hard rules are unchanged; only the default order (dev server
before a preview push) changes. Lands inbound issue #124 (from smartwatchbanden); the issue named
Sandra #21 and Steven #22, and Liam #20 (the builder) was folded in by decision so the doctrine runs
across the build role too.

Plugins: specialists-shopify

[PR #126](https://github.com/DaveKJohn/davekjohns-workshop/pull/126)

---

### #125 · Consolidate the visible-sender header rule: canonical in CLAUDE.md, pointer in Chris lens · Docs · 2026-07-21

The "visible sender" header rule was stated in full in two always-loaded places: `CLAUDE.md` and
Chris's repo lens `01-01-extension.md`. Consolidated to a single canonical statement in `CLAUDE.md`
(it is a repo-specific "hard rule from Dave", not a portable system concept, so it stays here rather
than moving to the portable persona body); the lens bullet becomes a short pointer back to it. The
rule stays fully in force and always loaded — `CLAUDE.md` is loaded automatically every session — so
this removes the verbatim duplication without weakening the rule or extending the agent-shared
generator to lenses. Ravi's analysis also corrected the earlier "threefold" assumption: the persona
body never carried the rule, so it was a twofold duplication.

[PR #125](https://github.com/DaveKJohn/davekjohns-workshop/pull/125)

---

### #123 · Translate the GEGENEREERD, bewerk sentinel marker to English across the agent defs · Docs · 2026-07-21

Translated the last Dutch fragment in the agent-def shared-block sentinel comments to English, in
line with the repo-wide English-content norm: `<!-- BEGIN shared:NAME -- GEGENEREERD, bewerk
agent-shared/NAME.md -->` becomes `<!-- BEGIN shared:NAME -- GENERATED, edit agent-shared/NAME.md
-->`. The marker is literal per-file text (the generator preserves the BEGIN/END sentinel lines
as-is and only fills the body between them), so all 21 agent-defs across the three plugins were
updated directly, plus the one docstring example in `agent-shared-lib.ps1` and the one test
fixture string in `agent-shared.tests.ps1`. No regex in the generator or the lint gate matched the
Dutch text, so nothing there needed changing. Verified: `build-agent-defs.ps1 -Check` (in sync),
`check-plugin-integrity.ps1` (0 errors), and all `scripts/tests/*.tests.ps1` suites green.

Plugins: specialists, specialists-lifehub, specialists-shopify

[PR #123](https://github.com/DaveKJohn/davekjohns-workshop/pull/123)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.14.0] - 2026-07-21 — Minor

Zie [releases/development/1.14/1.14.0.md](releases/development/1.14/1.14.0.md) voor de volledige release-notes.

---

### [v1.13.0] - 2026-07-21 — Minor

Zie [releases/development/1.13/1.13.0.md](releases/development/1.13/1.13.0.md) voor de volledige release-notes.

---

### [v1.12.1] - 2026-07-20 — Patch

Zie [releases/development/1.12/1.12.1.md](releases/development/1.12/1.12.1.md) voor de volledige release-notes.

---

### [v1.12.0] - 2026-07-20 — Minor

Zie [releases/development/1.12/1.12.0.md](releases/development/1.12/1.12.0.md) voor de volledige release-notes.

---

### [v1.11.0] - 2026-07-20 — Minor

Zie [releases/development/1.11/1.11.0.md](releases/development/1.11/1.11.0.md) voor de volledige release-notes.

---

### [v1.10.0] - 2026-07-19 — Minor

Zie [releases/development/1.10/1.10.0.md](releases/development/1.10/1.10.0.md) voor de volledige release-notes.

---

### [v1.9.2] - 2026-07-19 — Patch

Zie [releases/development/1.9/1.9.2.md](releases/development/1.9/1.9.2.md) voor de volledige release-notes.

---

### [v1.9.1] - 2026-07-19 — Patch

Zie [releases/development/1.9/1.9.1.md](releases/development/1.9/1.9.1.md) voor de volledige release-notes.

---

### [v1.9.0] - 2026-07-19 — Minor

Zie [releases/development/1.9/1.9.0.md](releases/development/1.9/1.9.0.md) voor de volledige release-notes.

---

### [v1.8.0] - 2026-07-18 — Minor

Zie [releases/development/1.8/1.8.0.md](releases/development/1.8/1.8.0.md) voor de volledige release-notes.

---

### [v1.7.0] - 2026-07-18 — Minor

Zie [releases/development/1.7/1.7.0.md](releases/development/1.7/1.7.0.md) voor de volledige release-notes.

---

### [v1.6.0] - 2026-07-18 — Minor

Zie [releases/development/1.6/1.6.0.md](releases/development/1.6/1.6.0.md) voor de volledige release-notes.

---

### [v1.5.2] - 2026-07-18 — Patch

Zie [releases/development/1.5/1.5.2.md](releases/development/1.5/1.5.2.md) voor de volledige release-notes.

---

### [v1.5.1] - 2026-07-18 — Patch

Zie [releases/development/1.5/1.5.1.md](releases/development/1.5/1.5.1.md) voor de volledige release-notes.

---

### [v1.5.0] - 2026-07-17 — Minor

Zie [releases/development/1.5/1.5.0.md](releases/development/1.5/1.5.0.md) voor de volledige release-notes.

---

### [v1.4.1] - 2026-07-16 — Patch

Zie [releases/development/1.4/1.4.1.md](releases/development/1.4/1.4.1.md) voor de volledige release-notes.

---

### [v1.4.0] - 2026-07-16 — Minor

Zie [releases/development/1.4/1.4.0.md](releases/development/1.4/1.4.0.md) voor de volledige release-notes.

---

### [v1.3.0] - 2026-07-16 — Minor

Zie [releases/development/1.3/1.3.0.md](releases/development/1.3/1.3.0.md) voor de volledige release-notes.

---

### [v1.2.0] - 2026-07-16 — Minor

Zie [releases/development/1.2/1.2.0.md](releases/development/1.2/1.2.0.md) voor de volledige release-notes.

---

### [v1.1.1] - 2026-07-15 — Patch

Zie [releases/development/1.1/1.1.1.md](releases/development/1.1/1.1.1.md) voor de volledige release-notes.

---

### [v1.1.0] - 2026-07-15 — Minor

Zie [releases/development/1.1/1.1.0.md](releases/development/1.1/1.1.0.md) voor de volledige release-notes.

---

### [v1.0.0] - 2026-07-14 — Major

Zie [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) voor de volledige release-notes.
