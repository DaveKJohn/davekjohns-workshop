# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #167 · fold-changelog: only fold real changelog-entry files, not root meta docs · Fix · 2026-07-24

**Bug:** in fold-all mode (`fold-changelog-entry.ps1` without `-Branch`) any root `*.md` that was not
in a tiny denylist (`CHANGELOG.md`/`CLAUDE.md`/`README.md`) was treated as a changelog entry — so
the repo-meta files `CONTRIBUTING.md` and `SECURITY.md` (added later) got folded into `CHANGELOG.md`
and then removed. Caught and reverted during the Marlowe fold; nothing shipped.

**Fix:** add a positive, structural gate. A changelog entry always opens with the compact
`### <title> · <type> · <date>` H3 heading (the fold code already relies on that `###` line);
repo-root meta docs open with an H1. Fold-all now folds a file only if its first non-empty line is
that H3 heading, so meta docs are never folded. Deliberately independent of the branch-prefix table,
so consumer-extended prefixes (Shopify's `style/`, `liquid/`, …) still fold. `-Branch` mode is
unchanged (it targets exactly the named entry).

- `scripts/release/fold-changelog-entry.ps1`: new `Test-IsChangelogEntryFile` helper + the fold-all
  filter; header doc updated. Plugin mirror re-synced byte-identical via `build-shared-scripts.ps1`.
- New regression suite `scripts/tests/fold-changelog.tests.ps1` (17 asserts): meta docs survive, a
  genuine entry folds, an extended-prefix entry still folds, a hyphen-named H1 doc is not folded,
  and `-Branch` mode is unaffected.

Plugins: specialists

[PR #167](https://github.com/DaveKJohn/davekjohns-workshop/pull/167)

---

### #166 · Add Marlowe #29 -- adversarial conclusion reviewer (investigative journalist / watchdog) · Feat · 2026-07-24

New specialist in the shared `specialists` plugin (flows back to every consumer via a release):
**Marlowe 🕵️ #29, the Investigative Journalist / consumer watchdog** — the independent devil's
advocate on the *substance and conclusions* of the team's work.

Where Victor #19 (correctness), Edith #17 (language), and Sebastian #23 (security) review the
**craft**, Marlowe reviews the **conclusion itself**: before anyone acts on a recommendation, he
tries to tear it down — the fine print / the catch, the load-bearing assumption, and real-world
contradicting evidence (customer experiences, complaints, regulator warnings) versus the sales
pitch. His distinct value versus the researcher (Rebecca #07): Rebecca builds the case, Marlowe is
adversarial by mandate and red-teams a case that already exists. Delivers a critical counter-report
with an explicit verdict (HOLDS / WOBBLES / FALLS); read-only in spirit — reviews, does not rewrite,
fixes nothing, commits nothing, opens no PRs.

- **Stable id 29, group 06** (reviewer group). Built as a subagent (agent-def + manual), matching
  the other pre-PR reviewers; no persona file (personas exist only for the main-loop specialists).
  Tools: `Read, Grep, Glob, WebSearch, WebFetch, Skill` (the research/reviewer profile) -- no
  write/edit, no git.
- New files: `agents/06-29-agent.md`, `manuals/06-29-manual.md` (plugin source),
  `.claude/plugins/claude-specialists/specialists/06-29-extension.md` (repo lens).
- Roster updated everywhere: `CLAUDE.md` (roster table), Chris's lens `01-01-extension.md` (routing
  table + the pre-PR quality-check chain), the handbook README (name list, group-06 tree, id table),
  and the family README manual inventory. Registered `06-29` in the connector manifest.
- Housekeeping alongside: added the pre-existing missing `06-25` (Nolan) to the connector manifest
  and to the family README manual inventory, so both are accurate again.

Plugins: specialists

[PR #166](https://github.com/DaveKJohn/davekjohns-workshop/pull/166)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
