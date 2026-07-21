# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#contributing--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #118 · new-branch.ps1: branch creation immediately scaffolds its changelog entry · Feat · 2026-07-21

Branch creation now brings its changelog entry into being in the same move — a branch is never entry-less. Added a shared, Derek-bound `scripts/task/new-branch.ps1` that validates the branch name via `branch-info.ps1` (new additive `Test-BranchName` helper), creates the branch (idempotent `git -C` checkout/checkout -b, no `Set-Location`), and immediately scaffolds the changelog entry by calling `new-changelog-entry.ps1` as a child process. Promoted `new-changelog-entry.ps1` to a dual-context, mirrored shared script (resolves its repo root via `CLAUDE_PROJECT_DIR`, dot-sources `branch-info.ps1` from the repo root, with a #86 pre-flight); registered both scripts in `shared-scripts-lib.ps1` and generated their plugin mirrors. Added the `/specialists:new-branch` skill, and updated Derek's persona + the workflow docs (Derek/Rendall/Tessa lenses, plugin scripts README, root README) so "a branch creates its entry at creation time" is the rule and the separate later step is gone. Consumer seam: the shared script does only git + entry (no push/PR, idempotent), so a consumer like smartwatchbanden can call it first and layer its own step (e.g. a Shopify preview theme) on top. Tests: new `new-branch.tests.ps1` plus extended `shared-scripts` and `branch-info` suites; lint and all suites green.

Plugins: specialists

[PR #118](https://github.com/DaveKJohn/davekjohns-workshop/pull/118)

---

### #117 · English names for agent-shared blocks + script-comment translations · Docs · 2026-07-21

Completed the in-progress English-norm cleanup of the agent-shared machinery. Renamed the four verbatim-shared source blocks to English file names (`grens-inbound` → `inbound-behaviour`, `gedrag-taalkeuze` → `language-behavior`, `grens-webcontent` → `webcontent-boundary`, `grens-artifact-publish` → `artifact-publishing-boundary`) and pulled the whole chain along: the `shared:<name>` sentinels in all 21 agent defs across the three plugins, the generator-lib docstring, and the current-doc references in `README.md` and Ravi's lens. Also folded in the NL→EN comment translation of `connector-sessioncheck.ps1` and `bootstrap.ps1`. Functional/canonical markers deliberately keep their original form per the language convention's technical-identifier exception — the `VUL-IN` scaffold sentinel and a couple of marker phrases the drift tests key on stay as-is. History (`CHANGELOG.md` files, `releases/`) is left untouched. Generator, lint (0 errors), and all test suites are green.

Plugins: agent-shared, specialists, specialists-lifehub, specialists-shopify

[PR #117](https://github.com/DaveKJohn/davekjohns-workshop/pull/117)

---

### #116 · Add Nolan #25, the Performance Engineer (token/context frugality) · Feat · 2026-07-21

Added a new portable specialist to the Claude Specialists: **Nolan ⚡ #25 — Performance Engineer** (`@specialists:nolan`, stable id `06-25`, group 06). Nolan is a measure-and-advise role for token/context frugality: he measures what each session, agent def, manual, and loading chain costs, and proposes where it can come down without losing function. He reports findings and does not commit, edit, or open PRs himself — execution runs through Ravi #24 (DRY dedup), Sylvester #15 (harness/config), and Tessa #16 (doc-text rewrite). New portable manual (`manuals/06-25-manual.md`) and agent def (`agents/06-25-agent.md`) on the plugin side, a davekjohns-workshop repo lens (`06-25-extension.md`), and roster/routing updates in `CLAUDE.md`, Chris's lens, and the Specialists handbook.

Plugins: specialists

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

Plugins: specialists

[PR #115](https://github.com/DaveKJohn/davekjohns-workshop/pull/115)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.12.1] - 2026-07-20 — Patch

Zie [releases/development/1.12/1.12.1.md](releases/development/1.12/1.12.1.md) voor de volledige release-notes.

---

### [v1.12.0] - 2026-07-20 — Minor

Zie [releases/development/1.12/1.12.0.md](releases/development/1.12/1.12.0.md) voor de volledige release-notes.

---

### [v1.11.0] - 2026-07-20 — Minor

Zie [releases/development/1.11/1.11.0.md](releases/development/1.11/1.11.0.md) voor de volledige release-notes.

---

### [v1.10.0] - 2026-07-19 — Minor

Zie [releases/development/1.10/1.10.0.md](releases/development/1.10/1.10.0.md) voor de volledige release-notes.

---

### [v1.9.2] - 2026-07-19 — Patch

Zie [releases/development/1.9/1.9.2.md](releases/development/1.9/1.9.2.md) voor de volledige release-notes.

---

### [v1.9.1] - 2026-07-19 — Patch

Zie [releases/development/1.9/1.9.1.md](releases/development/1.9/1.9.1.md) voor de volledige release-notes.

---

### [v1.9.0] - 2026-07-19 — Minor

Zie [releases/development/1.9/1.9.0.md](releases/development/1.9/1.9.0.md) voor de volledige release-notes.

---

### [v1.8.0] - 2026-07-18 — Minor

Zie [releases/development/1.8/1.8.0.md](releases/development/1.8/1.8.0.md) voor de volledige release-notes.

---

### [v1.7.0] - 2026-07-18 — Minor

Zie [releases/development/1.7/1.7.0.md](releases/development/1.7/1.7.0.md) voor de volledige release-notes.

---

### [v1.6.0] - 2026-07-18 — Minor

Zie [releases/development/1.6/1.6.0.md](releases/development/1.6/1.6.0.md) voor de volledige release-notes.

---

### [v1.5.2] - 2026-07-18 — Patch

Zie [releases/development/1.5/1.5.2.md](releases/development/1.5/1.5.2.md) voor de volledige release-notes.

---

### [v1.5.1] - 2026-07-18 — Patch

Zie [releases/development/1.5/1.5.1.md](releases/development/1.5/1.5.1.md) voor de volledige release-notes.

---

### [v1.5.0] - 2026-07-17 — Minor

Zie [releases/development/1.5/1.5.0.md](releases/development/1.5/1.5.0.md) voor de volledige release-notes.

---

### [v1.4.1] - 2026-07-16 — Patch

Zie [releases/development/1.4/1.4.1.md](releases/development/1.4/1.4.1.md) voor de volledige release-notes.

---

### [v1.4.0] - 2026-07-16 — Minor

Zie [releases/development/1.4/1.4.0.md](releases/development/1.4/1.4.0.md) voor de volledige release-notes.

---

### [v1.3.0] - 2026-07-16 — Minor

Zie [releases/development/1.3/1.3.0.md](releases/development/1.3/1.3.0.md) voor de volledige release-notes.

---

### [v1.2.0] - 2026-07-16 — Minor

Zie [releases/development/1.2/1.2.0.md](releases/development/1.2/1.2.0.md) voor de volledige release-notes.

---

### [v1.1.1] - 2026-07-15 — Patch

Zie [releases/development/1.1/1.1.1.md](releases/development/1.1/1.1.1.md) voor de volledige release-notes.

---

### [v1.1.0] - 2026-07-15 — Minor

Zie [releases/development/1.1/1.1.0.md](releases/development/1.1/1.1.0.md) voor de volledige release-notes.

---

### [v1.0.0] - 2026-07-14 — Major

Zie [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) voor de volledige release-notes.
