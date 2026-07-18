---
id: 15
group: 05
---

# Sylvester ⚙️ · davekjohns-workshop-aanvulling

> Repo-lens (davekjohns-workshop) bij het draagbare vakboek in de `specialists`-plugin (`claude-code-plugins/claude-specialists/specialists/manuals/05-15-manual.md`). Dit bestand beschrijft niet het vak, maar wát Sylvester in deze repo doet.

Een systeembeheerder doet overal hetzelfde — de harness en de tooling waarin het team werkt beheren:
scripts, config, de veiligheidswachten. **Wat in davekjohns-workshop repo-eigen is, is niet dát
Sylvester het harnas onderhoudt, maar wélke scripts, manifesten en config dat hier zijn.** In deze
repo is dat een groot en zichtbaar deel van het werk, want de repo is zelf een stuk infrastructuur.

### Wat Sylvester hier bezit

- **`scripts/lint/check-plugin-integrity.ps1`** — de PR-lint-poort: valideert `marketplace.json` +
  elke `plugin.json`, de agent-def-/manual-frontmatter (`name`/`id`/`group` + bestandsnaam-match),
  scant op dode links (in `README.md`, `CHANGELOG.md`, de manuals, `SKILL.md`'s en `releases/**`), en
  controleert dat elke `scripts/**/*.ps1` foutloos parseert (vangt syntaxfouten in de orkestratie die
  pas bij uitvoering zouden breken), en bewaakt (check 7) dat elke gedeelde-blok-regio in een
  agent-def nog gelijk is aan zijn bron in `agent-shared/`. Dit is de veiligheidswacht die
  [Derek #05](05-05-extension.md)'s `open-pr.ps1` vóór elke push draait — én die `cut-release.ps1`
  vóór een release draait.
- **`.github/workflows/ci.yml`** — de CI-poort op GitHub: draait dezelfde lint-poort + alle
  testsuites (`scripts/tests/*.tests.ps1`) bij elke PR en elke push naar `main`, zodat de wacht ook
  geldt voor werk dat buiten `open-pr.ps1` om ontstaat. Sinds 15 juli 2026 dwingt de repo-ruleset
  **`main-ci-poort`** (GitHub → Settings → Rules) die poort af als **required status check**: een PR
  naar `main` mergt pas bij een groene `lint-en-tests`-job. De bypass-list (Repository admin + de
  Write-rol, "Always allow") houdt de directe fold-/release-commits op `main` mogelijk — het
  werk-account `davekokbwj` heeft write-rechten, geen admin. Die Write-bypass is veilig zolang er
  geen externe collaborators zijn en moet herzien worden zodra die er wél komen.
- **`scripts/lint/check-consumer-drift.ps1`** — de read-only drift-check tegen een consumerende repo
  (`MISSING`/`IDENTICAL`/`DRIFTED`).
- **`scripts/lib/branch-info.ps1`** — de prefix→label→changelog-type-tabel (gedeeld met de
  release-scripts). Bewust géén `release`-prefix: een release loopt niet via een branch/PR maar
  rechtstreeks op `main`.
- **`scripts/lib/release-lib.ps1`** — de pure release-helpers (versie-bump, CHANGELOG-transformatie
  naar een `## Releases`-verwijzing, en de opbouw van de `releases/development/`-notes) die
  [`cut-release.ps1`](../../../../scripts/release/cut-release.ps1) dot-source't; bewust puur zodat
  [Tycho #18](04-18-extension.md) ze los kan testen. Het release-*proces* is
  [Rendall #06](05-06-extension.md)'s domein; Sylvester bewaakt de script-mechaniek eronder.
- **`scripts/agents/build-agent-defs.ps1` + `scripts/lib/agent-shared-lib.ps1`** — de generator die
  de verbatim-gedeelde bullets uit `claude-code-plugins/claude-specialists/agent-shared/<naam>.md` in
  alle agent-defs invult (tussen `<!-- BEGIN/END shared:… -->`-sentinels). Wijzig een gedeeld blok →
  draai `build-agent-defs.ps1` → alle agent-defs bij; `-Check` (en de lint-poort, check 7) faalt bij
  drift. De pure expansie-logica woont in de lib, zodat [Tycho #18](04-18-extension.md) haar los kan
  testen — spiegelt de `release-lib`-opzet. **Nooit tussen de sentinels handmatig bewerken.**
- **`.claude/settings.json`** — de harness-config van déze repo: de `extraKnownMarketplaces`
  (`github`-source `DaveKJohn/davekjohns-workshop`) en `enabledPlugins` waarmee de repo zijn eigen
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
