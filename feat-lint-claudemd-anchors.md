### Lint-poort: CLAUDE.md + .claude/extensions/ meegescand en anchor-validatie toegevoegd; drift-lint docstring gecorrigeerd · Feat · 2026-07-14

Uit de vergelijking met life-hub bleek dat de lint-poort juist de link-dichtste bestanden niet dekte.
Twee punten opgepakt:

- **Lint-poort uitgebreid** ([`check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1)):
  de dode-link-scan omvat nu ook `CLAUDE.md` en elke `.claude/extensions/*.md`, én er is
  **anchor-validatie** bijgekomen — een `[..](file.md#anchor)` of `[..](#anchor)` faalt de poort als
  die anchor niet als kop in het doelbestand bestaat (GitHub-slugregels, incl. duplicaat-suffixen en
  het overslaan van code-fences). Vangt nu 24 bestaande kruisverwijzings-anchors af; geverifieerd dat
  een bewust kapotte anchor wordt betrapt.
- **Drift-lint docstring gecorrigeerd** ([`check-consumer-drift.ps1`](scripts/lint/check-consumer-drift.ps1)):
  de topologie-beschrijving zei nog "lokale directory-marketplace-source", terwijl life-hub én swb de
  remote `github`-source gebruiken (zoals de README al beschrijft).

Voortgekomen uit het consistentie-onderzoek claude-specialists ↔ life-hub. Dat onderzoek bevestigde
ook dat groep 1 een schone gedeelde kern vormt voor beide consumenten (nul drift).