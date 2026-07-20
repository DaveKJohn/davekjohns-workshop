# Quickstart — how to connect your repo

This page is for those who did **not** build the Claude Specialists system: a colleague with a repo
of their own who wants to work with the specialists team. Everything below is the common thread —
the deeper explanation sits behind the links and is deliberately not repeated here.

## What you get

Instead of one generic Claude, you work with a **team of specialized Claudes under one Chief of
Staff (Chris)**: every assignment is classified and delivered to the specialist with the right
playbook — a DevOps engineer for branches and PRs, a technical writer for docs, a copy editor
and code/security reviewers for the independent final pass before a PR or merge. Your repo stays in
charge: the governance (your `CLAUDE.md`, your safety rules) remains yours; the plugins only supply
the team and its playbooks.

The system consists of **three plugins**: the repo-neutral core `specialists` (group 1 — always
enable it) and two optional domain groups. Which specialists live in which plugin and who they are
meant for is covered in the [family README](README.md).

## Connecting in three steps

**Step 1 — enable the plugins.** In your repo's `.claude/settings.json`, set the marketplace source
and the plugins you want (always the core; a domain group only if your repo has that domain):

```jsonc
// .claude/settings.json (your repo)
"extraKnownMarketplaces": {
  "davekjohns-workshop": {
    "source": { "source": "github", "repo": "DaveKJohn/davekjohns-workshop" }
  }
},
"enabledPlugins": {
  "specialists@davekjohns-workshop": true
}
```

This repo is public, so the source can be read without GitHub authentication; Claude Code clones
and caches it by itself. **Then restart your Claude Code session** — only then are the plugins (and
the skill from step 2) available.

**Step 2 — run the bootstrap skill.** In the new session, invoke `specialists-init`. It sets up —
purely additively, without overwriting anything — the **lens-only** persona lenses (including
Chris) + an empty repo-lens scaffold per specialist on the **plugin path**
(`.claude/plugins/claude-specialists/<plugin>/`), the two Chris `@`-imports in your `CLAUDE.md`
(his portable body from the plugin install + his repo lens), and a proposal for safety settings
(`settings.suggested.jsonc`, for your own
review). The details of this path are in the
[root README › Adoption](../../README.md#adoption-the-bootstrap-path) — which counts the steps there
as "step 0" (the enabling above) and "step 1" (the skill).

**Step 3 — restart and verify.** Start again and check that Chris takes the floor (every turn opens
with a sender header such as `🧭 Chris — intake & routing`). Then, at your own pace, fill in the
repo lenses on the plugin path (`.claude/plugins/claude-specialists/<plugin>/`): that is where you tell each specialist what it serves in your repo.
The worker specialists can be invoked directly as `@specialists:<name>`.

## Staying up to date

Updates reach you via **releases**: `claude plugin update` compares version numbers only, so you
get changes as soon as the workshop has cut a new version — not before. Each plugin carries its own
`CHANGELOG.md` that travels with the plugin cache and describes per release what changed for that
plugin; the full history lives in the workshop itself
([`CHANGELOG.md`](../../CHANGELOG.md) and [`releases/`](../../releases/README.md)).

## Reporting back or improving something

- **An improvement to the shared core** (an agent def, playbook, persona, or skill): don't
  rework it locally, but report it as an issue on this repo with the label `inbound` — an
  [issue template](../../.github/ISSUE_TEMPLATE/inbound-verbeterpunt.md) is ready for that. The
  workshop processes it through its own chain, and the improvement comes back to all consumers via
  a release.
- **Repo-specific additions** belong in your own repo lenses on the plugin path
  (`.claude/plugins/claude-specialists/<plugin>/`) — those are yours and do not travel with the plugin.
