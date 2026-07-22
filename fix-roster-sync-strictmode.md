### Load repo-config without StrictMode in check-roster-sync (sibling of #147) · Fix · 2026-07-22

Fixes the same strict-mode false-positive in `scripts/sync/check-roster-sync.ps1` that #147/#148 fixed
in `check-script-contract.ps1`. The roster check runs under `Set-StrictMode -Version Latest` +
`$ErrorActionPreference = 'Stop'` and dot-sourced the consumer's `scripts/repo-config.ps1` directly in
that strict scope to read `Get-RosterPath`/`Get-RosterIgnoredIds`. But `repo-config.ps1` is explicitly
written on the no-strict-mode assumption (the real runtime callers never enable StrictMode), so a
consumer copy carrying harmless pre-strict-mode loose top-level code (e.g. an `if` on an unset
variable) threw at the dot-source — and because EAP is `Stop`, that terminated the whole roster check,
making the `roster-sessioncheck` hook report "could not complete" at every session start, for exactly
the older consumer repos the check serves.

- **Strict-off child-scope load.** `repo-config.ps1` is now dot-sourced and probed in a child scope
  with `Set-StrictMode -Off` (the same idiom as the `check-script-contract.ps1` fix), so it matches how
  the real workflow scripts load it and harmless loose top-level code no longer trips it. The resolved
  `Get-RosterPath`/`Get-RosterIgnoredIds` values replace the defaults exactly as before; absent
  `repo-config.ps1` keeps the sane defaults untouched.
- **Genuine load failure degrades gracefully.** A real load error (e.g. a syntax error, not just
  strict-mode noise) now falls back to the sane defaults (`CLAUDE.md`, no ignored ids) with a
  non-blocking `Write-Info`, instead of crashing the whole check — consistent with this check's
  documented "sane default, does not hard-require repo-config" stance.
- **Regression test** (`roster-sync.tests.ps1`, scenario 14): a consumer `repo-config.ps1` defining the
  roster functions plus loose top-level code referencing an unset variable — the check now runs clean
  (exit 0), honors `Get-RosterPath`, and surfaces no strict-mode exception. Verified non-vacuous
  (reverting the fix makes it fail).

`check-roster-sync.ps1` is a mirrored shared script; the plugin mirror was regenerated via
`build-shared-scripts.ps1`. Verified: `build-shared-scripts.ps1 -Check` in sync,
`check-plugin-integrity.ps1` 0 errors, and all 11 test suites green (roster-sync at 58 asserts).

Plugins: specialists
