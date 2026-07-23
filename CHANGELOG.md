# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`README.md`](README.md#contributing--changelog--pr-workflow).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #151 · Record how the specialists system relates to Cowork and Skills · Docs · 2026-07-23

Records, as a durable doc fact rather than only in memory, how this specialists system relates to
Anthropic's Cowork and Agent Skills concepts — until now there was zero reference to Cowork anywhere
in the repo. Added a new `README.md` section, "Where this runs: Chat, Cowork, and Claude Code"
(after "Shared agent-def blocks", before "Consumption"), stating the operationally important fact:
a skill bundled in a plugin works in Claude.ai Chat, Cowork, and Claude Code alike, but a subagent or
a hook runs only in Cowork and in Claude Code — in plain Chat they show up grayed out. Concretely for
this repo: the specialists roster (the subagents under Chris) and the three SessionStart hooks
(`connector-sessioncheck`, `roster-sessioncheck`, `script-contract-sessioncheck`) are
Cowork/Claude-Code-only; the skills (`fold-changelog`, `open-pr`, `new-branch`, `specialists-init`,
`sync-roster`, `start-task`) remain available everywhere. Also notes, briefly and with sources,
what Cowork and Agent Skills are, and flags two open uncertainties (whether Cowork runs on the Claude Agent SDK; whether a Cowork subagent
shares its definition format with a Claude Code subagent) as unconfirmed rather than fact.

`CLAUDE.md` gets a short pointer to that section (under "The Claude Specialists — who does what"),
so the fact is discoverable from both entry docs without duplicating it.

[PR #151](https://github.com/DaveKJohn/davekjohns-workshop/pull/151)

---

### #150 · Record the StrictMode-off rule for dot-sourcing consumer libs (Sylvester lens) · Docs · 2026-07-22

Records the lesson behind #148/#149 as a durable rule in Sylvester #15's repo lens
(`.claude/plugins/claude-specialists/specialists/05-15-extension.md`), so the next check or hook that
dot-sources a consumer's repo-owned lib gets it right by design instead of rediscovering it at
runtime. Added in the "Repo-specific rules" section as a third rule of that kind, joining its two
sibling native-command rules (the `$LASTEXITCODE`-before-pipe rule and the stderr-under-`Stop` rule):

- **The rule:** a check/hook that dot-sources `branch-info.ps1`/`repo-config.ps1` to probe it must do
  so in a child scope with `Set-StrictMode -Off`, because the real workflow scripts that consume those
  libs never enable StrictMode and the libs are written on that assumption. Loading under strict mode
  makes harmless pre-strict-mode loose top-level code throw — a false `[ERROR]`, or a full crash under
  `$ErrorActionPreference = 'Stop'` — at every session start, for exactly the older consumer repos the
  checks serve. A genuine load failure should degrade gracefully, not abort the check.

Doc-only; no script or config change (the two fixes themselves shipped in #148/#149).

Plugins: specialists

[PR #150](https://github.com/DaveKJohn/davekjohns-workshop/pull/150)

---

### #149 · Load repo-config without StrictMode in check-roster-sync (sibling of #147) · Fix · 2026-07-22

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

Plugins: specialists

[PR #149](https://github.com/DaveKJohn/davekjohns-workshop/pull/149)

---

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
