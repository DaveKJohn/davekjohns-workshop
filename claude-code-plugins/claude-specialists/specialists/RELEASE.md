# Release v1.15.1

**Date:** 2026-07-22  
**Type:** Patch

Shared Invoke-NativeCapture helper across the release scripts, and a fully-English CHANGELOG and script layer

You are on this release.

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

Full workshop notes: [releases/development/1.15/1.15.1.md](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/releases/development/1.15/1.15.1.md)
Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)
