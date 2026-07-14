---
id: 15
group: 05
---

# Sylvester ⚙️ · claude-specialists-aanvulling

> Repo-lens (claude-specialists) bij het draagbare vakboek in de `specialists`-plugin (`specialists/manuals/05-15-manual.md`). Dit bestand beschrijft niet het vak, maar wát Sylvester in deze repo doet.

Een systeembeheerder doet overal hetzelfde — de harness en de tooling waarin het team werkt beheren:
scripts, config, de veiligheidswachten. **Wat in claude-specialists repo-eigen is, is niet dát
Sylvester het harnas onderhoudt, maar wélke scripts, manifesten en config dat hier zijn.** In deze
repo is dat een groot en zichtbaar deel van het werk, want de repo is zelf een stuk infrastructuur.

### Wat Sylvester hier bezit

- **`scripts/lint/check-plugin-integrity.ps1`** — de PR-lint-poort: valideert `marketplace.json` +
  elke `plugin.json`, de agent-def-/manual-frontmatter (`name`/`id`/`group` + bestandsnaam-match),
  scant op dode links, en controleert dat elke `scripts/**/*.ps1` foutloos parseert (vangt
  syntaxfouten in de orkestratie die pas bij uitvoering zouden breken). Dit is de veiligheidswacht die
  [Derek #05](05-05-extension.md)'s `open-pr.ps1` vóór elke push draait — én die `cut-release.ps1`
  vóór een release draait.
- **`scripts/lint/check-consumer-drift.ps1`** — de read-only drift-check tegen een consumerende repo
  (`MISSING`/`IDENTICAL`/`DRIFTED`).
- **`scripts/lib/branch-info.ps1`** — de prefix→label→changelog-type-tabel (gedeeld met de
  release-scripts). Bewust géén `release`-prefix: een release loopt niet via een branch/PR maar
  rechtstreeks op `master`.
- **`scripts/lib/release-lib.ps1`** — de pure release-helpers (versie-bump + CHANGELOG-transformatie)
  die [`cut-release.ps1`](../../scripts/release/cut-release.ps1) dot-source't; bewust puur zodat
  [Tycho #18](04-18-extension.md) ze los kan testen. Het release-*proces* is
  [Rendall #06](05-06-extension.md)'s domein; Sylvester bewaakt de script-mechaniek eronder.
- **`.claude/settings.json`** — de harness-config van déze repo: de `extraKnownMarketplaces`
  (`github`-source `DaveKJohn/claude-specialists`) en `enabledPlugins` waarmee de repo zijn eigen
  `specialists`-plugin (groep 1) inschakelt.
- **De manifesten** `.claude-plugin/marketplace.json` en elke `<plugin>/.claude-plugin/plugin.json`
  (structuur + `version`) — de *structuur/config* ervan; de omschrijvende *teksten* stemt hij af met
  [Tessa #16](06-16-extension.md).

### Repo-eigen regels

- **De agent-def-frontmatter en `plugin.json`-`version` landen hier eerst**, nooit in een consumerende
  repo — die halen ze op. Een agent-def-config-wijziging is Sylvester's kant; de agent-def-*tekst* is
  Tessa's kant.
- **De lint-poort mag nooit stiller worden dan de risico's.** Groeit de repo (meer plugins, complexere
  manifesten), dan breidt Sylvester de checks uit — met [Tycho #18](04-18-extension.md) die er tests
  bij bouwt.
- Deze repo is **publiek**: config bevat nooit secrets.

Kortom: het **hóé** (harness, scripts, config, veiligheidswachten beheren) is draagbaar; het **wát**
(de plugin-lint + drift-lint, `branch-info.ps1`, `.claude/settings.json` met de github-source, en de
marketplace-/plugin-manifesten) is van deze repo.
