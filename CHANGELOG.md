# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`README.md`](README.md#contributing--changelog--pr-workflow).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #148 · Script-contract drift check for repo-owned lib helpers (inbound #147) · Feat · 2026-07-22

Adds a detection layer for the repo-owned script contract, closing inbound #147 from life-hub. The
shared, mirrored workflow scripts (`new-branch`/`new-changelog-entry`/`open-pr`/`fold-changelog-entry`/
`check-roster-sync`, issue #81) dot-source **repo-owned** libs from the consumer
(`scripts/lib/branch-info.ps1`, `scripts/repo-config.ps1`), but nothing signalled when those libs
lagged the function contract the shared scripts call at runtime. The real incident: after updating
the plugin v1.12.1 → v1.18.0, the first `new-branch` run crashed with
`The term 'Test-BranchName' is not recognized` — the consumer's `branch-info.ps1` predated that
helper, and the gap stayed invisible until the flow broke. There was a roster-drift guard
(`check-roster-sync` + `roster-sessioncheck`) but no equivalent for the script contract; this mirrors
that architecture exactly.

- **New local check `scripts/sync/check-script-contract.ps1`.** Declares the mandatory
  repo-owned functions per mirrored, consumer-run shared script (`Get-BranchInfo`/`Test-BranchName`
  from `branch-info.ps1`; `Get-RepoName`/`Get-LintScript`/`Get-RosterPath`/`Get-RosterIgnoredIds` from
  `repo-config.ps1`), dot-sources the consumer's copy and asserts each is defined via `Get-Command`,
  reporting a missing one as `[ERROR]` that names the function, its lib, and the shared script(s) that
  call it. Read-only, dual-context repo root, shared `[OK]/[INFO]/[ERROR]` helpers from
  `check-report-lib.ps1`. The consumer libs are dot-sourced in a child scope with StrictMode OFF, to
  match how the real (non-strict) workflow scripts load them — so harmless pre-strict-mode loose
  top-level code in an older consumer's lib does not trip a false `[ERROR]`. The optional `Get-Pr*`
  functions `open-pr.ps1` guards via `Get-Command` are
  deliberately out of the contract (a consumer without them is not drifted); workshop-only scripts
  (`ship-pr.ps1`/`cut-release.ps1`) are out of scope (not mirrored). Registered as a mirrored pair in
  `shared-scripts-lib.ps1` and generated into the plugin via `build-shared-scripts.ps1`.
- **New SessionStart hook `script-contract-sessioncheck.ps1`.** A structural twin of
  `roster-sessioncheck.ps1`: runs the mirrored check silently, surfaces only `[ERROR]` lines into the
  session context, always exits 0. Added as a third SessionStart hook in the plugin's `hooks.json`
  alongside the connector and roster checks (both untouched). This turns the class of runtime crash
  behind #147 into an actionable heads-up right after a plugin update.
- **Tests (`scripts/tests/script-contract.tests.ps1`, 87 asserts).** Happy path, the exact #147
  missing-`Test-BranchName` case, a missing `repo-config` function, an entirely missing lib file, a lib
  that throws on load, and proof the optional `Get-Pr*` functions are never flagged; plus a two-layer
  contract-completeness drift guard (the declared contract still lists the exact six pairs, and each
  declared function still literally appears in its shared script's real source, so a stale entry is
  caught).

Verified: `build-shared-scripts.ps1 -Check` in sync, `check-plugin-integrity.ps1` 0 errors, and all
11 test suites green.

Plugins: specialists

Plugins: specialists

[PR #148](https://github.com/DaveKJohn/davekjohns-workshop/pull/148)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.18/1.18.0.md](releases/development/1.18/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.17/1.17.0.md](releases/development/1.17/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.16/1.16.0.md](releases/development/1.16/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.15/1.15.1.md](releases/development/1.15/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.15/1.15.0.md](releases/development/1.15/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.14/1.14.0.md](releases/development/1.14/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.13/1.13.0.md](releases/development/1.13/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.12/1.12.1.md](releases/development/1.12/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.12/1.12.0.md](releases/development/1.12/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.11/1.11.0.md](releases/development/1.11/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.10/1.10.0.md](releases/development/1.10/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.9/1.9.2.md](releases/development/1.9/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.9/1.9.1.md](releases/development/1.9/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.9/1.9.0.md](releases/development/1.9/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.8/1.8.0.md](releases/development/1.8/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.7/1.7.0.md](releases/development/1.7/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.6/1.6.0.md](releases/development/1.6/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.5/1.5.2.md](releases/development/1.5/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.5/1.5.1.md](releases/development/1.5/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.5/1.5.0.md](releases/development/1.5/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.4/1.4.1.md](releases/development/1.4/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.4/1.4.0.md](releases/development/1.4/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.3/1.3.0.md](releases/development/1.3/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.2/1.2.0.md](releases/development/1.2/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.1/1.1.1.md](releases/development/1.1/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.1/1.1.0.md](releases/development/1.1/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) for the full release notes.
