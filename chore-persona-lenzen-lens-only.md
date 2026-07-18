### Persona-lenzen naar lens-only (body-duplicatie verwijderd) · Chore · 2026-07-18

De drie persona-lenzen (Chris 01-01, Derek 05-05, Rendall 05-06) droegen een bijna-volledige **kopie**
van hun draagbare body uit de plugin-sjablonen — ~168 regels duplicatie. Reden: de subagents laden hun
vak automatisch uit de plugin, maar de persona's draaien in de hoofdloop, waar dat niet automatisch
kan; daarom stond de body gekopieerd in de lens. Deze repo is echter net zo goed een **consument** als
life-hub, dus hij hoort hetzelfde **lens-only-model** te gebruiken.

Onderzocht (Rebecca, via life-hub's echte opzet) en toegepast:

- **`CLAUDE.md`** laadt Chris nu via **twee `@`-imports**: de draagbare body rechtstreeks uit de
  plugin-install (`@~/.claude/plugins/marketplaces/davekjohns-workshop/.../personas/01-01-persona.md`)
  én de repo-lens (`@.claude/plugins/claude-specialists/specialists/01-01-extension.md`).
- De **3 persona-lenzen zijn lens-only**: de body-kopie eruit (netto ~151 regels), een
  `> Repo-lens (lens-only persona)`-kop erin, en het repo-eigen `## Eigen aan deze repo`-deel
  (roster/routing/poortwachters) behouden. Derek en Rendall laden hun body on-demand van hetzelfde pad.
- De doc-beschrijvingen (het handboek + `README.md`) bijgewerkt van het oude kopie-model naar
  lens-only.

Zo woont elke draagbare gedragsregel op één plek (de plugin), net als bij de subagents. De body laadt
uit de plugin-cache (de laatst-gereleasede versie) — normaal consument-gedrag. Lint + alle testsuites
groen.
