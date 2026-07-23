### Record how the specialists system relates to Cowork and Skills · Docs · 2026-07-23

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
