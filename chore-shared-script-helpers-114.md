### Quiet-moment backlog #114: shared check-report helpers + two-plugin roster-sync test (native-capture assessed, not extracted) · Chore · 2026-07-21

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
