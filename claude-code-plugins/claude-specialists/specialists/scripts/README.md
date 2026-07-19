# `specialists/scripts/` — gedeelde workflow-scripts (spiegel voor consumenten)

Deze map is het **single source of truth**-thuis van de repo-agnostische workflow-scripts, zodat
consumenten (life-hub, smartwatchbanden, …) ze niet langer per repo dupliceren. De aanleiding staat
in [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81).

**Het model — spiegel, geen verhuizing:**
- De **workshop-root-kopie is de canonieke, geteste bron** (`scripts/…` in deze repo). Daar wordt
  ontwikkeld en getest; CI draait die vanaf een kale checkout.
- De kopie **hier in de plugin is een LF-identieke spiegel** — dat is wat een **consument** draait
  (via een skill). De werkplaats zelf blijft zijn root-kopie gebruiken.
- Een **drift-lint** (`check-plugin-integrity.ps1`) bewaakt dat spiegel en bron gelijk blijven, en de
  generator `scripts/sync/build-shared-scripts.ps1` schrijft de spiegel bij. Zo erft de spiegel de
  testdekking van de root-kopie zónder dat we hem in de workshop live hoeven te draaien (dat kan niet:
  de werkplaats consumeert de laatst-gepushte plugin, niet je branch).

## Status

| Script | Status | Skill |
|---|---|---|
| `release/fold-changelog-entry.ps1` | **Gedeeld** (spiegel actief) | [`fold-changelog`](../skills/fold-changelog/SKILL.md) |
| `release/open-pr.ps1` | **Gedeeld** (spiegel actief; lint-gate via `Get-LintScript` in `repo-config`) | [`open-pr`](../skills/open-pr/SKILL.md) |

## Hoe de spiegel werkt

1. **Dual-context repo-root.** Een gedeeld script lost zijn repo-root op als
   `${CLAUDE_PROJECT_DIR}` (bij een consument die de spiegel draait) óf de git-root (workshop-root /
   buiten een sessie). Zo werkt dezelfde file in beide locaties en blijft de spiegel byte-identiek.
2. **Repo-data blijft lokaal.** Het script leest zijn repo-eigen blokje uit de **root van de
   consument**: `scripts/repo-config.ps1` (repo-naam) en `scripts/lib/branch-info.ps1`
   (branch-/type-afleiding). `${CLAUDE_PLUGIN_ROOT}` resolvet alléén binnen plugin-eigen componenten,
   dus die injectie loopt via `${CLAUDE_PROJECT_DIR}`, niet via de plugin-root.
3. **Consument roept aan via een skill** (`/fold-changelog`) die het script draait met
   `${CLAUDE_PLUGIN_ROOT}/scripts/release/…`. Een skill is de enige door de docs bevestigde mechaniek
   die zowel een mens als Claude kan aanroepen (`bin/` staat alleen op de PATH van de Bash-tool en is
   niet direct door een mens aan te roepen).

Een script toevoegen aan de gedeelde set: registreer het paar (bron → spiegel) in
`scripts/lib/shared-scripts-lib.ps1`, draai `scripts/sync/build-shared-scripts.ps1`, en voeg zo nodig
een skill toe.

## Wat bewust in de root van de consument blijft (kan hier níét heen)

- Alles wat **CI** aanroept vanaf een kale checkout zónder plugin-cache (de lint-poort, de testsuites
  en hun libs). CI ziet de plugin-cache niet.
- **`branch-info.ps1` kan niet mee.** Hij is aan de root vastgeklonken door twee onafhankelijke
  aanroepers: `release-lib.ps1` dot-sourcet hem (voor de branch-typen, `Get-BranchTypes`) en draait in
  **CI** vanaf een kale checkout — én de root-scripts dot-sourcen hem. Zolang `release-lib` van
  `branch-info` afhangt, zou verplaatsen de CI-poort breken.
- **`repo-config.ps1`** is per definitie repo-data (repo-naam, blob-URL) en hoort per repo lokaal.
  De `specialists-init`-bootstrap zet `repo-config.ps1` + `branch-info.ps1` als `VUL-IN`-scaffold neer,
  zodat een schone consument de gedeelde skills niet op een ontbrekend bestand stukloopt; de scripts
  pre-flighten er bovendien op ([#86](https://github.com/DaveKJohn/davekjohns-workshop/issues/86)).

## Precedent

De plugin draait al `hooks/connector-sessioncheck.ps1` via `hooks/hooks.json` met `${CLAUDE_PLUGIN_ROOT}`
in élke consument, zónder registratie in het consument-`settings.json`. Dat hook-mechanisme is bewezen;
de gedeelde-scripts-spiegel + skill hierboven breidt datzelfde SSOT-principe uit naar los aan te roepen
workflow-scripts.
