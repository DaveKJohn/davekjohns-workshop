### open-pr.ps1 survives git push's stderr chatter · Fix · 2026-07-20

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
