### English sweep of the script layer: .ps1 comments and console output to English (#114 item 3) · Chore · 2026-07-21

Translated the Dutch comments/docstrings and Dutch console output (`Write-Host`/`Write-Error`/
`Write-Warning`/`throw` text, summary lines) across the whole script layer to English, per Dave's
repo-wide English-content decision: `scripts/lib`, `scripts/lint`, `scripts/release`,
`scripts/sync`, `scripts/agents`, `scripts/repo-config.ps1`, `scripts/task`, and every
`scripts/tests/*.tests.ps1` suite, plus the two hooks
(`roster-sessioncheck.ps1`/`connector-sessioncheck.ps1`, the latter already English) and the
`specialists-init` bootstrap skill (two leftover Dutch fragments). Test assertions that matched on
now-translated output strings were updated in the same motion so the suites stay green and
verifiable; no test was weakened, only the expected text changed. The five shared-script mirrors
under `claude-code-plugins/claude-specialists/specialists/scripts/` were regenerated via
`build-shared-scripts.ps1` afterward, and `build-agent-defs.ps1 -Check` confirms the shared agent-def
blocks are untouched.

`VUL-IN` is kept as-is everywhere (Dave's explicit decision, technical scaffold marker) -- caught one
regression during the sweep where a first pass had renamed it to "FILL-IN" in a few Write-Error
messages, breaking the literal-marker contract; reverted those to `VUL-IN` and confirmed via the
test suite.

Follow-up (Sylvester, same branch): Dave asked for the generated-content templates in
`scripts/lib/release-lib.ps1` to also go English, since that text ends up in future
`CHANGELOG.md` / release-notes / per-plugin-`CHANGELOG.md` files. Translated: the `catTitle`
category labels (`Feat`/`Docs`/`Chore`/the `Overig` catch-all, now `New features & improvements` /
`Documentation` / `Maintenance (scripts, tooling, config)` / `Other`), the reference line under
`## Releases` ("See [...] for the full release notes"), the `## Releases` genesis intro text
(only ever seen before a repo's first release), the fresh per-plugin-`CHANGELOG.md` intro
paragraph in `Add-PluginChangelogSection`, and the `**Datum:**` label (now `**Date:**`, matching
the `Build-PluginReleaseCard` label it already used). `scripts/tests/release-lib.tests.ps1`'s
fixtures and assertions were updated to the new English expectations (no assertion weakened,
plus one added assertion exercising the genesis-intro fallback path). History remains the
deliberate exception per Dave's decision: `releases/**` and already-folded `CHANGELOG.md`
sections keep whatever language they were written in -- only future generator output changed, so
a mix of Dutch history and English new content is expected and fine.

Two categories of Dutch text were deliberately left untouched, as they are not "script layer"
comments/console output but generated document CONTENT: (1) `releases/**` history plus the
legacy Dutch slot-marker text ('Eigen aan deze repo') that `check-consumer-drift.ps1` and
`bootstrap.ps1`'s templates deliberately still recognize for back-compat with older Dutch consumer
repos; and (2) `cut-release.ps1`'s literal match against `releases/README.md`'s existing Dutch
table header ("Versie | Datum | Type | Titel") -- that header is itself history and the match is
already explicitly documented in that script as a deliberate exception, not touched here.
Bilingual back-compat matchers in `open-pr.ps1` (PR-template checklist strings) and the legacy
`[FOUT]` marker in `connector-sessioncheck.ps1` were left exactly as they were: both languages are
a deliberate feature, not leftover translation debt.

End state: `check-plugin-integrity.ps1` reports 0 errors and all 10 `scripts/tests/*.tests.ps1`
suites pass (`agent-shared`, `bootstrap-drift`, `branch-info`, `connectors`, `new-branch`,
`release-lib`, `repo-config`, `roster-sync`, `shared-scripts`, `sync-roster`).