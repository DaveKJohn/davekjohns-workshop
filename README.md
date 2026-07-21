# davekjohns-workshop

The **workshop of Dave (DaveKJohn)**: the marketplace repo where all of his Claude Code plugins are
built and maintained — designed by a human, executed with his team of specialists. The first
product family is the **Claude Specialists system** in
[`claude-code-plugins/claude-specialists/`](claude-code-plugins/claude-specialists/), split into **three plugins**: the shared,
portable core plus two domain groups. This repo is the **single source of truth** for all shareable
subagent definitions — every consuming repo points to it instead of maintaining its own copies, and
enables or disables **per plugin** which groups it needs.

## The plugin families

Every plugin family lives in its own folder under `claude-code-plugins/`, with its **own README**
that explains what the family does and how its sub-plugins differ. For now there is one family:

- **[`claude-specialists/`](claude-code-plugins/claude-specialists/README.md)** — the
  Claude Specialists system: the shared, repo-neutral core `specialists` (group 1, for every
  repo) plus the two deliberately domain-flavored groups `specialists-lifehub` (group 2) and
  `specialists-shopify` (group 3). Which specialists sit in which sub-plugin, who they are
  meant for, and how to invoke them is in that README — this file doesn't repeat it.

## What lives here and what doesn't

**Does live here:** the three plugin folders with **subagent definitions** (`agents/`); for a
migrated domain group also the **portable playbook** (`manuals/<group>-<id>-manual.md`) that the
agent def reads in via `${CLAUDE_PLUGIN_ROOT}/manuals/`. Group 1 additionally carries two things
that cover the **main-loop layer** (see [Adoption: the bootstrap path](#adoption-the-bootstrap-path)): the
**persona templates** (`personas/<group>-<id>-persona.md`) of the orchestrator + main-loop specialists
(Chris, Bianca, Derek, Rendall), and the **repo-neutral bootstrap skill** `specialists-init`.

**Doesn't:** governance (`CLAUDE.md`, the workflow rules), safety hooks, or MCP config. Those stay
at repo level deliberately, because they differ per repo (or are safety-critical). The plugins
deliberately carry **no safety/guardrail hooks** and **no repo-specific skills** — with a few named,
repo-neutral exceptions: the skill `specialists-init` (the adoption path itself) and two
informational, read-only SessionStart hooks that never block — `connector-sessioncheck` (sync
signaling) and `roster-sessioncheck` (roster-drift signaling; see the
[connectors README](claude-code-plugins/claude-specialists/connectors/README.md)); domain groups
2/3 may carry domain skills that a repo shares.

### Manuals — the split model

A specialist handbook splits into a **portable** part (repo-neutral, identical in every repo: the
craft, the hard rules, the tone) and a **repo lens** (the `## Specific to this repo` part: which
content/context of that repo the specialist serves). The portable part lives in
`<plugin>/manuals/<group>-<id>-manual.md` in this marketplace; the consuming repo keeps only the
lens in `.claude/plugins/claude-specialists/specialists/<group>-<id>-extension.md`. The agent def points to both.

**All three groups have now been migrated** — every handbook lives here in the `manuals/` folder of
its plugin, and every consuming repo keeps only its repo lens in `.claude/plugins/claude-specialists/specialists/`:

- **`specialists` (group 1)** → `claude-code-plugins/claude-specialists/specialists/manuals/` (Paula, Rebecca, Vera, Gwen, Cody, Tycho,
  Sylvester, Tessa, Edith, Victor, Sean, Ravi).
- **`specialists-lifehub` (group 2)** → `claude-code-plugins/claude-specialists/specialists-lifehub/manuals/` (Astrid, Fiona, Hugo, Ian, Onyx).
- **`specialists-shopify` (group 3)** → `claude-code-plugins/claude-specialists/specialists-shopify/manuals/` (Liam, Sandra, Steven).

**Persona templates — a third artifact alongside agent def and manual.** The orchestrator and the
main-loop specialists (Chris #01, Bianca #02, Derek #05, Rendall #06) run in the **main loop**, not as
subagents — a plugin cannot inject always-on main-loop context, and an intake conversation moreover
requires direct back-and-forth with the client. They therefore deliberately have
**no** agent def; their portable source lives in `claude-code-plugins/claude-specialists/specialists/personas/<group>-<id>-persona.md` as a
**self-contained template** (portable body + a repo-lens placeholder). The consumer loads the
**portable body straight from the plugin install** via an `@` import in its `CLAUDE.md` (the
orchestrator always, the other personas on demand). The local extension
`.claude/plugins/claude-specialists/specialists/<group>-<id>-extension.md` is therefore **lens-only**:
only the repo-specific `## Specific to this repo` part, no body copy. The [drift lint](#maintenance-drift-lint)
recognizes such a lens-only extension and reports it as `LENS-ONLY`. The lint's agent-def↔manual
coupling deliberately leaves personas alone (they have no agent def).

### Shared agent-def blocks — one source for the verbatim boundaries

A number of bullets under **Grenzen** (the boundaries section) are word-for-word identical across
many agent defs — the **inbound rule** even across all 19. Such governance belongs *in* the
agent-def body (always loaded, also for a directly invoked worker subagent), but Claude Code has no
native transclusion in an agent def — what's written there is there, literally. To still maintain
those blocks in **one place** instead of in every agent def, a **build-and-lint** model applies:

- The canonical text of each shared block lives in
  `claude-code-plugins/claude-specialists/agent-shared/<name>.md`.
- In an agent def the block appears between sentinels:
  `<!-- BEGIN shared:<name> … -->` … `<!-- END shared:<name> -->`. The content really is there (self-contained), but is marked as generated.
- **Never edit between the sentinels.** Change the source file and run
  [`scripts/agents/build-agent-defs.ps1`](scripts/agents/build-agent-defs.ps1) — all agent defs
  carrying the block are updated. The [lint gate](#maintenance-drift-lint) (`check-plugin-integrity.ps1`,
  check 7) fails as soon as a marked region deviates from its source (a hand edit or a forgotten
  rebuild), just like the drift lint for consumers.

Current blocks: `inbound-behaviour` (19 agent defs), `webcontent-boundary` (3), and `artifact-publishing-boundary`
(2). This way changing a shared boundary costs one edit + one build, not 19 manual
changes.

## Consumption

A consuming repo adds this marketplace via `extraKnownMarketplaces` in
`.claude/settings.json` and enables the desired plugins via `enabledPlugins`. Both current
consumers (life-hub and smartwatchbanden) use a remote **`github` marketplace source**
(`"source": "github", "repo": "DaveKJohn/davekjohns-workshop"`) — machine-independent, because the
Claude Code CLI clones and caches this repo itself; a fresh clone of the consuming repo gets the
plugins without a manual local step.

```jsonc
// .claude/settings.json (consuming repo)
"extraKnownMarketplaces": {
  "davekjohns-workshop": {
    "source": { "source": "github", "repo": "DaveKJohn/davekjohns-workshop" }
  }
},
"enabledPlugins": {
  "specialists@davekjohns-workshop": true,          // group 1 — always
  "specialists-lifehub@davekjohns-workshop": true   // or specialists-shopify@… , as needed
}
```

A newly enabled plugin only becomes visible in the **next** Claude Code session.

**Seeing which release you're on — `RELEASE.md`.** Each plugin folder carries a `RELEASE.md` card
(version + date/type, a one-line summary, and the entries for that version) that travels with the
plugin cache exactly like its `CHANGELOG.md`. Because `claude plugin update` pins the cache to a
specific version (see [Versioning](#versioning)), the cached `RELEASE.md` copy is always *exactly*
the installed release — a consumer opens it under the plugin path in their own cache to see which
release they're on, without cross-referencing this workshop's own `releases/` history.

**One canonical channel — mind the old repo name.** The marketplace is named `davekjohns-workshop`
(repo `DaveKJohn/davekjohns-workshop`) and that is the only channel; use that name in
`extraKnownMarketplaces` (as above). This repo used to be named `claude-specialists`: that old
name keeps pointing to the same repo via a **GitHub rename redirect**, so a marketplace still
registered under `claude-specialists` refers to exactly the same repo — there is **no
second source** to mirror to. However, the local marketplace clone of such an old registration can
lag behind (it was once cloned at an older commit and doesn't converge to the new
`HEAD` on its own), so an install on that channel silently yields an older plugin version. If you
run into this: update the marketplace registration (a marketplace update) or re-add it under
`davekjohns-workshop` — a fresh install should always use `DaveKJohn/davekjohns-workshop`.

## Adoption: the bootstrap path

> **New here?** The shareable beginner route is in the
> [Quickstart](claude-code-plugins/claude-specialists/QUICKSTART.md) — get connected in three steps,
> for those who didn't build the system. Below is the underlying explanation.

Enabling the plugin delivers the **worker subagents**, but not the **conductor** (Chris) or the
governance/hooks layer — those cannot come from a plugin (a plugin injects no
main-loop context and edits no `CLAUDE.md`). The skill **`specialists-init`** (group 1) closes that
gap in a consuming repo. Because a plugin skill cannot hook itself in, the path is
two-stage:

- **Step 0 (manual).** Put the marketplace source + `enabledPlugins` in `.claude/settings.json`
  (see [Consumption](#consumption)) and **restart** the session — only then is the skill available.
- **Step 1 (the skill).** Invoke `specialists-init`. The bundled
  [`bootstrap.ps1`](claude-code-plugins/claude-specialists/specialists/skills/specialists-init/bootstrap.ps1) performs only **additive**
  actions: it copies the persona templates to `.claude/plugins/claude-specialists/specialists/<group>-<id>-extension.md`
  (never overwriting), places an **empty lens scaffold** for every subagent of the enabled
  plugin(s) (`VUL-IN` — the spot where repo-specific tasks per specialist are
  filled in), adds the `@.claude/plugins/claude-specialists/specialists/01-01-extension.md` import at the bottom of `CLAUDE.md`
  (or creates a scaffold), and writes a `settings.suggested.jsonc` with a `permissions.deny` +
  hooks **stub**. It does not touch `settings.json` — that merge and filling in the repo lens are
  manual work afterwards (repo-specific), after which one more **restart** activates the new context.

## Versioning

Every plugin (`claude-code-plugins/claude-specialists/specialists/…`, `claude-code-plugins/claude-specialists/specialists-lifehub/…`, `claude-code-plugins/claude-specialists/specialists-shopify/…`) carries its own
`version` in its `plugin.json`. On a release those versions move **in lockstep** — they all get the
same number and one repo-wide tag `vX.Y.Z` (see [Cutting a release](#cutting-a-release)).
**That version number is also the update gate**: `claude plugin update` compares nothing but
version numbers, so a consuming repo (including this repo itself, which consumes itself) only pulls
in merged changes after the `version` has been bumped — a merge without a release stays invisible
to consumers. So if work must propagate to consumers, a release belongs with it
(on Dave's explicit request, as always).
On every release, `cut-release.ps1` also (re)generates each plugin's `RELEASE.md` card from that
plugin's lockstep version + its own changelog entries, so the two artifacts always move together —
the lint gate ([`scripts/lint/check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1),
check 9) guards that the card is present and its version matches `plugin.json`.
Changes to a shared agent def land here first, are committed here, and only then picked up by the
consuming repos — never the other way around (no repo may overwrite a shared agent def locally
without contributing it back here).

## Maintenance: drift lint

Through the `github` marketplace source, the Claude Code CLI clones and caches this repo itself for
every consumer, so no physical copy in the consuming repo is needed and thus no sync step either —
every consumer literally consumes the same files. Left over from a transition, however, a consuming
repo may still have an outdated local copy of an agent def that is by now shared here.
[`scripts/lint/check-consumer-drift.ps1`](scripts/lint/check-consumer-drift.ps1) compares such a
local copy (read-only, changes nothing) with the canonical version here and reports `MISSING`
(already migrated), `IDENTICAL` (dead copy, safe to remove), or `DRIFTED` (inspect first before
removing). The cleanup itself happens in the consuming repo, not by this script.

The same script also compares the **personas**: it lays the portable body of each
`personas/<group>-<id>-persona.md` next to the body of the consumer copy in
`.claude/plugins/claude-specialists/specialists/<group>-<id>-extension.md` (everything above the `## Specific to this repo` marker; the
repo lens below it differs per repo and is not compared). Those persona findings are
**informational** — they don't count toward the exit code, because a consumer with a handwritten
persona is by definition `DRIFTED` until it has been reconciled in a coordinated way.

```powershell
./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\path\to\life-hub
./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\path\to\smartwatchbanden
```

## Contributing — changelog & PR workflow

Changes to this repo go through a branch + Pull Request to `main`, with a folded
changelog entry — the same workflow as the consuming repos. The steps:

1. **Branch — its changelog entry comes along in the same move:**
   [`scripts/task/new-branch.ps1`](scripts/task/new-branch.ps1)`-Name <prefix>/<short-name> -Title "…"`
   creates (or idempotently resumes) the `<prefix>/<short-name>` branch and, as a child step,
   scaffolds `<branch-name>.md` in the repo root (heading + date + type already filled in) via
   [`scripts/release/new-changelog-entry.ps1`](scripts/release/new-changelog-entry.ps1) — a branch is
   never entry-less. Valid prefixes (prefix → label → changelog type): `feat/` → enhancement → Feat ·
   `fix/` → bug → Fix · `docs/` → documentation → Docs · `chore/` → documentation → Chore
   (maintenance: scripts, tooling, config). The table is in
   [`scripts/lib/branch-info.ps1`](scripts/lib/branch-info.ps1).
2. **Work + commit** on the branch: write the entry file's description, then commit it along with
   the rest of the work.
3. **Open the PR:** [`scripts/release/open-pr.ps1`](scripts/release/open-pr.ps1)`-Title "…"` first runs
   the **lint gate** [`scripts/lint/check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1)
   (valid manifests, agent-def frontmatter, no dead links) and then the **test gate** (all
   `scripts/tests/*.tests.ps1`, exactly as CI does); on an error or a failing suite nothing is pushed and
   no PR is opened. If both gates pass, the script pushes and opens the PR with label + auto-filled body.
   The same gate also runs as **CI** on GitHub ([`.github/workflows/ci.yml`](.github/workflows/ci.yml):
   lint + all test suites, on every PR and every push to `main`) — so a PR created outside the
   scripts still passes through it all the same.
4. **Merge** (on Dave's word).
5. **Fold:** on `main`, right after the merge,
   [`scripts/release/fold-changelog-entry.ps1`](scripts/release/fold-changelog-entry.ps1)`-Branch <name>`
   folds the entry file into the `## Pull Requests` section of [`CHANGELOG.md`](CHANGELOG.md) (with
   `#NN` + PR link), derives a `Plugins:` line from the PR's files along the way (for the per-plugin
   CHANGELOGs — see [Cutting a release](#cutting-a-release)), and removes the entry file;
   commits that directly on `main`.

### Cutting a release

A release is a **captured moment**: all three plugins get the same version number
(**lockstep, repo-wide**) and the state is tagged as `vX.Y.Z`. Nothing is published to GitHub Releases
— only a git tag, the full notes in [`releases/`](releases/README.md), and a reference to them in
[`CHANGELOG.md`](CHANGELOG.md). A release is cut **only on Dave's explicit
request** and deliberately does **not** go through a branch + PR: like the fold commit, the
release commit is a permitted direct-on-`main` action (the second exception to "everything via
branch + PR").

In one motion, on a clean `main`:
[`scripts/release/cut-release.ps1`](scripts/release/cut-release.ps1)`(-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"]`

1. bumps all `plugin.json` versions in lockstep to `X.Y.Z`;
2. generates the full release notes in `releases/development/<X.Y>/<X.Y.Z>.md` (from the folded
   `## Pull Requests` entries, per branch type), adds a row to `releases/README.md`, and places in
   `CHANGELOG.md` a reference under `## Releases` (the Pull Requests section is emptied down to its intro);
3. appends, per plugin, the entries that touched that plugin (selected via the `Plugins:` line that
   the fold derives from the PR's files; as internal bookkeeping, the line itself doesn't travel along)
   to the **per-plugin `CHANGELOG.md`**, and regenerates that plugin's **`RELEASE.md`** card (version,
   one-line summary, and the entries for that version) — both consumer-facing artifacts that travel
   along with the plugin cache;
4. commits that directly on `main` (`release: vX.Y.Z`) and sets an annotated tag `vX.Y.Z`;
5. pushes `main` + the tag (unless `-NoPush` for inspection first).

Guardrails: a clean `main`, no unfolded entry files, lint gate green, tag doesn't exist yet.
The pure logic (version bump, CHANGELOG transformation, notes construction) lives in
[`scripts/lib/release-lib.ps1`](scripts/lib/release-lib.ps1) and is covered by
[`scripts/tests/release-lib.tests.ps1`](scripts/tests/release-lib.tests.ps1).
