# `specialists/scripts/` — het gedeelde thuis van de workflow-scripts (in opbouw)

Deze map is het toekomstige **single source of truth**-thuis van de repo-agnostische workflow-scripts,
zodat consumenten (life-hub, smartwatchbanden, de workshop zelf) ze niet langer per repo dupliceren.
De aanleiding staat in [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81).

> **Status: alleen de structuur staat er.** In deze fase is bewust nog géén script verplaatst — de
> map + de lint-bewaking zijn het fundament. De daadwerkelijke verhuizing volgt in een latere stap,
> zodra de aanroep-mechaniek gekozen is (zie hieronder).

## Wat hier straks woont — en wat niet

Een script hoort hier alleen als het **repo-agnostisch** is (geen repo-naam, geen CI-afhankelijkheid).
Repo-eigen data blijft in de consument, in `scripts/repo-config.ps1` (repo-naam, blob-URL, e.d.), en
wordt door het gecentraliseerde script ingelezen via `${CLAUDE_PROJECT_DIR}` — dat pad resolvet altijd,
ook in plugin-context.

**Blijft bewust in de root van de consument** (kan hier dus níét heen):

- Alles wat **CI** aanroept vanaf een kale checkout zónder plugin-cache (de lint-poort, de testsuites
  en hun libs). CI ziet de plugin-cache niet.
- **`branch-info.ps1` kan niet mee.** Hij is aan de root vastgeklonken door twee onafhankelijke
  aanroepers: `release-lib.ps1` dot-sourcet hem (voor de branch-typen, `Get-BranchTypes`) en draait in
  **CI** vanaf een kale checkout — én het root-script `open-pr.ps1` dot-sourcet hem. Zolang `release-lib`
  van `branch-info` afhangt, zou verplaatsen de CI-poort breken. Merk op: `${CLAUDE_PLUGIN_ROOT}`
  resolvet sowieso alléén binnen plugin-eigen componenten, niet in een root-script.

## Open ontwerpkeuze vóór de eerste verhuizing

Een script dat een mens/agent direct aanroept (zoals `new-changelog-entry.ps1`) moet vanuit de plugin
bereikbaar blijven. Het native `bin/`-mechanisme (auto-PATH, kaal aanroepbaar) bestaat, maar is voor
deze Windows/PowerShell-repo op drie punten nog onbevestigd: `bin/` staat op de PATH van de
**Bash-tool** (niet de PowerShell-tool waarmee onze `.ps1` draait) en een **mens kan het niet direct**
aanroepen; Windows `.ps1`-als-kaal-commando vergt een `.cmd`-shim waarvan de docs het gedrag niet
bevestigen; en of een `bin/`-executable `${CLAUDE_PROJECT_DIR}` krijgt (nodig om de root-libs te
bereiken) is evenmin gedocumenteerd. De enige door de docs bevestigde mechaniek die zowel een mens
(`/naam`) als Claude kan aanroepen, is een **skill** die het script via `${CLAUDE_PLUGIN_ROOT}` draait.

Daarom blijft de verhuizing (Fase 2) bewust uitgesteld. De volledige afweging staat in
[issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81) (zie het Fase 2-addendum).

## Precedent

De plugin draait al `hooks/connector-sessioncheck.ps1` via `hooks/hooks.json` met `${CLAUDE_PLUGIN_ROOT}`
in élke consument, zónder registratie in het consument-`settings.json`. Dat hook-mechanisme is bewezen;
de aanroep-mechaniek voor los aan te roepen scripts (`bin/` vs. een skill) ligt nog open — zie de
ontwerpkeuze hierboven.
