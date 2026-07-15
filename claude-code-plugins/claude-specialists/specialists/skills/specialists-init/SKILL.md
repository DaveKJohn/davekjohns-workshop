---
name: specialists-init
description: >-
  Bootstrap het Claude-Specialists-systeem in een nieuwe consumerende repo: zet de orchestrator
  (Chris) en de hoofdloop-persona's (Derek, Rendall) op via de @-import in CLAUDE.md, kopieer hun
  draagbare sjablonen naar .claude/extensions/, en zet een governance-/safety-hooks-voorstel neer.
  Gebruik dit wanneer de gedeelde `specialists`-plugin wél is ingeschakeld maar de dirigent en de
  governance-laag nog ontbreken ("de werkers zijn er, Chris niet").
---

# specialists-init — het adoptiepad voor een nieuwe consument

De gedeelde `specialists`-plugin levert de **werker-subagents** (Sylvester, Tessa, Edith, Victor,
Tycho, …). Wat een plugin **niet** kan, is altijd-aan-hoofdloop-context injecteren of de `CLAUDE.md`
van een consument bewerken. Precies daar zit het gat: **Chris** (de orchestrator) en de andere
hoofdloop-persona's (**Derek**, **Rendall**) worden geladen via een `@`-import onderaan de
repo-`CLAUDE.md`, plus de governance- en safety-laag die per repo verschilt. Deze skill dicht dat gat.

## Kip-en-ei — stap 0 doet de gebruiker zelf

Deze skill zit ín de `specialists`-plugin. Een plugin-skill is pas beschikbaar nadat de repo de
plugin heeft ingeschakeld **en de sessie is herstart**. De skill kan zichzelf dus niet aanhaken.
Stap 0 is daarom handmatig — controleer dat de consument dit al heeft in `.claude/settings.json`:

```jsonc
"extraKnownMarketplaces": {
  "davekjohns-workshop": { "source": { "source": "github", "repo": "DaveKJohn/davekjohns-workshop" } }
},
"enabledPlugins": {
  "specialists@davekjohns-workshop": true
  // plus een domein-plugin naar keuze, bv. "specialists-shopify@davekjohns-workshop": true
}
```

Staat dat er niet, zet het er dan eerst in, **herstart de sessie**, en roep deze skill daarna opnieuw
aan. Staat het er wel, ga door.

## Wat de skill doet

Draai het bijgeleverde bootstrap-script vanuit de **root van de consumerende repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/skills/specialists-init/bootstrap.ps1"
```

Het script doet alleen **veilige, additieve** handelingen — het overschrijft nooit bestaande inhoud:

1. **Persona-sjablonen** — kopieert `${CLAUDE_PLUGIN_ROOT}/personas/<g>-<id>-persona.md` naar
   `.claude/extensions/<g>-<id>-extension.md` van de consument (Chris `01-01`, Derek `05-05`,
   Rendall `05-06`), alleen als die er nog niet staat.
2. **De `@`-import** — zorgt dat `CLAUDE.md` onderaan `@.claude/extensions/01-01-extension.md`
   draagt; maakt een minimale `CLAUDE.md`-scaffold als die ontbreekt.
3. **Settings-voorstel** — schrijft `.claude/settings.suggested.jsonc` met de aanbevolen
   `permissions.deny` + een hooks-**stub**. Het raakt `settings.json` **niet** aan: een JSON-merge is
   repo-specifiek en risicovol, dus die beoordeling blijft bij jou.

## Afronden (handmatig — de oordeelskundige stappen)

Na het script:

1. **Vul de repo-lens.** Elk gekopieerd `*-extension.md` heeft een `## Eigen aan deze repo (VUL-IN)`-slot.
   Vervang dat door de repo-eigen context: het roster/de routing (Chris), de branch-/PR-conventies
   (Derek), het release-mechaniek (Rendall). De draagbare body erboven laat je staan — de drift-lint
   van de marketplace bewaakt die tegen de canonieke bron.
2. **Neem de settings over.** Kopieer uit `.claude/settings.suggested.jsonc` wat past naar
   `settings.json` (of `settings.local.json`), pas de hooks-stub aan naar echte repo-scripts (of laat
   ze weg), en verwijder daarna het voorstel-bestand.
3. **Schrijf de governance.** De `CLAUDE.md`-scaffold is kaal — vul de safety-rules en de
   werkwijze van deze repo aan (zie een bestaande consument als model).
4. **Herstart de sessie.** De nieuwe `@`-import en config worden pas actief bij een **herstart** van
   Claude Code.

## Belangrijk

- **Niet overschrijven.** Bestaat een `*-extension.md` of de `@`-import al, dan laat het script het
  met rust. De skill is veilig herhaald aan te roepen.
- **De persona's zijn sjablonen, geen subagents.** Ze hebben bewust geen agent-def; ze draaien in de
  hoofdloop. Wijzig de draagbare body niet lokaal — een bodywijziging landt eerst in de marketplace
  (`personas/`), niet in een consument (net als een gedeelde agent-def).
