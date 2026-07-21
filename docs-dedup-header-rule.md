### Consolidate the visible-sender header rule: canonical in CLAUDE.md, pointer in Chris lens · Docs · 2026-07-21

The "visible sender" header rule was stated in full in two always-loaded places: `CLAUDE.md` and
Chris's repo lens `01-01-extension.md`. Consolidated to a single canonical statement in `CLAUDE.md`
(it is a repo-specific "hard rule from Dave", not a portable system concept, so it stays here rather
than moving to the portable persona body); the lens bullet becomes a short pointer back to it. The
rule stays fully in force and always loaded — `CLAUDE.md` is loaded automatically every session — so
this removes the verbatim duplication without weakening the rule or extending the agent-shared
generator to lenses. Ravi's analysis also corrected the earlier "threefold" assumption: the persona
body never carried the rule, so it was a twofold duplication.