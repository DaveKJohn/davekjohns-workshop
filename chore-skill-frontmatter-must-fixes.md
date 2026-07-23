### Harden open-pr invocation control and fix sync-roster description person · Chore · 2026-07-23

Applies the two must-fixes from Sylvester's own skill audit. `open-pr`'s `SKILL.md`
(`claude-code-plugins/claude-specialists/specialists/skills/open-pr/SKILL.md`) gets
`disable-model-invocation: true` in its frontmatter, removing the autonomous Skill-tool invocation
surface in support of the constitution rule that a PR is only opened on Dave's explicit word — the
same pattern `start-task` already uses in the Shopify family. Note this only closes the Skill-tool
path; a direct Bash call to `scripts/release/open-pr.ps1` or the plugin mirror is not gated by this
field, so the actual guarantee remains the CLAUDE.md constitution rule plus branch discipline.

`sync-roster`'s `SKILL.md`
(`claude-code-plugins/claude-specialists/specialists/skills/sync-roster/SKILL.md`) gets its
description rewritten from second person ("for you to paste", "you want ... done for you") to third
person, same content, matching the style of every other skill description. Verified: the lint gate
(`check-plugin-integrity.ps1`) accepts the new field with no findings, and neither description is
duplicated elsewhere in the repo (plugin.json, generated mirrors, or drift-lint fixtures).