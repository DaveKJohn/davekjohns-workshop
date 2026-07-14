### life-hub-domeingroep: draagbaar vakboek naar specialists-lifehub/manuals/, agent-defs verwijzen nu naar plugin + repo-extensie · Feat · 2026-07-14

Eerste stap in het gesplitste manual-model: het **draagbare** vakboek van een specialist verhuist naar de plugin, de **repo-lens** blijft als extensie in de consumerende repo. Uitgevoerd voor de domeingroep `specialists-lifehub` (Astrid, Fiona, Hugo, Ian, Onyx); groep 1 (`specialists`) en `specialists-shopify` volgen apart omdat die meerdere consumerende repo's tegelijk raken.

- `specialists-lifehub/manuals/{02-10,03-08,03-14,04-03,04-04}-manual.md` — nieuw: de 5 draagbare, repo-neutraal gemaakte vakboeken (het `## Eigen aan deze repo`-deel is eruit gehaald en woont nu als lens in `.claude/extensions/` van de consumerende repo).
- `specialists-lifehub/agents/*.md` (5) — de vakboek-verwijzing wijst nu naar `${CLAUDE_PLUGIN_ROOT}/manuals/<group>-<id>-manual.md` (in de plugin) plus `.claude/extensions/<group>-<id>.md` (repo-lens), i.p.v. het oude `.claude/manuals/<group>-<id>-manual.md`.
- `scripts/lint/check-plugin-integrity.ps1` — lint-poort uitgebreid: valideert nu ook `<plugin>/manuals/*-manual.md` (frontmatter `id`/`group` + bestandsnaam-match) en scant die manuals op dode relatieve links.
- `README.md` — sectie "Wat hier wél en niet woont" herschreven naar het gesplitste model (draagbaar deel in `manuals/`, repo-lens in `.claude/extensions/`), met de migratie-status per groep.
