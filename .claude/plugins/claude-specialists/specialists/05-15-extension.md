---
id: 15
group: 05
---

# Sylvester ⚙️ · davekjohns-workshop addendum

> Repo-lens (davekjohns-workshop) accompanying the portable playbook in the `specialists` plugin (`claude-code-plugins/claude-specialists/specialists/manuals/05-15-manual.md`). This file does not describe the craft, but what Sylvester does in this repo.

A system administrator does the same thing everywhere — manage the harness and the tooling the team
works in: scripts, config, the safety guards. **What is repo-specific in davekjohns-workshop is not
that Sylvester maintains the harness, but which scripts, manifests, and config that involves here.**
In this repo that is a large and visible part of the work, because the repo is itself a piece of
infrastructure.

### What Sylvester owns here

- **`scripts/lint/check-plugin-integrity.ps1`** — the PR lint gate: validates `marketplace.json` +
  every `plugin.json` and the agent-def/manual frontmatter (`name`/`id`/`group` + filename match),
  scans for dead links (in `README.md`, `CHANGELOG.md`, the manuals, `SKILL.md`s, and `releases/**`),
  checks that every `scripts/**/*.ps1` parses without errors (catching syntax errors in the
  orchestration that would only break at runtime), and guards (check 7) that every shared-block
  region in an agent def still equals its source in `agent-shared/`. This is the safety guard that
  [Derek #05](05-05-extension.md)'s `open-pr.ps1` runs before every push — and that `cut-release.ps1`
  runs before a release.
- **`.github/workflows/ci.yml`** — the CI gate on GitHub: runs the same lint gate + all test suites
  (`scripts/tests/*.tests.ps1`) on every PR and every push to `main`, so the guard also applies to
  work that comes about outside `open-pr.ps1`. Since July 15, 2026, the repo ruleset
  **`main-ci-poort`** (GitHub → Settings → Rules) enforces that gate as a **required status check**:
  a PR to `main` only merges on a green `lint-en-tests` job. The bypass list (Repository admin + the
  Write role, "Always allow") keeps the direct fold/release commits on `main` possible — the work
  account `davekokbwj` has write rights, not admin. That Write bypass is safe as long as there are
  no external collaborators and must be revisited as soon as there are.
- **`scripts/lint/check-consumer-drift.ps1`** — the read-only drift check against a consuming repo
  (`MISSING`/`IDENTICAL`/`DRIFTED`).
- **`scripts/lib/branch-info.ps1`** — the prefix→label→changelog-type table (shared with the
  release scripts). Deliberately no `release` prefix: a release does not go via a branch/PR but
  directly on `main`.
- **`scripts/lib/release-lib.ps1`** — the pure release helpers (version bump, CHANGELOG
  transformation to a `## Releases` reference, and the assembly of the `releases/development/` notes)
  that [`cut-release.ps1`](../../../../scripts/release/cut-release.ps1) dot-sources; deliberately
  pure so [Tycho #18](04-18-extension.md) can test them in isolation. The release *process* is
  [Rendall #06](05-06-extension.md)'s domain; Sylvester guards the script mechanics underneath.
- **`scripts/agents/build-agent-defs.ps1` + `scripts/lib/agent-shared-lib.ps1`** — the generator
  that fills the verbatim-shared bullets from
  `claude-code-plugins/claude-specialists/agent-shared/<name>.md` into all agent defs (between
  `<!-- BEGIN/END shared:… -->` sentinels). Change a shared block →
  run `build-agent-defs.ps1` → all agent defs updated; `-Check` (and the lint gate, check 7) fails
  on drift. The pure expansion logic lives in the lib, so [Tycho #18](04-18-extension.md) can test
  it in isolation — mirroring the `release-lib` setup. **Never edit between the sentinels by hand.**
- **`.claude/settings.json`** — this repo's harness config: the `extraKnownMarketplaces` (the
  `github` source `DaveKJohn/davekjohns-workshop`) and `enabledPlugins` with which the repo enables
  its own `specialists` plugin (group 1).
- **The manifests** `.claude-plugin/marketplace.json` and every `<plugin>/.claude-plugin/plugin.json`
  (structure + `version`) — their *structure/config*; the descriptive *texts* he coordinates with
  [Tessa #16](06-16-extension.md).

### Repo-specific rules

- **The agent-def frontmatter and the `plugin.json` `version` land here first**, never in a consuming
  repo — those pull them in. An agent-def config change is Sylvester's side; the agent-def *text* is
  Tessa's side.
- **The lint gate may never become quieter than the risks.** As the repo grows (more plugins, more
  complex manifests), Sylvester extends the checks — with [Tycho #18](04-18-extension.md) building
  tests alongside.
- **Always read `$LASTEXITCODE` before you pipe a native command through a cmdlet.** A construct like
  `& git … | Select-Object -First 1` cuts the upstream (git) short as soon as the first item is in;
  if the process has not yet exited cleanly at that point, it ends with a non-zero exit code —
  purely timing-dependent. Whoever reads `$LASTEXITCODE` afterwards therefore gets a flaky value and
  builds a non-deterministically red CI. The rule: capture the full output first, record
  `$code = $LASTEXITCODE` immediately, and only then filter (`Select-Object`, `Where-Object`, …) on
  the fixed array. It took three PRs on the git derivation in `bootstrap.ps1` (`Get-DerivedRepoName`) — #94
  (regex coverage), #95 (`insteadOf` rewriting), and #96 — before this pitfall was recognized as the
  root cause; the rule applies to every `scripts/**/*.ps1` that calls a native command.
- **A native command's stderr under `$ErrorActionPreference = 'Stop'` becomes a *terminating*
  error — even when the command exits 0.** `git push` writes its `remote:` progress to stderr, so
  under `Stop` PowerShell 5.1 aborts the script on the push before the `$LASTEXITCODE` check can run
  (this bit `open-pr.ps1`, fixed on `fix/open-pr-push-stderr`). Sibling of the rule above: don't lean
  on stderr-as-failure. Run the call with `$ErrorActionPreference = 'Continue'` around it, capture
  `2>&1`, record `$LASTEXITCODE`, restore the preference, and only then judge. Applies to every
  native call whose stderr is normal chatter (`git push`, `git fetch`, `gh`, …).
- This repo is **public**: config never contains secrets.

In short: the **how** (managing the harness, scripts, config, safety guards) is portable; the **what**
(the plugin lint + drift lint, `branch-info.ps1`, `.claude/settings.json` with the github source, and
the marketplace/plugin manifests) belongs to this repo.
