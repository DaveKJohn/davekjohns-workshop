### Bootstrap-adoptiepad: persona-sjablonen + specialists-init-skill · Feat · 2026-07-14

Dicht het adoptie-/bootstrap-gat: een verse repo die de `specialists`-plugin inschakelt kreeg wél de
werker-subagents, maar niet de dirigent (Chris) of de governance-/hooks-laag — die kunnen niet uit
een plugin komen (een plugin injecteert geen hoofdloop-context en bewerkt geen `CLAUDE.md`).
Opgelost via een hybride C+A:

- **C — canonieke bron.** Nieuwe map `specialists/personas/` met self-contained sjablonen voor de
  hoofdloop-persona's (Chris `01-01`, Derek `05-05`, Rendall `05-06`): draagbare body + een
  repo-lens-placeholder. Bewust géén agent-def (persona's draaien in de hoofdloop, niet als subagent).
- **A — levering.** Repo-neutrale skill `specialists/skills/specialists-init/` met `bootstrap.ps1`:
  kopieert de sjablonen naar `.claude/extensions/<g>-<id>-extension.md` (nooit overschrijven), zet de
  `@`-import onderaan `CLAUDE.md`, en schrijft een `settings.suggested.jsonc` (`permissions.deny` +
  hooks-stub; raakt `settings.json` niet aan). Documenteert de kip-en-ei stap 0 + de herstart-les.
- **Lint.** `check-plugin-integrity.ps1` valideert nu persona-frontmatter + bestandsnaam (check 3c),
  neemt personas mee in de link/anchor-scan, en parse-checkt ook plugin-skill-scripts; sectie 6 laat
  persona's bewust met rust. `check-consumer-drift.ps1` vergelijkt daarnaast de draagbare persona-body
  tegen de consument-kopie (informatief — telt niet mee in de exit-code).
- **Docs.** `README.md` (persona-artefact + sectie "Adoptie: het bootstrap-pad" + drift-uitleg),
  `CLAUDE.md` (structuur) en `.claude/README.md` (persona-representatie) bijgewerkt. `plugin.json`
  erkent de repo-neutrale skill als bewuste uitzondering op "geen skills".

Niet-brekend geverifieerd: lint groen, drift-lint tegen life-hub én smartwatchbanden toont 0 gedrifte
agent-defs (persona's informatief `DRIFTED` — de handgeschreven kopieën, later gecoördineerd te
reconciliëren). Bootstrap end-to-end + idempotentie getest tegen een verse wegwerp-consument.
