### Redistribute root README content across family/connectors/releases READMEs + new CONTRIBUTING.md · Docs · 2026-07-23

The root `README.md` had grown to carry family-specific mechanics that broke its own "family
mechanics belong in the family README" rule. Moved out of root: "Manuals — the split model"
(merged into the family README as the single canonical explanation of manual/agent-def/persona-template,
replacing three near-duplicate versions across root, the family README, and the Specialists handbook),
"Shared agent-def blocks", "Where this runs: Chat, Cowork, and Claude Code", "How we use skills —
and what we deliberately don't", "Adoption: the bootstrap path" (next to the existing Quickstart
pointer), and "Adding a new plugin group" — all five now live in the family
README (`claude-code-plugins/claude-specialists/README.md`); "Maintenance: drift lint" moved into
`connectors/README.md`, consolidated with its existing drift/persona-drift sections instead of
duplicating them; "Cutting a release" and the scripty part of "Versioning" moved into
`releases/README.md` with proper section anchors; "Contributing — changelog & PR workflow" moved
into a new root `CONTRIBUTING.md`. The root README itself is slimmed to a short TOC (intro, plugin
families, what lives here, a shortened repo layout, a shortened consumption section, a short
versioning fact + link, a short contributing pointer, and a closing "Want to know more?" block) with
every internal/external cross-reference into the moved sections repointed to its new home
(`CLAUDE.md`, `CHANGELOG.md`, `QUICKSTART.md`, and the family README's own self-references included).