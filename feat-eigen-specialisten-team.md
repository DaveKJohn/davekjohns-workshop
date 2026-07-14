### Repo consumeert nu zelf het specialisten-team (groep 1) + volwaardige CLAUDE.md · Feat · 2026-07-14

De marketplace-repo huisvestte het specialisten-systeem al, maar gebruikte het niet zelf. Nu schakelt
`claude-specialists` zijn eigen `specialists`-plugin (groep 1) in en krijgt hij een volwaardige
operating guide volgens hetzelfde model als life-hub: draagbare grondwet + team-framing bovenaan,
repo-lens onderaan. Het team is klein en toegespitst op het onderhoud van dít product (agent-defs,
manuals, docs, tooling), met Chris als orchestrator.

- `CLAUDE.md` — herschreven: van "bron, geen consument" naar een repo die door de Claude Specialists
  wordt bestuurd. Grondwet (safety-rules + werkwijze) + Chris-first-protocol + zichtbare-afzender-regel
  bovenaan; repo-slot met roster/routing, structuur en de `master`-safety-invulling onderaan. Laadt
  Chris auto in via `@.claude/extensions/01-01-extension.md`.
- `.claude/settings.json` — nieuw: `extraKnownMarketplaces` (`github`-source `DaveKJohn/claude-specialists`
  — de repo wijst naar zichzelf) + `enabledPlugins` (`specialists@claude-specialists`). Alleen groep 1;
  de domein-plugins passen niet bij deze repo.
- `.claude/extensions/` — nieuw: drie persona-manuals (Chris #01, Derek #05, Rendall #06, volledig want
  persona-only) + vijf groep-1-repo-lenzen (Sylvester #15, Tessa #16, Edith #17, Tycho #18, Victor #19),
  elk her-lensd naar de marketplace-context.
- `.claude/README.md` — nieuw: het specialisten-handboek (lay-out van `.claude/`, persona-vs-subagent,
  de manual-tweedeling, het `<group>-<id>`-systeem, het kleine team + index).
