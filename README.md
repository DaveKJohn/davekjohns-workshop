# claude-specialists

Standalone marketplace-repo die het **Claude-Specialists-systeem** huisvest, opgedeeld in **drie
plugins**: de gedeelde, draagbare kern plus twee domein-groepen. Deze repo is de **single source of
truth** voor alle deelbare subagent-definities — elke consumerende repo wijst ernaar toe in plaats
van eigen kopieën te onderhouden, en schakelt **per plugin aan of uit** welke groepen hij nodig
heeft.

## De drie groepen

Het systeem kent drie groepen specialisten, elk in een eigen plugin:

| Plugin | Groep | Voor wie | Subagents |
|---|---|---|---|
| `specialists` | **1 · globaal** | elke repo | Paula, Rebecca, Vera, Gwen, Cody, Tycho, Sylvester, Tessa, Edith, Victor |
| `specialists-lifehub` | **2 · life-hub-achtig** | persoonlijke informatie-hub / brain-gebaseerde kennisrepo | Astrid, Fiona, Hugo, Ian, Onyx |
| `specialists-shopify` | **3 · Shopify** | Shopify-store-repo (bv. smartwatchbanden) | Liam, Sandra, Steven |

Een consumerende repo schakelt **groep 1 altijd in**, plus de domein-groep die bij hem past:

- **life-hub** → `specialists` + `specialists-lifehub`
- **smartwatchbanden** → `specialists` + `specialists-shopify`
- **een nieuwe repo** → `specialists` + de passende domein-plugin (of alleen de kern, als geen domein past)

### Groep 1 — repo-neutraal

Groep 1 (`specialists/agents/*.md`) is **repo-neutraal** geschreven: geen repo-naam, geen
teamgenoot-namen, geen repo-specifieke paden of scriptnamen. Het exacte platform/tech, de
teamgenoten en de vak-conventies van een specialist staan in de manual van de consumerende repo
(`.claude/manuals/<group>-<id>-manual.md`) — de agent-def verwijst daar zelf naar.

### Groep 2 & 3 — bewust domein-gekleurd

De domein-groepen (`specialists-lifehub/`, `specialists-shopify/`) zijn juist **niet** neutraal: ze
noemen hun repo, hun teamgenoten en hun vak-context expliciet. Dat mag, want alleen de repo waar het
domein bij past schakelt die plugin in — een Shopify-repo krijgt Ian/Onyx nooit te zien, en een
life-hub-achtige repo krijgt Liam/Sandra/Steven nooit te zien.

## Wat hier wél en niet woont

**Wél:** de drie plugin-mappen met uitsluitend **subagent-definities**.

**Niet:** governance (`CLAUDE.md`, `.claude/manuals/*`), safety-hooks of MCP-config. Die blijven
bewust op repo-niveau, want ze zijn per repo verschillend (of veiligheidskritisch). De plugins
dragen ook bewust **geen hooks** — alleen subagents (groep 2/3 mogen wél domein-skills meedragen als
een repo die deelt). De **volledige vakboeken** (`.claude/manuals/<group>-<id>-manual.md`) van álle
specialisten — ook die van groep 1 — blijven in de consumerende repo; alleen de compacte,
uitvoerbare agent-def verhuist naar deze marketplace.

## Aanroep

Zodra een repo deze marketplace toevoegt en een plugin inschakelt, worden de subagents daarin
genamespaced aanroepbaar met het **plugin** als namespace, niet de groep:

- groep 1 → `@specialists:<naam>` (bv. `@specialists:rebecca`)
- groep 2 → `@specialists-lifehub:<naam>` (bv. `@specialists-lifehub:ian`)
- groep 3 → `@specialists-shopify:<naam>` (bv. `@specialists-shopify:liam`)

## Consumptie

Een consumerende repo voegt deze marketplace toe via `extraKnownMarketplaces` in
`.claude/settings.json` en schakelt de gewenste plugins in via `enabledPlugins`. Beide huidige
consumenten (life-hub en smartwatchbanden) gebruiken een remote **`github`-marketplace-source**
(`"source": "github", "repo": "DaveKJohn/claude-specialists"`) — machine-onafhankelijk, want de
Claude Code CLI clonet en cachet dit repo zelf; een verse clone van de consumerende repo krijgt de
plugins zonder handmatige lokale stap.

```jsonc
// .claude/settings.json (consumerende repo)
"extraKnownMarketplaces": {
  "claude-specialists": {
    "source": { "source": "github", "repo": "DaveKJohn/claude-specialists" }
  }
},
"enabledPlugins": {
  "specialists@claude-specialists": true,          // groep 1 — altijd
  "specialists-lifehub@claude-specialists": true   // óf specialists-shopify@… , naar keuze
}
```

Een nieuw ingeschakelde plugin is pas in een **volgende** Claude Code-sessie zichtbaar.

## Versiebeheer

Elke plugin (`specialists/…`, `specialists-lifehub/…`, `specialists-shopify/…`) draagt een eigen
`version` in zijn `plugin.json`. Wijzigingen aan een gedeelde agent-def landen hier eerst, worden
hier gecommit, en pas daarna door de consumerende repo's opgehaald — nooit andersom (geen repo mag
een gedeelde agent-def lokaal overschrijven zonder dat hier terug te leggen).

## Onderhoud: drift-lint

Via de `github`-marketplace-source clonet en cachet de Claude Code CLI dit repo zelf voor elke
consument, dus is er geen fysieke kopie in de consumerende repo nodig en dus ook geen sync-stap —
elke consument consumeert letterlijk dezelfde bestanden. Uit een overgang kan een consumerende repo
echter nog een verouderde lokale kopie van een agent-def hebben die inmiddels hier gedeeld is.
[`scripts/lint/check-consumer-drift.ps1`](scripts/lint/check-consumer-drift.ps1) vergelijkt zo'n
lokale kopie (read-only, wijzigt niets) met de canonieke versie hier en meldt `MISSING` (al
gemigreerd), `IDENTICAL` (dode kopie, veilig te verwijderen) of `DRIFTED` (eerst bekijken vóór
verwijderen). Opruimen zelf gebeurt in de consumerende repo, niet door dit script.

```powershell
./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\pad\naar\life-hub
./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\pad\naar\smartwatchbanden
```
