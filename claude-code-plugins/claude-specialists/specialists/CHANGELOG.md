# Changelog — specialists

Consumer-facing history of this plugin: per release, the changes that touched this plugin.
Automatically appended by `cut-release.ps1` of the marketplace repo (davekjohns-workshop); the full
workshop history lives there in `CHANGELOG.md` and `releases/`.

## v1.18.0 — 2026-07-22

### Features

#### #146 · Rename-proof lens scaffold (nameless header + propose-only reconcile) · Feat · 2026-07-22

Made a persona rename stop forcing manual header fixes in every consumer (inbound #145).

- **Nameless generated lens header.** Both scaffold generators (`sync-roster.ps1`'s `New-LensScaffold`
  and `specialists-init`'s `bootstrap.ps1`) now write the stable `# <group>-<id> · repo-lens` slug
  instead of baking the persona's first name into the header + intro. The name now lives in exactly
  one place — the agent-def's `name:` frontmatter — so a later rename can never drift a generated
  header again.
- **Propose-only header reconcile.** `check-roster-sync.ps1` detects an existing lens whose header
  still carries a stale scaffold name (`# Sean · repo-lens` after the agent became Sebastian) and
  reports it as a non-blocking `[INFO]` (silent at session start, shown on a deliberate run). The
  `sync-roster` skill parses that and prints the rename-proof, nameless replacement header to paste —
  it never rewrites the lens file, matching its propose-only stance for roster rows. Hand-customized
  headers (no `· repo-lens` tail) are never touched.
- **`Get-DisplayName` centralized** into the shared `check-report-lib.ps1` (was duplicated across
  `sync-roster.ps1` and `bootstrap.ps1`), now the single source for both the roster-row proposal and
  the header-drift comparison.
- Tests extended: nameless-scaffold assertions + stale-header detection/reconcile coverage across
  `roster-sync`, `sync-roster`, and `bootstrap-drift`.

Out of scope (noted): the persona-lens title copy in `bootstrap.ps1` (which snapshots the plugin
persona's canonical heading) still carries a name; the roster table + routing rule in a consumer's
`CLAUDE.md` remain repo-owned governance.

[PR #146](https://github.com/DaveKJohn/davekjohns-workshop/pull/146)

---

## v1.17.0 — 2026-07-22

### Features

#### #143 · New specialists-ecomm plugin with three e-commerce specialists (SEO, CRO, SEA) · Feat · 2026-07-22

New fourth domain group — the plugin `specialists-ecomm`, for commercial webshop repos of any
platform (not Shopify-only) — with its first three specialists, all group 06 (the
measure-and-optimize family):

- **Sergio 📈 #26 — SEO Specialist.** Technical/on-site SEO: anchor links and internal linking,
  canonical tags, structured data (schema.org/JSON-LD), XML sitemaps, and pagespeed. Auditor and
  builder: measure first, fix at the source, validate, white-hat only.
- **Craig 🎯 #27 — CRO Specialist.** Conversion Rate Optimization: funnel/drop-off analysis, A/B
  experiments, checkout and landing-page optimization. Test, don't guess — keep only what a measured
  experiment proves.
- **Sean 💸 #28 — Performance / SEA Specialist.** The paid side of acquisition and its in-repo
  footprint: conversion tracking, product feeds, UTM conventions, ad-to-landing-page alignment.
  Honest about the boundary that live campaigns live in the ad platforms, and coordinates with
  Sergio so paid doesn't cannibalize organic.

All three carry the standard shared blocks (inbound-behaviour, laziness-automation,
language-behavior), defer visual/front-end changes to the design owner, and defer any preview/live
push to the platform's store owner.

**Rename to free the name for the SEA pun:** the existing Security Engineer **Sean 🛡️ #23** is
renamed to **Sebastian** (keeps 🛡️, #23, and its call name changes `@specialists:sean` →
`@specialists:sebastian`), so the new SEA specialist can be "Sean". Updated across the living
team-definition surfaces — the #23 agent def, manual, and repo lens; the roster in `CLAUDE.md`; the
family handbook; Chris's routing/chains lens; and the cross-references in the Ravi/Victor/Edith
lenses; plus the group-1 listing in `README.md`. History (CHANGELOG/releases, the dated security
baseline) and past-advice attribution comments in scripts/hooks/tests/CI are deliberately left as
records.

- **New plugin:** `claude-code-plugins/claude-specialists/specialists-ecomm/` with `plugin.json`
  (version 1.16.0, lockstep), `CHANGELOG.md`, and `RELEASE.md` card; registered as the fourth entry
  in `.claude-plugin/marketplace.json`.
- **Specialists:** agent defs `agents/06-26|27|28-agent.md` and portable manuals
  `manuals/06-26|27|28-manual.md`.
- Group deliberately set up to grow further (lifecycle/email, analytics) without restructuring.

**Quality-round follow-ups (Victor/Edith/Sebastian/Ravi/Nolan on the diff):**
- Registered the new plugin in the docs that describe the family — root `README.md`, the family
  `README.md`, and `QUICKSTART.md` now say "four plugins" and list `specialists-ecomm`; reframed
  "a repo needs at most one domain group" as **complementary** (a Shopify repo can enable
  `specialists-shopify` + `specialists-ecomm`).
- Fixed a real functional gap: `check-consumer-drift.ps1` hardcoded three plugins, so a consumer's
  drift check would never cover ids 26/27/28 — added `specialists-ecomm`.
- Language norm: translated the three pre-existing Dutch manifests (`marketplace.json` + the
  `specialists`/`lifehub`/`shopify` `plugin.json`) to English, closing the mixed-language state
  instead of extending it; generalized stale "three plugins" wording in scripts and lenses.
- Ravi: promoted three verbatim-shared boundaries across the ecomm agent-defs to `agent-shared/`
  blocks (`design-owner-boundary`, `changelog-entry-boundary`, `storefront-preview-boundary`),
  scoped to Sergio/Craig/Sean.

Verified: `build-agent-defs.ps1 -Check` (shared blocks in sync), `check-plugin-integrity.ps1`
(0 errors), and all test suites green.

[PR #143](https://github.com/DaveKJohn/davekjohns-workshop/pull/143)

---

## v1.15.1 — 2026-07-22

### #131 · shared Invoke-NativeCapture helper (#114 item 1) · Chore · 2026-07-22

Centralized the native-command stderr-capture pattern (#114 item 1) into a new shared helper
`scripts/lib/native-capture-lib.ps1` (`Invoke-NativeCapture`), so the #96/#97/#107 lesson --
run under `ErrorActionPreference = 'Continue'`, capture output, then judge on `$LASTEXITCODE`
instead of on stderr -- lives in exactly one tested place. The helper takes `-FilePath`/`-Arguments`
(not a scriptblock, so the EAP override actually reaches the command) and returns `Output` +
`ExitCode`; `-DiscardStderr` keeps stderr out of machine-readable output. `open-pr.ps1` (git push +
`gh pr create`) and `fold-changelog-entry.ps1` (`gh pr list`) now call the helper instead of each
repeating the save/restore dance. Registered as a mirrored shared script and dot-sourced
`$PSScriptRoot`-relative, matching the `check-report-lib.ps1` precedent. Regression guards in
`shared-scripts.tests.ps1` were re-pointed from the old inline patterns to the centralized helper,
plus a new behavioral test of `Invoke-NativeCapture` (throws-nothing on native stderr under caller
EAP=Stop, real exit code, EAP restored, `-DiscardStderr`).

[PR #131](https://github.com/DaveKJohn/davekjohns-workshop/pull/131)

---

## v1.15.0 — 2026-07-21

### #130 · open-pr/fold consumer-fit: configurable PR markers, optional assignee/milestone, fold -RepoRoot (#101) · Feat · 2026-07-21

Three consumer-fit gaps in the shared `open-pr.ps1` / `fold-changelog-entry.ps1` scripts,
surfaced by smartwatchbanden (inbound #101). All three are backward-compatible: a repo whose
`scripts/repo-config.ps1` does not define the new optional functions, and every existing
`fold-changelog-entry.ps1` call site, keep today's exact behavior.

1. **PR auto-fill markers are now configurable.** `open-pr.ps1` matched its description
   placeholder and its "Requested by Dave" approval checkbox against this repo's own
   (bilingual) template text. Two optional repo-config functions,
   `Get-PrDescriptionPlaceholder` and `Get-PrApprovalPattern`, let a consumer point at its own
   template markers; when absent (guarded via `Get-Command ... -ErrorAction SilentlyContinue`),
   the script falls back to this repo's current markers unchanged.
2. **Optional PR assignee/milestone.** Two more optional repo-config functions,
   `Get-PrAssignee` and `Get-PrMilestone`, are passed to `gh pr create` as `--assignee` /
   `--milestone` only when they return a non-empty value; not defined (or empty) means the
   flags are simply omitted, exactly as before. This repo defines neither.
3. **`fold-changelog-entry.ps1` gained an explicit `-RepoRoot` parameter.** Default (omitted):
   unchanged dual-context resolution (`CLAUDE_PROJECT_DIR`, else the git root). When supplied,
   it wins outright -- letting a consumer that runs the fold from a temporary/detached worktree
   (e.g. smartwatchbanden's `ship-pr.ps1`) write to that tree directly, without the
   env-var workaround.

`open-pr.ps1` and `fold-changelog-entry.ps1` are the mirrored shared scripts (source of truth
here, regenerated into the plugin mirror via `build-shared-scripts.ps1`); `scripts/repo-config.ps1`
is this repo's own file and is unchanged (the workshop keeps the built-in defaults on all four
functions).

[PR #130](https://github.com/DaveKJohn/davekjohns-workshop/pull/130)

---

### #129 · Quiet-moment backlog #114: shared check-report helpers + two-plugin roster-sync test (native-capture assessed, not extracted) · Chore · 2026-07-21

Two dedup points from the quiet-moment backlog (#114), each assessed for the mirror/consumer
boundary first (the #103 lesson: a shared lib must be present in EVERY context that dot-sources
it, not just the workshop).

**Point 1 -- the `Invoke-NativeCapture` pattern (save `$ErrorActionPreference` -> `Continue` ->
native call -> capture output + `$LASTEXITCODE` -> restore, the #107 stderr guard): NOT extracted
to a shared lib -- reported as a mirror-boundary constraint instead of a half measure.** All five
occurrences of the exact pattern live inside three whole-file-mirrored, consumer-run scripts
(`open-pr.ps1` x2 -- push + `gh pr create`, `new-branch.ps1` x2 -- the exists-check + the checkout,
`fold-changelog-entry.ps1` x1 -- `gh pr list`); `cut-release.ps1` (workshop-only) uses a simpler,
different shape (a single `EAP=Continue` for its tail block, no per-call capture/restore) and was
left as is. A cross-file shared lib for these three would need a NEW consumer-scaffolded file
(like `repo-config.ps1`/`branch-info.ps1`), since none of the three currently dot-source a common
lib the helper could ride along on -- that means extending `specialists-init/bootstrap.ps1` and
every already-bootstrapped consumer, real infra scope beyond a same-branch pure refactor. Not
implemented; flagged here for a deliberate follow-up decision instead.

**Point 2 -- a new `scripts/lib/check-report-lib.ps1`: extracted cleanly, no consumer-bootstrap
changes needed.** Unlike `repo-config.ps1`/`branch-info.ps1` (repo-owned, per-consumer-repo-root
files), this lib is not repo-specific, so it can be dot-sourced relative to `$PSScriptRoot` --
which means it ships as part of the SAME plugin/mirror payload as its callers and needs no
consumer scaffold. Registered as a new pair in `scripts/lib/shared-scripts-lib.ps1` (mirrored to
`claude-code-plugins/claude-specialists/specialists/scripts/lib/check-report-lib.ps1` via
`build-shared-scripts.ps1`, exactly like the five whole-script pairs). Extracted: `Write-Ok` /
`Write-Info` / `Write-Fout` (counting variant) / `Write-CheckSummary` (the "Summary: N error(s), N
info signal(s)." line + exit code), `Test-PluginNameSlug` / `Test-PluginMarketplaceSlug` (the
slug-guard regexes), and `Resolve-PluginDir` (the versioned-plugin-cache-dir resolver, honoring
`$env:CLAUDE_PLUGIN_ROOT`, `[version]`-sorted).

Consumers, per their actual mirror/consumer status:
- `scripts/sync/check-connectors.ps1` (workshop-only -- reads the `connectors/` register that only
  exists here): dot-sources unconditionally; kept its own `Write-Skip` and `Get-PluginDir`
  (family-plugin-folder lookup -- a genuinely different function from `Resolve-PluginDir`'s
  cache/version resolution, despite the similar name, so NOT merged).
- `scripts/sync/check-roster-sync.ps1` (whole-file mirror): dot-sources via `$PSScriptRoot`
  (not `$repoRoot` -- this lib is not repo-owned), safe because both files travel in the same
  registered mirror-pair set (drift-lint guarded).
- `claude-code-plugins/claude-specialists/specialists/skills/sync-roster/sync-roster.ps1`
  (plugin-native, never had a root copy): dot-sources the mirrored lib two levels up
  (`..\..\scripts\lib\...`), same reasoning as its existing `Resolve-CheckScript` sibling-path
  logic. Kept its OWN non-counting `Write-Info`/`Write-Fout` (it tracks
  created/kept/proposed and always exits 0 -- a deliberately different shape from the
  error/info-signal counters, so not merged; the later local redefinition intentionally shadows
  the lib's counting versions in the same scope).

Verified: dot-sourcing runs in the caller's own scope, so a shared `Write-Fout`/`Write-Info`
correctly bumps the CALLER's own `$script:errors`/`$script:infos` -- confirmed with a small
throwaway repro before relying on it.

`build-agent-defs.ps1 -Check`, `build-shared-scripts.ps1` (regenerated the two touched mirrors,
then `-Check` green), and `check-plugin-integrity.ps1` all report 0 findings. Adjusted one coupled
assertion in `scripts/tests/shared-scripts.tests.ps1` ("every mirrored source resolves the repo
root via `CLAUDE_PROJECT_DIR`"): `check-report-lib.ps1` is a dot-sourced lib, not a standalone
dual-context entry point, so it is excluded from that specific invariant (still covered by the
existence/in-sync checks). All `scripts/tests/*.tests.ps1` suites pass (behavior identical --
integration tests assert on stdout/exit-code, not on internal function boundaries).

**Follow-up on this same branch -- `Write-Fout` renamed to `Write-Failure`.** After the English
sweep of this repo's content (docs/lens-language-english, #115), `Write-Fout` was the one
remaining Dutch function name -- introduced in the new `check-report-lib.ps1` above specifically to
avoid a name clash with the built-in `Write-Error` cmdlet. Renamed (definition + all call sites) to
`Write-Failure` in `scripts/lib/check-report-lib.ps1`, `scripts/sync/check-connectors.ps1`,
`scripts/sync/check-roster-sync.ps1`, and the plugin-native
`claude-code-plugins/claude-specialists/specialists/skills/sync-roster/sync-roster.ps1` (incl. its
own non-counting shadow definition, kept for the same reasons as before). The mirrors
(`check-report-lib.ps1`, `check-roster-sync.ps1`) were regenerated via `build-shared-scripts.ps1`.
Only the PowerShell identifier changed -- the printed `[ERROR]` marker and message text are
untouched, so hook/test matchers on the output stay intact. `build-shared-scripts.ps1 -Check`,
`check-plugin-integrity.ps1` (0 errors), and all `scripts/tests/*.tests.ps1` suites are green.

**Point 4 -- the two-plugin roster-sync test gap: closed on this branch.** `scripts/tests/roster-sync.tests.ps1` gains scenario 12 ("Cross-plugin orphan aggregation", 7 asserts): two enabled plugins each with their own orphan, asserting the aggregation reports both (not just the first) and that neither plugin's backing ids are lost across the per-plugin passes. No bug found in `check-roster-sync.ps1` -- the accumulation was already correct, now it is actually exercised rather than only documented as a gap.

(Point 3 of #114 -- the English sweep of the script layer -- landed separately in #128; only points 1, 2, and 4 are in scope here.)

[PR #129](https://github.com/DaveKJohn/davekjohns-workshop/pull/129)

---

### #128 · English sweep of the script layer: .ps1 comments and console output to English (#114 item 3) · Chore · 2026-07-21

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

[PR #128](https://github.com/DaveKJohn/davekjohns-workshop/pull/128)

---

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

[PR #127](https://github.com/DaveKJohn/davekjohns-workshop/pull/127)

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

[PR #123](https://github.com/DaveKJohn/davekjohns-workshop/pull/123)

---

## v1.14.0 — 2026-07-21

### #121 · Make the automation-first (lazy) rule a plugin-owned shared block, like inbound-behaviour · Feat · 2026-07-21

The automation-first ("stay lazy") behavioral rule is now plugin-owned via a new shared block,
`claude-code-plugins/claude-specialists/agent-shared/laziness-automation.md`, wired into the
subagent agent-defs via `<!-- BEGIN/END shared:... -->` sentinels — the same circle as
`shared:inbound-behaviour` — so the rule travels along to consuming repos instead of living only
in this repo's own `CLAUDE.md`. The per-specialist "X is lazy" examples in the manuals stay in
place as elaboration; `CLAUDE.md`'s own "Shared trait — all of them incredibly lazy" paragraph
remains as the governance narrative for the main loop (Chris and the main-loop personas, who carry
no agent-shared blocks), with a light note added that it is the same rule carried by every
specialist's shared playbook, not a second canonical copy.

[PR #121](https://github.com/DaveKJohn/davekjohns-workshop/pull/121)

---

### #120 · Cross-browser compatibility as a standard rule for the browser-facing builders · Feat · 2026-07-21

New shared behavioral rule for the browser-facing builders: what they build must work in all major
browsers (Chrome, Firefox, Safari, Edge), not only the one they happened to preview in. Landed as a
new canonical source block, `claude-code-plugins/claude-specialists/agent-shared/browser-compatibility.md`,
carried into the agent defs of the four specialists who share it — Gwen #12 (Front-End Designer),
Liam #20 (Liquid Developer), Cody #13 (App Developer), Vera #11 (Data Analyst) — via the existing
`agent-shared/` sentinel mechanism, plus a matching prose paragraph in each of their portable
manuals (`04-12-manual.md`, `specialists-shopify/manuals/04-20-manual.md`, `04-13-manual.md`,
`04-11-manual.md`) describing the cross-browser check in that specialist's own context.

[PR #120](https://github.com/DaveKJohn/davekjohns-workshop/pull/120)

---

## v1.13.0 — 2026-07-21

### #119 · Ship a per-plugin RELEASE.md card so consumers see which release they are on · Feat · 2026-07-21

Every plugin now carries a `RELEASE.md` card (version, one-line summary, and the entries for that
version) right next to its `CHANGELOG.md`. Chosen approach: **Model A, plugin-authored** — the card
lives inside the plugin folder and travels with the plugin cache via `claude plugin update`, so a
consumer can see exactly which release they're on without cross-referencing the workshop's own
`releases/` history. `cut-release.ps1` (re)generates the card for every plugin, in lockstep, on
every release; the lint gate's new check 9 guards that the card is present and its `vX.Y.Z` matches
that plugin's `plugin.json`. Deliberately **no SessionStart hook** announces this — the card is
discovered by opening the file in the plugin cache. Seeded on v1.12.1.

[PR #119](https://github.com/DaveKJohn/davekjohns-workshop/pull/119)

---

### #118 · new-branch.ps1: branch creation immediately scaffolds its changelog entry · Feat · 2026-07-21

Branch creation now brings its changelog entry into being in the same move — a branch is never entry-less. Added a shared, Derek-bound `scripts/task/new-branch.ps1` that validates the branch name via `branch-info.ps1` (new additive `Test-BranchName` helper), creates the branch (idempotent `git -C` checkout/checkout -b, no `Set-Location`), and immediately scaffolds the changelog entry by calling `new-changelog-entry.ps1` as a child process. Promoted `new-changelog-entry.ps1` to a dual-context, mirrored shared script (resolves its repo root via `CLAUDE_PROJECT_DIR`, dot-sources `branch-info.ps1` from the repo root, with a #86 pre-flight); registered both scripts in `shared-scripts-lib.ps1` and generated their plugin mirrors. Added the `/specialists:new-branch` skill, and updated Derek's persona + the workflow docs (Derek/Rendall/Tessa lenses, plugin scripts README, root README) so "a branch creates its entry at creation time" is the rule and the separate later step is gone. Consumer seam: the shared script does only git + entry (no push/PR, idempotent), so a consumer like smartwatchbanden can call it first and layer its own step (e.g. a Shopify preview theme) on top. Tests: new `new-branch.tests.ps1` plus extended `shared-scripts` and `branch-info` suites; lint and all suites green.

[PR #118](https://github.com/DaveKJohn/davekjohns-workshop/pull/118)

---

### #117 · English names for agent-shared blocks + script-comment translations · Docs · 2026-07-21

Completed the in-progress English-norm cleanup of the agent-shared machinery. Renamed the four verbatim-shared source blocks to English file names (`grens-inbound` → `inbound-behaviour`, `gedrag-taalkeuze` → `language-behavior`, `grens-webcontent` → `webcontent-boundary`, `grens-artifact-publish` → `artifact-publishing-boundary`) and pulled the whole chain along: the `shared:<name>` sentinels in all 21 agent defs across the three plugins, the generator-lib docstring, and the current-doc references in `README.md` and Ravi's lens. Also folded in the NL→EN comment translation of `connector-sessioncheck.ps1` and `bootstrap.ps1`. Functional/canonical markers deliberately keep their original form per the language convention's technical-identifier exception — the `VUL-IN` scaffold sentinel and a couple of marker phrases the drift tests key on stay as-is. History (`CHANGELOG.md` files, `releases/`) is left untouched. Generator, lint (0 errors), and all test suites are green.

[PR #117](https://github.com/DaveKJohn/davekjohns-workshop/pull/117)

---

### #116 · Add Nolan #25, the Performance Engineer (token/context frugality) · Feat · 2026-07-21

Added a new portable specialist to the Claude Specialists: **Nolan ⚡ #25 — Performance Engineer** (`@specialists:nolan`, stable id `06-25`, group 06). Nolan is a measure-and-advise role for token/context frugality: he measures what each session, agent def, manual, and loading chain costs, and proposes where it can come down without losing function. He reports findings and does not commit, edit, or open PRs himself — execution runs through Ravi #24 (DRY dedup), Sylvester #15 (harness/config), and Tessa #16 (doc-text rewrite). New portable manual (`manuals/06-25-manual.md`) and agent def (`agents/06-25-agent.md`) on the plugin side, a davekjohns-workshop repo lens (`06-25-extension.md`), and roster/routing updates in `CLAUDE.md`, Chris's lens, and the Specialists handbook.

[PR #116](https://github.com/DaveKJohn/davekjohns-workshop/pull/116)

---

### #115 · English repo content becomes a system-wide norm (incl. consumer lenses) · Docs · 2026-07-20

Promotes the "repo content is English" rule from the workshop-only `### Language` slot in
`CLAUDE.md` to a portable, synced norm in Tessa #16's manual body ("Guarding the language
convention"), so every consuming repo inherits it — including that a consumer's own repo lens
(`## Specific to this repo`) is written in English, while the session-reply language stays free and
follows the user. The workshop `CLAUDE.md` slot now defers to that norm and keeps only this repo's
own application of it. Consumers pick up the norm after the next release + `claude plugin update`;
translating their existing lenses stays each consumer's own session job.

[PR #115](https://github.com/DaveKJohn/davekjohns-workshop/pull/115)

---

## v1.12.1 — 2026-07-20

### #113 · Sweep: the git/gh stderr-under-Stop pitfall across the release scripts · Fix · 2026-07-20

Cutting v1.12.0 exposed that the #107 fix (open-pr's push) only patched one spot: the same
`$ErrorActionPreference = 'Stop'` + native-stderr-as-terminating-error pitfall lived on in the other
release scripts. `cut-release.ps1` died on `git add -A` (the autocrlf LF↔CRLF warning goes to
stderr), before its `$LASTEXITCODE` check — the release had to be finished by hand. This sweeps the
whole class.

- **`cut-release.ps1`:** the commit/tag/push block now runs under `EAP=Continue` (with a `git add`
  exit-code check that was missing), so git's chatter can't abort the release before the checks.
- **`fold-changelog-entry.ps1`** (+ mirror): the two `gh pr list`/`gh pr view --json` calls run under
  `EAP=Continue` with `2>$null`, so a `gh` notice can't terminate the fold before its graceful
  `$LASTEXITCODE` handling (and can't pollute the captured JSON). On a non-zero `gh` exit it now
  prints a one-line notice that the PR-number / Plugins-line enrichment was skipped (restoring the
  operator-visibility the raw stderr used to give — review point Victor/Sean).
- **`open-pr.ps1`** (+ mirror): the `gh pr create` call gets the same `EAP=Continue` + capture guard
  the push already had (#107).
- **Query commands left as-is:** `git rev-parse`/`git status`/`git tag --list` write results to
  stdout and only real errors to stderr, so `Stop` is correct there — deliberately not wrapped.
- **Tests:** `shared-scripts.tests.ps1` gains static regression guards that cut-release runs its
  git-mutation block under `Continue`, fold discards `gh` stderr, and open-pr guards `gh pr create`.
- **`05-15-extension.md`** (Sylvester's lens): the #107 lesson now names `git add` and the query-vs-
  mutation distinction, and records the sweep.

The live release/push/gh paths against a real remote stay an honest test-gap (not unit-testable
without a remote); the guards assert the safe shape.

[PR #113](https://github.com/DaveKJohn/davekjohns-workshop/pull/113)

---

## v1.12.0 — 2026-07-20

### #112 · Roster-sync recovery skill (layer 3, feature complete) · Feat · 2026-07-20

The final layer of the roster-sync feature: after the SessionStart hook (layer 2, #111) flags a
specialist missing from a consumer's roster, the `sync-roster` skill stages the catch-up — without
ever writing to `CLAUDE.md`, committing, or touching main. With this, the feature is complete:
detection (#110) → signaling (#111) → recovery.

- **`skills/sync-roster/sync-roster.ps1` (new):** delegates drift detection to
  `check-roster-sync.ps1` (it does not re-decide drift), then for each flagged agent creates the
  missing lens scaffold (`## Specific to this repo (VUL-IN)`, the same structure `specialists-init`
  writes — frontmatter, lens-only intro, the VUL-IN slot; additive, never overwriting) and prints a
  proposed roster row built from the agent's frontmatter
  (name + description, best-effort matched to the roster's table-or-list style). It prints a summary
  with an explicit "main is sacred — review and branch this yourself" reminder. The roster file is
  never modified.
- **`skills/sync-roster/SKILL.md` (new):** when to run it (after the hook flags drift), what it
  stages, and the human follow-up — mirroring the `open-pr`/`specialists-init` skill tone.
- **`roster-sessioncheck.ps1`:** the drift hint now points at the `sync-roster` skill (the forward
  reference deliberately held back in layer 2 until the skill existed).
- **`QUICKSTART.md`:** a "new specialist" note in *Staying up to date* points consumers at the hook
  + skill.
- **Tests:** `sync-roster.tests.ps1` (22 asserts) covers scaffold creation, the never-overwrite
  guard, a proposed row printed for a missing-roster agent, and that the roster file's bytes are
  never changed.

Version gate as usual: consumers get the skill after a release bump + `claude plugin update`.

[PR #112](https://github.com/DaveKJohn/davekjohns-workshop/pull/112)

---

### #111 · Roster-sync SessionStart hook (layer 2 of the feature) · Feat · 2026-07-20

Layer 2 of the roster-sync feature: the detection from layer 1 (#110) now surfaces itself at
session start, so a specialist missing from a consumer's roster is visible right after a plugin
update instead of only when someone happens to run the check.

- **`hooks/roster-sessioncheck.ps1` (new):** a SessionStart hook that runs the mirrored
  `check-roster-sync.ps1` against the current repo and, like `connector-sessioncheck.ps1`, is
  deliberately soft — it surfaces only blocking `[ERROR]` signals (a missing specialist) as a
  compact summary, keeps `[INFO]` (orphans, ignore-list skips, uncached plugins) silent, and always
  exits 0 (a session start never strands here). Read-only.
- **`hooks/hooks.json`:** a second command is added to the existing `SessionStart` (startup) entry,
  so the new hook runs alongside the connector check.
- **`connectors/README.md`:** the named-exception note now covers this second hook.
- **Tests:** `roster-sync.tests.ps1` gains hook cases (missing check script → skipped; an `[ERROR]`
  stub → drift summary + exit 0, never blocking; an `[INFO]`/`[OK]`-only stub → silent in-sync
  message).

Version gate as usual: consumers receive the hook only after a release bump + `claude plugin
update` + session restart. Layer 3 (the semi-automatic `sync-roster` recovery skill) and the full
feature docs follow.

[PR #111](https://github.com/DaveKJohn/davekjohns-workshop/pull/111)

---

### #110 · Roster-sync detection (layer 1 of the feature) · Feat · 2026-07-20

When a plugin release adds a new specialist (e.g. Ravi 06-24), a consumer that updates the plugin
gets no signal that its roster (the specialists table in CLAUDE.md) and its repo lenses now lag
behind — the Ravi and Sean cases were both caught by chance. This is layer 1 of the fix: **detection**.
The SessionStart signaling (layer 2) and the semi-automatic recovery skill (layer 3) follow; full
user-facing docs land with layer 3 when the feature is complete.

- **`scripts/sync/check-roster-sync.ps1` (new, shared):** run from a consumer root, it resolves the
  enabled plugins' agents from the highest-version cache dir, then flags per agent: no roster row
  (`[ERROR]`), no repo-lens (`[ERROR]`), and roster/lens ids with no backing agent or persona
  (`[INFO]` orphan). Same `[OK]/[INFO]/[ERROR]` + exit-code convention and path guardrails as
  `check-connectors.ps1`. Mirrored to the plugin via the shared-scripts pipeline (byte-identical,
  drift-linted).
- **`repo-config.ps1`:** `Get-RosterPath` (default `CLAUDE.md`) tells the check where the roster
  lives; `Get-RosterIgnoredIds` lists agents that are enabled but deliberately have no roster
  row/lens (here: Paula 02-09, Vera 04-11, Gwen 04-12, Cody 04-13 — a documented choice), so the
  workshop's own run is clean. A fresh consumer leaves the ignore-list empty.
- **Tests:** `roster-sync.tests.ps1` (28 asserts, fixture-driven) covers the happy path, a new agent
  missing from the roster, a missing lens, orphans, disabled/uncached plugins, highest-version
  resolution, persona-backing, the `Get-RosterPath` override, the legacy lens path, and the
  ignore-list. `repo-config.tests.ps1` gained asserts for the two new getters.

Layer 1 is not yet wired into any gate — it is a standalone check a consumer can run; the hook
(layer 2) will surface it at session start.

[PR #110](https://github.com/DaveKJohn/davekjohns-workshop/pull/110)

---

### #109 · Shared block for the language directive (Ravi) · Feat · 2026-07-20

Phase B left the closing "respond in the user's language" line verbatim-identical in 19 of the 20
agent defs. Ravi's duplication check recommended promoting it to a single source via the existing
`agent-shared/` mechanism — no new machinery needed, since the generator is line-based.

- **New source `agent-shared/gedrag-taalkeuze.md`** with the canonical line; the 19 identical agent
  defs now carry it between `<!-- BEGIN/END shared:gedrag-taalkeuze -->` sentinels, filled and
  verified by `build-agent-defs.ps1` like the `grens-*` blocks.
- **03-07 (Rebecca) stays local:** its line has a deliberate source-quoting nuance ("...quoting
  sources in another language is fine") — a near-duplicate that Ravi's own rule says not to force-merge.
- **Ravi's lens (06-24)** scope updated: the shared-block circle now names a third category
  (standalone behavior directives outside Boundaries/Working method) and lists `gedrag-taalkeuze`.

Naming note: the new source keeps the Dutch-style name of its `grens-*` siblings for uniformity;
renaming the whole `agent-shared/` set to English is a later-phase consistency item.

[PR #109](https://github.com/DaveKJohn/davekjohns-workshop/pull/109)

---

### #108 · Workshop to English — phase C: machine markers, bilingual · Feat · 2026-07-20

The final English-switch phase: the machine-coupled Dutch markers and the consumer-facing output of
the connector tooling are now English, with **bilingual back-compat** so consumers still carrying
the Dutch markers keep working across a plugin-version skew.

- **Slot marker `## Eigen aan deze repo` → `## Specific to this repo`.** `bootstrap.ps1` now writes
  the English scaffold heading; `check-consumer-drift.ps1` splits the portable body on **either**
  language (a legacy Dutch consumer still splits correctly). Docs (root README, connectors README,
  `specialists-init` skill, Chris's lens) follow the English canonical name.
- **Signal token `[FOUT]` → `[ERROR]`.** `check-connectors.ps1` emits `[ERROR]`; the SessionStart
  hook's blocking-signal filter recognizes **both** `[FOUT]` and `[ERROR]` (the plugin cache and the
  workshop checkout can be on different versions).
- **Consumer-facing output is English.** The connector check/drift-check messages and the hook's own
  session-start lines (`no errors`, `signals found …`) — surfaced into every consumer session — are
  translated.
- **PR template → English, `open-pr.ps1` matches both languages.** The three auto-fill strings are
  English in the template; the script still recognizes the Dutch strings so a consumer whose template
  is still Dutch keeps its auto-fill.
- **Tests:** bilingual back-compat is proven — the drift split is tested with both the legacy Dutch
  and the new English slot fixture; the hook test surfaces both a `[FOUT]` and an `[ERROR]` line.
  All seven suites green.

**Deferred to a later phase (D):** the purely internal, non-consumer-facing Dutch code-comments in
the scripts (and old research docs under `research/`). They ship in no consumer-visible surface, so
they carry no urgency; the English switch of everything consumer-facing is complete with this phase.

[PR #108](https://github.com/DaveKJohn/davekjohns-workshop/pull/108)

---

### #107 · open-pr.ps1 survives git push's stderr chatter · Fix · 2026-07-20

`open-pr.ps1` died on the `git push` step: git writes its `remote:` progress to stderr, and under
`$ErrorActionPreference = 'Stop'` PowerShell 5.1 promotes that stderr to a *terminating*
NativeCommandError — aborting the script before the `$LASTEXITCODE` check, even though git itself
exited 0. This surfaced when opening the phase-B PR (#106): the push succeeded but the script
stopped before creating the PR, so the PR had to be opened by hand.

- **`scripts/release/open-pr.ps1`** (+ its plugin mirror via `build-shared-scripts.ps1`): the push
  now runs with `$ErrorActionPreference = 'Continue'`, captures `2>&1`, records `$LASTEXITCODE`,
  restores the preference, and only then judges — the same shape as the #96 fix.
- **`scripts/tests/shared-scripts.tests.ps1`**: a guard proving the mechanism (naive stderr-under-Stop
  is terminating; the capture pattern is not and reads the real exit code) plus a regression guard
  that `open-pr.ps1` keeps the safe push form. The live push against a real remote stays an honest
  test-gap (no remote in the unit suite).
- **`05-15-extension.md`** (Sylvester's lens): the lesson secured next to the #97 `$LASTEXITCODE`
  note — stderr-as-failure under `Stop` is the sibling pitfall.

[PR #107](https://github.com/DaveKJohn/davekjohns-workshop/pull/107)

---

### #106 · Workshop switched to English — phase B: plugin content · Feat · 2026-07-20

Follow-up to phase A (#105): the shipped plugin content itself is now English, so consumers
worldwide read an English team. Covers all three plugins.

- **Translated:** the 20 agent definitions (prose outside the shared sentinel blocks), all 26
  manuals/playbooks, the 4 personas, `agent-shared/` (the canonical shared-bullet source), the
  three core skills + the shopify `start-task` skill, `specialists/scripts/README.md`, and the
  intro paragraphs of the three plugin `CHANGELOG.md` files (release history left as written).
- **Shared blocks regenerated:** `build-agent-defs.ps1` refilled every `<!-- BEGIN/END shared -->`
  region from the translated `agent-shared/`, so the sentinel content is English and byte-in-sync
  in all 20 agent defs.
- **Language directive aligned with the approved policy:** each agent def ended with a hard
  "work in Dutch" instruction. That contradicts the phase-A Language policy (specialists reply in
  the language the user writes in) and the worldwide-sharing goal, so all 20 now read "Respond in
  the language the user addresses you in." This is a behavior change beyond pure translation —
  flagged for review.
- **Slot-heading canon:** the human-readable `## Specific to this repo` section heading is now
  used consistently across manuals, lenses, and CLAUDE.md.

**Deliberately deferred to a later phase (scripts):** the machine-coupled Dutch marker
`## Eigen aan deze repo` still lives in `bootstrap.ps1` (the scaffold it writes),
`check-consumer-drift.ps1` (`Get-PortableBody` splits on it) and its test fixture; likewise the
`[FOUT]`/`[DRIFTED]` signal tokens, the `VUL-IN` scaffold marker, and the three Dutch PR-template
strings `open-pr.ps1` matches. Migrating those to English needs bilingual back-compat for
consumers that still carry the Dutch slot — a dedicated scripts phase. Lint and all seven test
suites pass.

[PR #106](https://github.com/DaveKJohn/davekjohns-workshop/pull/106)

---

## v1.11.0 — 2026-07-20

### #99 · Sessiestart-hook meldt alleen nog blokkerende signalen — INFO blijft stil · Feat · 2026-07-20

De SessionStart-hook toonde bij elke sessiestart óók de `[INFO]`-signalen uit de connectors-check:
registeradministratie over de sync-stand van consumenten (manifest achter op de bronversie, een
niet-geregistreerde extension). Die stand leeft vaak op een andere machine of bij een andere
gebruiker, en ook waar hij hier bij te werken is, is het administratie op eigen tempo — geen
sessiestart-werk. Het schaalt bovendien niet naarmate meer repo's de plugin installeren (wens
Dave).

- **`connector-sessioncheck.ps1`**: het signaalfilter is beperkt tot `[FOUT]`/`[DRIFTED]` — alleen
  wat hier en nu oplosbaar is bereikt de sessie-context. De OK-melding is daarop aangepast
  ("geen fouten"). `[INFO]` blijft volledig zichtbaar bij een bewuste run van
  `scripts/sync/check-connectors.ps1` in de workshop; aan de check zelf verandert niets.
- **`connectors.tests.ps1`**: nieuwe stub-case borgt dat INFO-regels nooit als sessie-alert
  doorlekken; de bestaande schone-stub-case volgt de nieuwe OK-melding.
- **`connectors/README.md`**: de sessie-check-doctrine beschrijft de FOUT/INFO-scheiding.

Let op de versie-poort: consumenten (en de workshop zelf, die zichzelf consumeert) draaien de
nieuwe hook pas na een release-bump + `claude plugin update` + sessie-herstart.

[PR #99](https://github.com/DaveKJohn/davekjohns-workshop/pull/99)

---

### #96 · RepoName-afleiding immuun voor de pipeline-exitcode-race (echte kern-oorzaak CI-flakiness) · Fix · 2026-07-19

De git-afleiding in de bootstrap bleef na #94 en #95 nog **niet-deterministisch** rood op CI (de
ssh-cases faalden soms, soms niet): dezelfde code, dezelfde omgeving, wisselend resultaat. De kern-
oorzaak is nu gevonden en weggenomen.

- **Oorzaak:** `Get-DerivedRepoName` las de origin als
  `& git ... config --get remote.origin.url | Select-Object -First 1`. Die pipe breekt de upstream
  (git) vroegtijdig af zodra de eerste regel binnen is; als git op dat moment nog niet netjes is
  afgesloten, wordt het proces met een **non-nul exitcode** beeindigd — puur timing-afhankelijk. Die
  flaky `$LASTEXITCODE` liet de exitcode-guard soms `$null` teruggeven, waarna de scaffold op VUL-IN
  bleef staan en de drift-test faalde. Een byte-exacte probe won de race consequent; de echte
  bootstrap soms niet — vandaar het "onverklaarbare" verschil.
- **`bootstrap.ps1`**: de git-aanroep en `Select-Object -First 1` zijn ontkoppeld. Eerst wordt de
  volledige output gevangen, dan meteen `$LASTEXITCODE` in `$code` vastgelegd, en pas daarna volgt
  `Select-Object` op de vaste array. Zo kan de pipeline-afbraak de exitcode niet meer corrumperen.
- **Gevolg:** de afleiding is nu deterministisch — de exitcode weerspiegelt uitsluitend git zelf,
  onafhankelijk van pipeline-timing.

Rondt de jacht af die in #94 en #95 begon; sluit de flaky-blokker onder PR #93.

[PR #96](https://github.com/DaveKJohn/davekjohns-workshop/pull/96)

---

### #95 · Bootstrap leest de origin rauw via git config (immuun voor insteadOf, CI stabiel) · Fix · 2026-07-19

Verhelpt de kern-oorzaak van de flaky RepoName-afleiding-test (opvolger van #94): de bootstrap las de
origin via `git remote get-url`, dat **`insteadOf`-herschrijvingen toepast**. CI-runners (en sommige
dev-machines) zetten zulke regels globaal, en welke vorm ze produceren (kale https, token-https,
`ssh://`) verschilt per run — waardoor de afleiding intermittent op VUL-IN terugviel en de test soms
faalde. De brede regex (#94) verzachtte dat maar nam de onvoorspelbaarheid niet weg.

- **`bootstrap.ps1`**: leest de origin nu via `git config --get remote.origin.url`, dat de **rauwe**
  opgeslagen URL teruggeeft en `insteadOf` volledig negeert — exact wat de consument configureerde,
  immuun voor de git-config van de machine.
- **`bootstrap-drift.tests.ps1`**: de flaky git-config-isolatie (lege global/system) is verwijderd
  (niet meer nodig); de zes afleiding-cases blijven. Bewezen: de suite slaagt nu ook onder een actief
  vijandige `insteadOf` die `git@github.com:`/`ssh://` naar een token-https herschrijft.

Geen gedragswijziging voor consumenten met een gewone origin; puur een deterministische, machine-
onafhankelijke afleiding.

[PR #95](https://github.com/DaveKJohn/davekjohns-workshop/pull/95)

---

### #94 · RepoName-afleiding dekt alle github-URL-vormen (regex verbreed, CI-flakiness weg) · Fix · 2026-07-19

Maakt de RepoName-afleiding (#91) robuust voor álle github-URL-vormen en verhelpt daarmee een
**flaky CI-test**: de git-afleiding-cases faalden intermittent op de windows-runner doordat die een
globale git-`insteadOf` zet die `git@github.com:` naar wisselende vormen herschrijft (kale https,
https met token-userinfo, of `ssh://`) — en `git remote get-url` past die rewrite toe. De regex uit
#91/#92 dekte niet alle vormen, dus soms viel de afleiding terug op VUL-IN en faalde de test.

- **`bootstrap.ps1`**: de derivatie-regex accepteert nu alle gangbare github-vormen —
  `https://`, `ssh://`, `git://` (elk met optionele userinfo) én de scp-achtige `git@github.com:`.
  owner/repo blijft een strikte slug; userinfo wordt niet gevangen (een `evil.com/x@github.com`-spoof
  matcht dus niet).
- **`bootstrap-drift.tests.ps1`**: de git-afleiding-cases draaien met een geneutraliseerde
  global/system git-config (elke case test echt zijn eigen URL-vorm, immuun voor runner-`insteadOf`),
  met een extra `ssh-scheme`-case (`ssh://git@github.com/...`).

Geen gedragswijziging voor consumenten met een gewone origin-URL; puur bredere dekking + een
deterministische testsuite.

[PR #94](https://github.com/DaveKJohn/davekjohns-workshop/pull/94)

---

## v1.10.0 — 2026-07-19

### #92 · Bootstrap schrijft een durabel, versie-loos body-importpad · Fix · 2026-07-19

Dicht een durability-gat dat een acceptatietest van consument djcylow-react aan het licht bracht
(Gat C): bij een user-scope install schreef de `specialists-init`-bootstrap een **versie-gepind**
body-importpad in `CLAUDE.md`
(`@~/.claude/plugins/cache/<marketplace>/<plugin>/<versie>/personas/01-01-persona.md`). De cache is
ephemeer — na een plugin-update wordt de oude versie-map opgeruimd (~7 dagen), waarna de `@`-import
naar een niet-bestaand pad wijst en de **body van de orchestrator (Chris) stil niet meer laadt**.

- **`bootstrap.ps1`**: nieuwe `Get-DurablePersonaDir` vertaalt een cache-pad
  (`…/plugins/cache/<marketplace>/…`) naar de versie-loze marketplaces-clone
  (`…/plugins/marketplaces/<marketplace>/…`) — het durabele anker dat een update overleeft (git-pull,
  pad verandert niet). De marketplace-naam wordt uit het cache-pad gerecupereerd; de clone wordt
  geverifieerd (bestaat, bevat de plugin-personas met `01-01-persona.md`) vóór hij wordt gebruikt.
  Bij elke twijfel terugval op het oorspronkelijke pad — geen regressie voor de source/marketplaces-
  layout (de bron die zichzelf consumeert verandert niet). De feitelijke *read* blijft de cache;
  alleen het geschreven pad wordt durabel.
- **Onderbouwing (research)**: `@`-imports in `CLAUDE.md` kennen géén variabele-expansie
  (`${CLAUDE_PLUGIN_ROOT}` e.d. werken daar niet), dus een vast versie-loos pad is de enige route.
- **`bootstrap-drift.tests.ps1`**: case (2c) toegevoegd die de user-scope layout nabootst
  (`plugins/cache/<mp>/…` naast een `plugins/marketplaces/<mp>/`-clone) en assert dat de geschreven
  `@`-import naar de clone wijst, niet naar de versie-gepinde cache.

Meegenomen robuustheidsfix aan de RepoName-afleiding (#91), aan het licht gekomen doordat CI-runners
een globale git-`insteadOf` zetten die `git@github.com:` naar een https-URL **mét token-userinfo**
herschrijft (`git remote get-url` past dat toe):

- **`bootstrap.ps1`**: de derivatie-regex tolereert nu optionele userinfo in de https-vorm
  (`https://<userinfo>@github.com/owner/repo`); de userinfo wordt bewust niet gevangen — alleen
  owner/repo, streng gevalideerd. Zo leidt ook een consument met credentials in de origin-URL correct af.
- **`bootstrap-drift.tests.ps1`**: de git-afleiding-cases draaien nu met een geneutraliseerde
  global/system git-config (zodat de ssh-case echt SSH test, immuun voor runner-`insteadOf`), plus een
  expliciete `https-cred`-case die de userinfo-tolerantie vastlegt.

[PR #92](https://github.com/DaveKJohn/davekjohns-workshop/pull/92)

---

### #91 · Bootstrap leidt RepoName automatisch af uit de git-remote · Feat · 2026-07-19

Ergonomie-verbetering aan het `specialists-init`-bootstrap-adoptiepad (Gat B): een verse consument
hoeft de repo-naam niet langer met de hand in te vullen.

- **`bootstrap.ps1` (sectie 1c)**: nieuwe `Get-DerivedRepoName` leidt `owner/repo` af uit
  `git remote get-url origin` van de consument en vult daarmee `$script:RepoName` in de neergezette
  `scripts/repo-config.ps1`-scaffold, in plaats van de `VUL-IN/repo`-placeholder. Ondersteunt de
  HTTPS- én SSH-vorm en stript het `.git`-suffix.
- **Guardrails (advies Sean)**: de remote-URL is externe input die in een geschreven `.ps1` én in
  `gh --repo` belandt — daarom een verankerde regex, owner/repo beperkt tot een strikte slug, alleen
  `github.com`, en bij elke twijfel (niet-github host, geen remote, git niet beschikbaar) terugval op
  de `VUL-IN`-placeholder. De git-aanroep zit in een `try/catch` + `2>$null`/`$LASTEXITCODE` en laat
  de bootstrap nooit crashen (blijft additief, exit 0). `Get-LintScript` en de branch-prefix-tabel
  blijven bewust VUL-IN — die zijn niet af te leiden.
- **Schonere scaffold-kop + slotrapport**: de kop van de repo-config-scaffold en stap 2 van het
  bootstrap-rapport melden nu wat er nog handmatig moet als RepoName al is afgeleid.
- **`bootstrap-drift.tests.ps1`**: cases toegevoegd voor de afleiding (HTTPS + SSH → afgeleid, geen
  VUL-IN op de RepoName-regel) en de terugval (niet-github host + geen remote → `VUL-IN/repo`).

[PR #91](https://github.com/DaveKJohn/davekjohns-workshop/pull/91)

---

## v1.9.2 — 2026-07-19

### #88 · specialists-init SKILL.md beschrijft het plugin-pad/lens-only-model (was: oude .claude/extensions-kopie) · Docs · 2026-07-19

Corrigeert een bestaande doc-drift in `specialists-init/SKILL.md`: de skill-tekst beschreef het
oude adoptiemodel (persona-bodykopie naar `.claude/extensions/`), terwijl `bootstrap.ps1` allang het
huidige model hanteert — **lens-only** repo-lenzen op het **plugin-pad**
`.claude/plugins/<familie>/<plugin>/`, met de draagbare body via een `@`-import uit de plugin-install,
en **twee** `@`-imports onderaan `CLAUDE.md` (body + lens).

- Frontmatter-`description`, de "Wat de skill doet"-stappen (persona-lenzen, lens-scaffolds, de
  @-imports) en de "Afronden"/"Belangrijk"-secties volgen nu het feitelijke bootstrap-gedrag.
- Puur documentatie: geen script- of gedragswijziging. De opgekomen drift was gesignaleerd tijdens
  de #86-fix en is bewust apart opgepakt.

[PR #88](https://github.com/DaveKJohn/davekjohns-workshop/pull/88)

---

## v1.9.1 — 2026-07-19

### #87 · specialists-init scaffoldt repo-config + branch-info; open-pr/fold pre-flighten (schone consument) · Fix · 2026-07-19

Dicht het script-afhankelijkheden-gat van de gedeelde workflow-skills op een schone consument (inbound
[#86](https://github.com/DaveKJohn/davekjohns-workshop/issues/86), vervolg op [#81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81)).
`open-pr`/`fold` leunen op twee repo-eigen bestanden in de consument-root (`scripts/repo-config.ps1` +
`scripts/lib/branch-info.ps1`) die de bootstrap niet neerzette — bij een eerste install liep dat op een
rauwe dot-source-fout.

- **Bootstrap-scaffold:** `specialists-init/bootstrap.ps1` zet beide bestanden nu additief als
  `VUL-IN`-scaffold neer (nooit overschrijven), met een **lege** branch-prefix-tabel — de taxonomie is
  per repo anders en wordt bewust niet meegebakken.
- **Pre-flight:** `open-pr` (beide bestanden) en `fold` (alleen `repo-config`) checken vóór de
  dot-source op aanwezigheid én op niet-ingevulde `VUL-IN`-placeholders, en stoppen anders met een
  duidelijke wegwijzer i.p.v. een rauwe fout. De spiegels zijn via de generator opnieuw gegenereerd.
- **Tests:** bootstrap-drift dekt de scaffold + idempotentie; shared-scripts dekt het pre-flight-gedrag
  van beide bron-scripts.
- **Docs:** de skill-teksten (`specialists-init`, `open-pr`, `fold-changelog`) en de plugin-scripts-README
  volgen het nieuwe gedrag; de fold-vereisten corrigeren meteen dat fold géén `branch-info` gebruikt.

[PR #87](https://github.com/DaveKJohn/davekjohns-workshop/pull/87)

---

## v1.9.0 — 2026-07-19

### #85 · Fase 2: open-pr gedeeld als plugin-spiegel (lint-gate via repo-config) · Feat · 2026-07-19

Tweede stap van Fase 2 uit [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81): `open-pr.ps1` wordt gedeeld met consumenten als plugin-spiegel, met dezelfde mechaniek als de fold-pilot.

- **`open-pr.ps1` dual-context** gemaakt (repo-root via `${CLAUDE_PROJECT_DIR}` of git-root); `repo-config` + `branch-info` uit de repo-root i.p.v. `$PSScriptRoot`.
- **Lint-gate geparametriseerd:** het repo-specifieke lint-script komt nu uit `Get-LintScript` in `repo-config` (workshop: `check-plugin-integrity`; een consument kan zijn eigen lint opgeven). De test-poort blijft conventie (`scripts/tests/*.tests.ps1`). Gate-meldingen zijn generiek gemaakt.
- **Spiegel + skill:** `open-pr` geregistreerd in `shared-scripts-lib.ps1`, spiegel gegenereerd, en een consument-skill `open-pr` toegevoegd.
- **Tests/docs:** `repo-config.tests.ps1` dekt `Get-LintScript`; `shared-scripts.tests.ps1` borgt dual-context voor álle gedeelde scripts; de README-statustabel bijgewerkt.

Daarmee zijn beide Fase 2-doelscripts (`fold` + `open-pr`) gedeeld; `branch-info`/`repo-config` blijven bewust per repo lokaal (CI-pin + repo-data).

[PR #85](https://github.com/DaveKJohn/davekjohns-workshop/pull/85)

---

### #84 · Fase 2-pilot: fold-changelog gedeeld als plugin-spiegel (SSOT voor consumenten) · Feat · 2026-07-19

Eerste stap van Fase 2 uit [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81): `fold-changelog-entry.ps1` wordt gedeeld met consumenten als plugin-spiegel — geen verhuizing, de workshop houdt zijn eigen testbare root-kopie.

- **Dual-context repo-root** in `fold-changelog-entry.ps1`: lost de repo-root op via `${CLAUDE_PROJECT_DIR}` (consument die de spiegel draait) of de git-root (workshop). Dezelfde file werkt in beide locaties; `repo-config` wordt uit de repo-root geladen i.p.v. `$PSScriptRoot`.
- **Spiegel-mechaniek** naar het bestaande `build-agent-defs`-patroon: `scripts/lib/shared-scripts-lib.ps1` (register), `scripts/sync/build-shared-scripts.ps1` (generator met `-Check`), en een drift-lint-sectie in `check-plugin-integrity.ps1` die bewaakt dat de plugin-spiegel LF-identiek blijft aan de bron.
- **Consument-skill** `fold-changelog` draait de spiegel via `${CLAUDE_PLUGIN_ROOT}` — het enige door de docs bevestigde mechaniek voor mens én Claude.
- **Tests:** nieuwe suite `shared-scripts.tests.ps1` (register-contract, in-sync-invariant, dual-context-borging, `-Check`-poort).
- **Docs:** `specialists/scripts/README.md` herschreven naar de werkende spiegel-mechaniek + statusoverzicht.

`open-pr` volgt als losse stap (de lint/test-gate moet eerst via `repo-config` geparametriseerd worden).

[PR #84](https://github.com/DaveKJohn/davekjohns-workshop/pull/84)

---

### #83 · Plugin-scripts-README: Fase 2-realiteit corrigeren (branch-info CI-pin + bin/-gaten) · Docs · 2026-07-19

Corrigeert twee onjuistheden in `claude-code-plugins/claude-specialists/specialists/scripts/README.md` die in #82 zelf ontstonden:

- **`branch-info.ps1` kan niet mee naar de plugin.** De README suggereerde dat dat kon zodra `open-pr.ps1` meeverhuist, maar dezelfde PR (#82) liet `release-lib.ps1` `branch-info` dot-sourcen; `release-lib` draait in CI vanaf een kale checkout, waardoor `branch-info` nu ook door CI aan de root is vastgeklonken.
- **De `bin/`-aanroepkeuze is niet settled.** `bin/` staat op de PATH van de Bash-tool (niet de PowerShell-tool), een mens kan het niet direct aanroepen, en Windows `.ps1`-als-kaal-commando + `${CLAUDE_PROJECT_DIR}`-beschikbaarheid zijn ongedocumenteerd. Een skill is het enige bevestigde alternatief. De README verwijst nu naar het Fase 2-addendum op [#81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81).

[PR #83](https://github.com/DaveKJohn/davekjohns-workshop/pull/83)

---

### #82 · Centraliseer workflow-scripts (SSOT): repo-config + type-bron + plugin-scripts-fundament · Feat · 2026-07-18

Eerste stappen op het SSOT-pad uit [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81) (inbound van life-hub), zonder big-bang:

**Fase 0 (repo-lokaal, CI-veilig):**
- Nieuw `scripts/repo-config.ps1` als enige bron voor repo-data (`Get-RepoName`, `Get-RepoBlobUrl`). De repo-naam-hardcode is weg uit `open-pr.ps1` (1x), `fold-changelog-entry.ps1` (2x) en `cut-release.ps1` (blob-URL geinjecteerd i.p.v. de literal-default in `release-lib.ps1`).
- DRY-lek gedicht: de branch-typen (Feat/Fix/Docs/Chore) hebben nu een enige bron in `branch-info.ps1` via `Get-BranchTypes`; `release-lib.ps1` leest die i.p.v. een eigen `$catOrder`-kopie.

**Fase 1 (alleen structuur):**
- Nieuwe map `claude-code-plugins/claude-specialists/specialists/scripts/` met een README als toekomstig SSOT-thuis; de lint-parse-scan (`check-plugin-integrity.ps1`) bewaakt die map nu mee. Er is bewust nog geen script verhuisd (aanroep-mechaniek volgt later).

**Tests:** nieuwe suites `branch-info.tests.ps1` (incl. het type-SSOT-contract) en `repo-config.tests.ps1`.

[PR #82](https://github.com/DaveKJohn/davekjohns-workshop/pull/82)

---

## v1.8.0 — 2026-07-18

### #80 · Bootstrap seedt plugin-pad + lens-only (adoptie-laag) · Feat · 2026-07-18

De laatste stap om het plugin-pad + lens-only-model écht overal de standaard te maken: de
**adoptie-laag**. `bootstrap.ps1` (de `specialists-init`-skill) seedt een verse consument nu op het
**plugin-pad** met **lens-only** persona-lenzen — precies wat deze repo en life-hub al hebben — i.p.v.
het legacy-pad met volledige body-kopieën.

- **`bootstrap.ps1`** zet de lenzen op `.claude/plugins/<familie>/<plugin>/` (familie + plugin
  afgeleid uit het install-pad, met fallback voor de versie-cache-layout). De persona-lenzen zijn
  **lens-only**: alleen de lens-only-kop + het VUL-IN-repo-lens-slot, géén body-kopie. `CLAUDE.md`
  krijgt **twee** `@`-imports voor Chris: zijn draagbare body uit de plugin-install
  (`@~/.claude/plugins/marketplaces/<marketplace>/.../01-01-persona.md`) én zijn repo-lens.
- **Regressietests** (`bootstrap-drift.tests.ps1`) herschreven: plugin-pad, lens-only, de twee
  imports, de versie-cache-fallback en de behouden legacy-body-drift-vergelijking (30 asserts).
- **Docs** (`QUICKSTART.md`, `connectors/README.md`) bijgewerkt naar het plugin-pad + lens-only-model.

De body laadt runtime uit de plugin-install; dat `~`-import-pad is (net als bij life-hub) niet volledig
via de fixture-tests af te dwingen — de tests dekken de pad-/lens-only-structuur, het live `@`-import-
gedrag is bewezen doordat life-hub het draait. Lint + alle testsuites groen.

[PR #80](https://github.com/DaveKJohn/davekjohns-workshop/pull/80)

---

## v1.7.0 — 2026-07-18

### #77 · Repo-lenzen naar het plugin-pad als standaard (primair + legacy-fallback) · Feat · 2026-07-18

De repo-lenzen van deze repo verhuizen van het legacy-pad (`.claude/extensions/`) naar het
**plugin-pad** (`.claude/plugins/claude-specialists/specialists/`) — de nieuwe standaard-locatie
(pariteit met life-hub). Om de andere consumerende repo's (life-hub, smartwatchbanden) niet te breken,
verwijst het gedeelde contract voortaan naar het **plugin-pad als primair, met het legacy-pad als
fallback** — een repo die nog op legacy staat blijft dus gewoon werken.

**Deze repo:**
- De 11 lenzen (incl. Ravi 06-24) + het handboek verplaatst naar het plugin-pad, met de relatieve
  link-diepte bijgesteld (2 → 4 niveaus). De 5 lege stubs (Paula/Bianca/Vera/Gwen/Cody) opgeruimd.
- De `@`-import onderaan `CLAUDE.md` → plugin-pad. Alle doc-verwijzingen (`CLAUDE.md`, `README.md`,
  het handboek) → plugin-pad. De persona-lens-index-regels naar locatie-onafhankelijke platte tekst.
- `check-plugin-integrity.ps1` scant nu de lenzen op het plugin-pad **én** het legacy-pad.

**Het gedeelde contract (raakt alle repo's, via de volgende release):**
- De ~20 agent-defs en de ~20 manuals verwijzen subagents nu naar het plugin-pad (primair) met het
  legacy-pad als fallback. De generieke lens-mention in het gedeelde `grens-inbound`-blok idem.

**Bewust uitgesteld (blijft werken via de fallback):** de **adoptie-laag** — `bootstrap.ps1` seedt
nieuwe consumenten nog op het legacy-pad, en `QUICKSTART.md` / `connectors/README.md` beschrijven dat
zo. Dat volledig omzetten (incl. de bootstrap-tests) is een aparte vervolgstap; tot die tijd landt een
verse consument op legacy en werkt hij via de fallback.

Lint en alle testsuites groen. De `## Releases`-CHANGELOG-entries zijn als historisch record ongemoeid
gelaten.

[PR #77](https://github.com/DaveKJohn/davekjohns-workshop/pull/77)

---

### #76 · Persona-sjabloon-intro's gededupliceerd (Ravi's eerste klus) · Chore · 2026-07-18

Ravi's eerste opdracht: de persona-sjablonen op duplicatie scannen. Bevinding — er zijn **geen
verbatim-gedeelde gedragsbullets** over de vier persona's (Chris, Bianca, Derek, Rendall); de
gedragsregels zijn bewust rol-geformuleerd (rol-nuance, niet harmoniseren). De énige verbatim-duplicatie
was het **intro-uitleg-commentaar** — een grotendeels identieke herhaling van het gesplitste model dat
`README.md` al vastlegt, en dat (in een HTML-commentaar) het gedeelde-blok-mechanisme sowieso niet kan
gebruiken.

Actie: het intro-commentaar in de vier sjablonen ingekort tot een korte verwijzing naar `README.md`,
met behoud van de rol-specifieke eerste regel. Netto ~33 regels boilerplate weg, en minder ruis die een
lens-only consument via de `@`-import meelaadt (sluit aan op de #69-schoonmaak). Het commentaar staat
boven de H1, dus `Get-PortableBody` raakt het niet — geen drift-regressie.

Conclusie voor de toekomst: het sentinel-mechanisme uitbreiden naar persona's heeft nú geen payload
(geen deelbaar body-blok); dat wacht tot een verbatim-gedeelde persona-bullet daadwerkelijk opduikt.

[PR #76](https://github.com/DaveKJohn/davekjohns-workshop/pull/76)

---

### #75 · Ravi (refactoring-specialist / DRY-bewaker) toegevoegd aan het team · Feat · 2026-07-18

Een nieuw teamlid in de `specialists`-plugin (groep 06, de vóór-de-merge-bewakers): **Ravi ♻️
#06-24**, de refactoring-specialist. Zijn vak is *single source of truth*: hij is de staande
verantwoordelijke voor duplicatie van **gedragsregels** (grenzen/werkwijzen) over agent-defs en
persona's. Zodra dezelfde regel op ≥2 plekken staat, slaat hij alarm en promoveert die tot één
gedeelde bron — beschikbaar voor de kring die de regel deelt, **niet** automatisch voor iedereen.

- **`specialists/agents/06-24-agent.md`** — de subagent-def (`@specialists:ravi`), die zelf het
  gedeelde `grens-inbound`-blok via sentinels gebruikt (dogfooding).
- **`specialists/manuals/06-24-manual.md`** — het draagbare vakboek, met "globaal = beschikbaar voor
  een deel, niet automatisch voor iedereen" als harde regel.
- **`.claude/extensions/06-24-extension.md`** — de repo-lens: wat Ravi hier bewaakt (de agent-defs +
  persona's van deze marketplace) en het `agent-shared/`-build-en-lint-mechanisme dat hij bedient.
- **Roster ingehaakt** in `CLAUDE.md`, Chris' routingtabel + twee ketens (parallelle
  kwaliteitscheck vóór PR én een eigen "duplicatie globaliseren"-keten), en het
  specialisten-handboek (`.claude/README.md`) + de root-README.

Ravi's eerste openstaande klussen: het gedeelde-blok-mechanisme uitbreiden naar de persona-sjablonen,
de Tier 2-sweep (eindbericht/gespreksgeschiedenis/branch), en een detectie-lint als
alarmbel-automatisering. Doel: het project zo klein en efficiënt mogelijk houden.

[PR #75](https://github.com/DaveKJohn/davekjohns-workshop/pull/75)

---

## v1.6.0 — 2026-07-18

### #74 · Gedeelde agent-def-blokken uit een enkele bron (build-en-lint) · Feat · 2026-07-18

Verbatim-gedeelde bullets onder **Grenzen** — de inbound-regel (19/19 agent-defs), de
webcontent-regel (3) en de Artifact-publiceer-regel (2) — werden tot nu toe in elke agent-def
handmatig gedupliceerd; één regel wijzigen betekende tot 19 bestanden aanraken. Ze komen nu uit
**één bron**, ingevuld door een generator en bewaakt door de lint-poort.

- **`claude-code-plugins/claude-specialists/agent-shared/<naam>.md`** — de canonieke bron van elk
  gedeeld blok (naast de plugin-mappen, zodat het niet met de plugin-cache meereist).
- **In de agent-defs** verschijnt elk blok tussen `<!-- BEGIN/END shared:<naam> -->`-sentinels. De
  inhoud staat er letterlijk (altijd-geladen, self-contained — Claude Code kent geen native
  transclusie in een agent-def), maar is als gegenereerd gemarkeerd.
- **`scripts/agents/build-agent-defs.ps1`** (+ `scripts/lib/agent-shared-lib.ps1`) — vult elke
  gemarkeerde regio uit zijn bron. Wijzig het bronbestand → draai het script → alle agent-defs bij.
  `-Check` meldt drift zonder te schrijven.
- **`check-plugin-integrity.ps1` (check 7)** faalt zodra een gemarkeerde regio afwijkt van zijn bron
  (hand-edit binnen de sentinels of een vergeten rebuild) — dezelfde poort die `open-pr.ps1` en CI
  al draaien.
- Regressietests in `scripts/tests/agent-shared.tests.ps1` (10 asserts) dekken de expansie, de
  drift-detectie, een BEGIN-zonder-END, een onbekend blok en de repo-in-sync-smoke.

De 19 agent-defs zijn puur omwikkeld met sentinels — nul inhoudelijke wijziging. Aanpassen van een
gedeelde grens kost voortaan één edit + één build in plaats van 19 handmatige wijzigingen.

[PR #74](https://github.com/DaveKJohn/davekjohns-workshop/pull/74)

---

## v1.5.2 — 2026-07-18

### #73 · Persona-indexregel locatie-onafhankelijk (bron-fix inbound #64) · Fix · 2026-07-18

De indexregel onder de titel van de vier persona-sjablonen (`01-01`, `03-02`, `05-05`, `05-06`) droeg een pad-diepte-afhankelijke markdown-link naar de repo-CLAUDE.md (`](../../CLAUDE.md)`). Die diepte klopt alleen op het legacy-pad (2 niveaus); op het plugin-pad (4 niveaus) was het een dode link, waardoor de draagbare body daar nooit byte-identiek aan de bron kon zijn.

- **De indexregel is nu platte tekst** (`Index: de repo-CLAUDE.md · …`), locatie-onafhankelijk. Een consument neemt de body op elk pad byte-identiek over — geen dode link meer.
- **De link-diepte-normalisatie in `check-consumer-drift.ps1` (`Get-PortableBody`) is verwijderd**, want overbodig geworden: er is geen pad-afhankelijke link meer om te normaliseren. Dit ruimt de workaround uit PR #68 (v1.5.0) op ten gunste van een bron-fix.
- De regressietests zijn navenant bijgewerkt: de twee normalisatie-tests zijn vervangen door één guard die borgt dat de indexregel geen pad-diepte-link meer draagt.

Dit is de bron-oplossing voor inbound life-hub [#64](https://github.com/DaveKJohn/davekjohns-workshop/issues/64): PR #68 doodde het vals-positieve `DRIFTED`-signaal aan de check-kant, deze wijziging neemt de wortel weg. Consumenten laten bij de volgende sync de link in hun indexregel vallen.

[PR #73](https://github.com/DaveKJohn/davekjohns-workshop/pull/73)

---

## v1.5.1 — 2026-07-18

### #72 · Persona-sjablonen en drift-check kennen het lens-only-model · Fix · 2026-07-18

Twee samenhangende punten uit inbound life-hub [#69](https://github.com/DaveKJohn/davekjohns-workshop/issues/69), beide gevolg van het lens-only-model dat een consument geen body-kopie meer laat bewaren:

- **Het `## Eigen aan deze repo (VUL-IN)`-slot is uit de vier persona-sjablonen gehaald** (`01-01`, `03-02`, `05-05`, `05-06`). Bij een consument die de body rechtstreeks importeert (lens-only) laadde dat slot — een bootstrap-instructie, geen persona-inhoud — als ruis mee in elke sessie. De sjabloon-intro-comments zijn navenant bijgewerkt.
- **`bootstrap.ps1` genereert het VUL-IN-slot nu zelf** bij het kopiëren van een persona, in plaats van het uit het sjabloon over te nemen — zo houdt een verse consument een duidelijke plek voor de repo-lens (DRY met de lens-scaffolds van stap 1b).
- **`check-consumer-drift.ps1` kent het lens-only-model.** Een consument-extension die met de `> Repo-lens (lens-only persona)`-blockquote opent, heeft per definitie geen body-kopie; de check meldt die nu als `LENS-ONLY` in plaats van de vals-positieve `DRIFTED`. Zo betekent een `DRIFTED`-melding weer altijd een écht werkpunt.

De regressietests in `scripts/tests/bootstrap-drift.tests.ps1` borgen dat het sjabloon schoon is, dat de bootstrap zelf een VUL-IN-slot toevoegt (geen drift-regressie op een verse kopie) en dat een lens-only extension als `LENS-ONLY` wordt gerapporteerd.

[PR #72](https://github.com/DaveKJohn/davekjohns-workshop/pull/72)

---

### #71 · Inbound-regel toegevoegd aan alle agent-defs · Docs · 2026-07-17

Elk van de 19 agent-defs in de drie plugins (`specialists`, `specialists-lifehub`,
`specialists-shopify`) heeft nu een eigen bullet in zijn **Grenzen**-sectie die de
inbound-route benoemt: verbeterpunten aan de gedeelde kern (de eigen agent-def en vakboek,
die van collega's, en alle andere onderdelen die de plugin draagt) bouwt een specialist
niet lokaal om; hij meldt ze via de vaste, afgesproken route — een issue met het label
`inbound` op de bron-repo van de plugin (het issue-sjabloon staat er al klaar), generiek
beschreven en zonder repo-eigen, persoonlijke of gevoelige details uit de eigen repo.
Werkt hij al in de bron-repo zelf, dan volgt hij daar gewoon de normale keten. Repo-eigen
aanvullingen horen in de repo-lens. Zo kent ook een rechtstreeks aangeroepen
werker-subagent deze regel, niet alleen Chris' persona-body en de QUICKSTART. De
formulering is na twee correctierondes (Edith's eindredactie: generieke plugin-onderdelen
+ collega's-agent-defs; Sean's security-review: standing-route-framing + de
anonimiseringscaveat) tot deze definitieve tekst gekomen.

[PR #71](https://github.com/DaveKJohn/davekjohns-workshop/pull/71)

---

## v1.5.0 — 2026-07-17

### #66 · Chris sluit af zonder vaste slotformule · Docs · 2026-07-17

Op verzoek van Dave: de vaste afsluitvraag ("hoe kan ik verder van dienst zijn?") is uit stap 6 van Chris' ritueel gehaald — die werd eentonig. Chris vat nog steeds samen en mag een concrete volgende stap noemen, maar sluit af zonder standaard slotformule. Aangepast in beide bronnen: de repo-lens (`.claude/extensions/01-01-extension.md`) en het canonieke persona-sjabloon in de plugin (`personas/01-01-persona.md`).

[PR #66](https://github.com/DaveKJohn/davekjohns-workshop/pull/66)

---

### #61 · Per-plugin CHANGELOGs: consument-gerichte release-geschiedenis die meereist · Feat · 2026-07-16

Elke plugin draagt nu een eigen `CHANGELOG.md` die met de plugin-cache meereist: de
consument-gerichte selectie uit de werkplaats-geschiedenis. De fold leidt per entry automatisch
een `Plugins:`-regel af uit de PR-bestanden (`gh pr view --json files`; de `connectors/`-map telt
niet mee), en `cut-release.ps1` schrijft bij elke release per plugin de rakende entries bij —
nieuwste bovenaan, met root-relatieve links herschreven naar absolute GitHub-URLs zodat ze in een
consument-cache blijven werken. Vier nieuwe pure functies in `release-lib.ps1` met twaalf nieuwe
asserts (50 totaal); drie seed-CHANGELOGs; Rendall's lens en het root-README beschrijven het
mechaniek. De root-`CHANGELOG.md` en `releases/` blijven de volledige werkplaats-geschiedenis.

[PR #61](https://github.com/DaveKJohn/davekjohns-workshop/pull/61)
