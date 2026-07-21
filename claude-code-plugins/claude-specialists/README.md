# claude-specialists — the specialists family

The first product family of [davekjohns-workshop](../../README.md): the **Claude Specialists system**,
designed by Dave (DaveKJohn). Instead of one generic Claude, you work with a **team of specialized
Claudes** under one Chief of Staff: every assignment is classified and delivered to the specialist
(subagent) with the right playbook — a DevOps engineer for branches and PRs, a technical writer
for docs, a copy editor for the final pass, and so on.

This directory contains **three plugins** that together make up that system. A consuming repo
enables or disables them **individually** via the marketplace.

## The three sub-plugins — what's the difference?

| Plugin | What it is | Who it's for |
|---|---|---|
| [`specialists/`](specialists/) | **The shared core (group 1).** Eleven repo-neutral specialists who work the same way in *every* repo (research, systems administration, technical writing, copy editing, code review, security review, and testing, among others). Also carries the persona templates of the main loop (Chris/Derek/Rendall) and the bootstrap skill `specialists-init`. | **Every** consuming repo — this is the foundation, always enable it. |
| [`specialists-lifehub/`](specialists-lifehub/) | **Domain group 2.** Five specialists for a personal information hub / brain-based knowledge repo (Astrid, Fiona, Hugo, Ian, Onyx). Deliberately domain-flavored: they know their repo and teammates by name. | Only a life-hub-style repo. |
| [`specialists-shopify/`](specialists-shopify/) | **Domain group 3.** Three specialists for a Shopify store repo (Liam · Liquid, Sandra · store management, Steven · configuration) plus the domain skill `start-task`. Also deliberately domain-flavored. | Only a Shopify repo (e.g. smartwatchbanden). |

In short: **`specialists` is the foundation; the other two are optional domain extensions**, of
which a repo needs at most one. The core is written repo-neutrally (no repo names, paths, or script
names — that context comes from the consumer's repo lens); the domain groups name their domain
explicitly, because only a matching repo enables them.

## Agent def vs. manual — two files, one specialist

Every specialist in these plugins consists of two files, each with its own job:

- **`agents/<group>-<id>-agent.md` — the agent definition**, the executable form. The frontmatter
  (`name`, `description`, `tools`, `model`) is what Claude Code reads to register the subagent;
  the `description` is also the routing signal the main loop uses to pick a subagent. The body is
  deliberately just a compact operational core (working method, boundaries, deliverable format) and
  refers to the playbook for the actual craft.
- **`manuals/<group>-<id>-manual.md` — the playbook**, the full description of the craft: the
  hard rules, the trade-offs behind them, and the personality & tone. It is read on demand — by the
  subagent itself when in doubt, and by the main loop (the orchestrator that assigns the work and
  the personas that are not subagents).

**The manual is leading; the agent def is the executable abbreviation.** You change a craft rule in
the manual; you only touch the agent def when the operational core or the tool set changes. The two
are kept deliberately separate: they serve different readers (the harness vs. humans and the main
loop), the router-critical `description` and tool set should not sway along with every textual
refinement, and the portable-vs-repo-lens model (see
[Manuals — the split model](../../README.md#manuals--the-split-model) in the root README)
relies on manuals as standalone, lintable documents. Moreover, the manual format is the common
denominator across the whole team: the persona-only specialists (Chris, Derek, Rendall) have no
agent def, but do have a full playbook as a template in `personas/`.

## Invocation

Once enabled, the specialists can be invoked with the **plugin name as namespace**:
`@specialists:<name>`, `@specialists-lifehub:<name>`, or `@specialists-shopify:<name>`.

## Which release am I on?

Every plugin folder carries a `RELEASE.md` card (version, a one-line summary, and the entries for
that version) right next to its `CHANGELOG.md`. It travels with the plugin cache, so once
`claude plugin update` has pinned your install to a version, the cached copy of `RELEASE.md` is
exactly that release — open it under the plugin path in your own cache to see which one you're on.
See [Consumption](../../README.md#consumption) in the root README for the mechanics.

## Want to know more?

**Connecting your own repo?** Follow the [Quickstart](QUICKSTART.md) — connect in three steps, for
those who didn't build the system.

How a repo consumes these plugins (marketplace source, `enabledPlugins`), how the split manual
model works, and how the bootstrap adoption path (`specialists-init`) gets a fresh repo going is
covered in the workshop's [root README](../../README.md).
