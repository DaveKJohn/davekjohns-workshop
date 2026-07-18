### Specialisten-handboek verplaatst naar het plugin-familie-niveau · Docs · 2026-07-18

Na de plugin-pad-migratie stond het specialisten-handboek los op `.claude/README.md`, terwijl de
lenzen die het indexeert naar `.claude/plugins/claude-specialists/specialists/` waren verhuisd. Het
handboek is nu verplaatst naar het familie-niveau, pal boven de lenzen:
**`.claude/plugins/claude-specialists/README.md`**.

- Verplaatst via `git mv`; de interne links hersteld — de lens-links worden **same-dir**
  (`specialists/<id>-extension.md`), de root-links (`CLAUDE.md`, `README.md`) en `settings.json`
  op de nieuwe diepte. Weergave-tekst overal met de targets in overeenstemming gebracht.
- De verwijzingen naar het handboek bijgewerkt in `CLAUDE.md` (2 links + de structuur-regel) en in
  Tessa's lens.
- **`check-plugin-integrity.ps1` valideert nu ook de links van het handboek** — die coverage-gap
  bestond al toen het op `.claude/README.md` stond; de move maakt de links complexer, dus ze worden
  voortaan bewaakt.

Lint (incl. de nieuwe handboek-scan) + alle testsuites groen.
