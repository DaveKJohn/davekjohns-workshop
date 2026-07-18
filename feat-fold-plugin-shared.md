### Fase 2-pilot: fold-changelog gedeeld als plugin-spiegel (SSOT voor consumenten) · Feat · 2026-07-19

Eerste stap van Fase 2 uit [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81): `fold-changelog-entry.ps1` wordt gedeeld met consumenten als plugin-spiegel — geen verhuizing, de workshop houdt zijn eigen testbare root-kopie.

- **Dual-context repo-root** in `fold-changelog-entry.ps1`: lost de repo-root op via `${CLAUDE_PROJECT_DIR}` (consument die de spiegel draait) of de git-root (workshop). Dezelfde file werkt in beide locaties; `repo-config` wordt uit de repo-root geladen i.p.v. `$PSScriptRoot`.
- **Spiegel-mechaniek** naar het bestaande `build-agent-defs`-patroon: `scripts/lib/shared-scripts-lib.ps1` (register), `scripts/sync/build-shared-scripts.ps1` (generator met `-Check`), en een drift-lint-sectie in `check-plugin-integrity.ps1` die bewaakt dat de plugin-spiegel LF-identiek blijft aan de bron.
- **Consument-skill** `fold-changelog` draait de spiegel via `${CLAUDE_PLUGIN_ROOT}` — het enige door de docs bevestigde mechaniek voor mens én Claude.
- **Tests:** nieuwe suite `shared-scripts.tests.ps1` (register-contract, in-sync-invariant, dual-context-borging, `-Check`-poort).
- **Docs:** `specialists/scripts/README.md` herschreven naar de werkende spiegel-mechaniek + statusoverzicht.

`open-pr` volgt als losse stap (de lint/test-gate moet eerst via `repo-config` geparametriseerd worden).