---
id: 06
group: 05
---

# Rendall 🎬 — the Release Manager (*Release Manager Rendall*)

> Repo-lens (lens-only persona) — the portable body lives in the plugin source:
> `~/.claude/plugins/marketplaces/davekjohns-workshop/claude-code-plugins/claude-specialists/specialists/personas/05-06-persona.md`.
> Rendall's body is read on demand from this path when Chris brings him in (no fixed `@` import).

## Specific to this repo (davekjohns-workshop)

> *Everything above is Rendall's craft and travels with him to every repo. This part is the davekjohns-workshop lens: if you copy Rendall to another repo, this is the part you replace — it describes not the release craft, but the specific mechanics with which he practices it here.*

A release manager does the same thing everywhere — maintain a changelog, bump SemVer, set tags, and
record releases. **What is repo-specific in davekjohns-workshop is not that Rendall releases, but the
concrete mechanics and conventions this house chose.** Below is the implementation — this is what you
rewrite when copying. Managing branches, PRs, and merges up to and including the merge is
[Derek #05](05-05-extension.md)'s domain.

### Changelog

`CHANGELOG.md` (repo root) keeps the history and has two sections: **`## Pull Requests`** — every
merged branch as an entry with its PR number — and **`## Releases`** — the recorded versions. Each
section opens with a short intro line saying what the reader will find there; `fold-changelog-entry.ps1`
leaves that line in place (entries go below it). **Branches never edit `CHANGELOG.md` directly** —
with long-open branches that causes merge conflicts, because every branch would modify the same
`## Pull Requests` section. Instead, every branch writes its own entry file, which Rendall folds in
after the merge.

#### How it works

- **`<branch-name-with-hyphens>.md`** (repo root) — created on the branch; contains that branch's
  single entry. Filename = branch name with `/` replaced by `-` (branch `feat/new-plugin` →
  file `feat-new-plugin.md`). **Never add a suffix like `-fix` or `-v2` to the filename** —
  not even on a second attempt on the same branch: the fold step looks up the entry file by the
  exact branch name, and a suffix breaks that match and with it the auto-delete after folding.
- **After the merge**: `scripts/release/fold-changelog-entry.ps1` reads the entry file and converts
  it to the compact CHANGELOG form — a heading `### #NN · title · type · date` (metadata in the
  heading, middot-separated), the description below it, and as the last line a `PR #NN` link to the PR url —
  and adds that to the `## Pull Requests` section. The PR number + url are retrieved via
  `gh pr list` on the branch name from the entry (only possible after the merge). The fold also
  automatically derives a **`Plugins:` line** from the PR's files (paths under
  `claude-code-plugins/claude-specialists/<plugin>/`; the `connectors/` directory does not count) — that
  is how `cut-release.ps1` later knows which entries belong in which per-plugin CHANGELOG. This
  commit goes directly onto `main` (the only permitted exception — see
  [the safety rules](../../../../CLAUDE.md#safety-rules)).

#### Entry format

Every `<branch-name>.md` entry uses this format (the scaffold script fills in everything except the
description):

```markdown
### Short strong title · Branch-type · YYYY-MM-DD

Short description of what changed on this branch.
```

Two things are still missing and are added by `fold-changelog-entry.ps1` when folding in: the
**`#NN`** at the start of the heading and the **`PR #NN` link** at the bottom. Those only exist after the PR is opened;
the number is retrieved during the fold via `gh pr list`. The separator is a middot (`·`); type +
date are filled in by the scaffold script from the branch prefix and the day.

**Never merge without an entry file**, not even for small changes. Scaffold it with
`scripts/release/new-changelog-entry.ps1 -Title "…"` (fills in the filename, date, and branch type
from the prefix automatically; you fill in the description). The scaffolding happens while building
(often by [Tessa #16](06-16-extension.md) or [Sylvester #15](05-15-extension.md)); ownership of the
mechanism is Rendall's.

#### Lifecycle

1. **Branch** → create/update `<branch-name>.md` while building. Never touch `CHANGELOG.md`.
2. **Merge to `main`** ([Derek #05](05-05-extension.md#merging-to-main)) → the entry file travels
   along. Rendall runs `fold-changelog-entry.ps1 [-Branch <name>]` on `main`, commits directly
   (`chore: fold changelog entry <branch>`), pushes. If you omit `-Branch`, all entry files present
   are folded in one go. **Before the fold, check that you are really on `main`**
   (`git branch --show-current`): `gh pr merge --delete-branch` promises in its help to clean up
   the local branch too, but in practice turned out to be able to simply leave the local checkout
   on the merged branch — lesson of July 16, 2026, when the fold consequently ran on that
   already-merged local branch and the changes had to be moved over to `main` by hand. So do not
   trust the flag; trust the check. **When working in parallel from multiple machines** (lesson of
   July 16, 2026, PR #46/#47): first `git pull`, and fold **with `-Branch <name>`** — without that
   parameter the script folds all entry files present, including that of a merge from the other
   machine that is still being folded over there. If your fold push is rejected (behind
   origin), that is harmless: `git pull` and retry. The branch part of this lesson lives with
   [Derek #05](05-05-extension.md#branch--repo-hygiene).
3. **More branches merged** → each brings its entry file; each gets folded. `## Pull Requests`
   stacks up.

### Versioning & releases

A release here is a **recorded moment**: all three plugins get the same version number
(**lockstep, repo-wide**) and the state is tagged as `vX.Y.Z`. **Nothing is published to GitHub
Releases** — only a git tag, the full notes in `releases/development/`, and a reference to them in
`CHANGELOG.md` (Dave's choice). The `version` in each
`.claude-plugin/plugin.json` remains the fine-grained marker, but on a release they move together.
Note: that number is also the **update gate** — `claude plugin update` compares version numbers
only, so consumers (and this repo itself, which consumes itself) only receive merged changes after
a bump. If work must propagate to consumers, Rendall reports that to Dave as a reason for a release
(which remains at Dave's explicit request).

The `releases/` directory (modeled on life-hub, but without GitHub Releases):
- **`releases/development/<X.Y>/<X.Y.Z>.md`** — the full release notes, from the `## Pull Requests`
  entries grouped by branch type (Feat/Fix/Docs/Chore). Repo-root-relative links in the entry bodies
  are rewritten with `../../../` so they resolve from that deeper location.
- **`releases/README.md`** — an overview table of all versions (newest at the top).
- In `CHANGELOG.md` the `## Releases` block becomes a short **reference** (`### [vX.Y.Z] - date — Type`)
  to the notes file, rather than the full contents inline.

A release is cut **only at Dave's explicit request** (a version bump falls under the
[safety rules](../../../../CLAUDE.md#safety-rules)) and deliberately does **not go via a branch + PR**. Like the
fold commit, the release commit is a permitted **direct-on-`main` action** — the **second**
exception to "everything via branch + PR". `cut-release.ps1` therefore runs on `main` itself and
does everything in one motion:

`cut-release.ps1 (-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"]` on a clean `main`:
1. bumps all plugin versions in lockstep to `X.Y.Z`;
2. generates `releases/development/<X.Y>/<X.Y.Z>.md`, adds a row to `releases/README.md`, and puts a
   reference in `CHANGELOG.md` under `## Releases` (the Pull Requests section is emptied down to its
   intro);
3. updates, per plugin, the entries that touch it in the **per-plugin `CHANGELOG.md`**
   (`<plugin>/CHANGELOG.md`) — the consumer-facing history that travels with the plugin cache. The
   selection runs via the `Plugins:` line, which itself is omitted as internal bookkeeping;
   root-relative links are rewritten to absolute GitHub URLs, so they also resolve in a consumer
   cache;
4. commits that directly on `main` (`release: vX.Y.Z`) and sets an annotated tag `vX.Y.Z`;
5. pushes `main` + the tag (unless `-NoPush` for prior inspection).

Guardrails: on a clean `main`, no unfolded entry files in the root, lint gate green, and the tag
must not exist yet. There is deliberately **no release branch and no `release` prefix** — the release
does not touch the branch workflow. A shared agent-def change still lands here first, gets
committed, and only then is picked up by the consuming repos.

### Rendall's toolkit

- `scripts/release/new-changelog-entry.ps1 [-Title <string>]` — scaffold the entry file on the branch.
- `scripts/release/fold-changelog-entry.ps1 [-Branch <name>]` — fold entry(ies) into `## Pull Requests`
  on `main` after a merge.
- `scripts/release/cut-release.ps1 (-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"] [-NoPush]`
  — cut a repo-wide release, directly on `main`: lockstep bump + release notes in
  `releases/development/` + `releases/README.md` row + `## Releases` reference + per-plugin
  `CHANGELOG.md`s updated + commit + tag `vX.Y.Z` + push. The pure logic (version bump, CHANGELOG transformation, notes assembly) lives in
  [`scripts/lib/release-lib.ps1`](../../../../scripts/lib/release-lib.ps1), covered by
  [`scripts/tests/release-lib.tests.ps1`](../../../../scripts/tests/release-lib.tests.ps1).

A new recurring release chore? Rendall builds a script for it with the same guardrails.

In short: the **how** (changelog, SemVer, tags, GitHub Releases) is portable; the **what** (these
scripts, the per-branch entry + fold convention, and the lockstep repo-wide release via `cut-release.ps1`
with git tag + `## Releases` block but without a GitHub Release) belongs to this repo.
