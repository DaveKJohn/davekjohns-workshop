# claude-specialists

Standalone marketplace-repo die de **gedeelde, draagbare kern** van het Claude-Specialists-systeem
huisvest: de subagent-definities die feitelijk identiek zijn in meerdere repo's (momenteel
life-hub + smartwatchbanden). Deze repo is de **single source of truth** voor die gedeelde kern —
elke consumerende repo wijst ernaar toe in plaats van een eigen kopie te onderhouden.

## Wat hier wél en niet woont

**Wél:** de plugin `specialists/`, met daarin uitsluitend de **10 gedeelde subagent-definities**
(`specialists/agents/*.md`). Elke agent-def is repo-neutraal geschreven: geen repo-naam, geen
teamgenoot-namen, geen repo-specifieke paden of scriptnamen. Het exacte platform/tech, de
teamgenoten en de vak-conventies van een specialist staan in de manual van de consumerende repo
(`.claude/manuals/<group>-<id>-manual.md`) — de agent-def verwijst daar zelf naar.

**Niet:** governance (`CLAUDE.md`, `.claude/manuals/*`), safety-hooks, MCP-config, of
repo-specifieke specialisten/skills. Die blijven bewust op repo-niveau, want ze zijn per repo
verschillend (of veiligheidskritisch) en horen niet in een gedeelde, generieke plugin. Deze plugin
draagt ook bewust **geen hooks en geen skills** — alleen subagents.

## De 10 gedeelde subagents

| # | Naam | Rol |
|---|---|---|
| 02-09 | Paula 📅 | Projectplanner |
| 03-07 | Rebecca 🔬 | Research Specialist |
| 04-11 | Vera 📊 | Data-analist |
| 04-12 | Gwen 🎨 | Grafisch & Front-end Ontwerper |
| 04-13 | Cody 💻 | App-ontwikkelaar |
| 04-18 | Tycho 🧪 | Test Engineer |
| 05-15 | Sylvester ⚙️ | Systeembeheerder |
| 06-16 | Tessa 📜 | Technical Writer |
| 06-17 | Edith 🔍 | Eindredacteur |
| 06-19 | Victor 🧐 | Code Reviewer |

Repo-eigen specialisten (bv. life-hub's Bianca/Ian/Onyx/Fiona/Astrid/Hugo, of swb's Liam/Sandra/
Steven) horen hier nooit thuis — die blijven agent-defs op repo-niveau in de consumerende repo zelf.

## Aanroep

Zodra een repo deze marketplace toevoegt en de plugin inschakelt, worden deze subagents
genamespaced aanroepbaar als `@specialists:<naam>` (bv. `@specialists:rebecca`), in plaats van de
bare naam die gold toen de agent-def nog los in de consumerende repo stond.

## Consumptie

Een consumerende repo voegt deze marketplace toe via `extraKnownMarketplaces` in
`.claude/settings.json` en schakelt de plugin in via `enabledPlugins`. Bootstrap-fase: consumptie
loopt via een **lokale `directory`-marketplace-source** (deze repo lokaal gecloond naast de
consumerende repo) — dat vermijdt een live cross-account git-dependency tijdens het opzetten.
Zodra trust en account-toegang op de betrokken machine(s) gevalideerd zijn, kan dit promoveren naar
een remote `github`-marketplace-source, zodat een verse clone van de consumerende repo de plugin
zonder handmatige lokale stap kan ophalen.

## Versiebeheer

`specialists/.claude-plugin/plugin.json` draagt een eigen `version`. Wijzigingen aan een gedeelde
agent-def landen hier eerst, worden hier gecommit, en pas daarna door de consumerende repo's
opgehaald — nooit andersom (geen repo mag een gedeelde agent-def lokaal overschrijven zonder dat
hier terug te leggen).

## Onderhoud: drift-lint

Zolang life-hub en swb via een lokale `directory`-marketplace-source rechtstreeks naar deze
checkout wijzen, is er geen fysieke kopie nodig en dus ook geen sync-stap — beide consumeren
letterlijk dezelfde bestanden. Tijdens de overgang (Fase 3) kan een consumerende repo echter nog
een eigen, verouderde lokale kopie hebben van een agent-def die inmiddels hier gedeeld is.
[`scripts/lint/check-consumer-drift.ps1`](scripts/lint/check-consumer-drift.ps1) vergelijkt zo'n
lokale kopie (read-only, wijzigt niets) met de canonieke versie hier en meldt `MISSING` (al
gemigreerd), `IDENTICAL` (dode kopie, veilig te verwijderen) of `DRIFTED` (eerst bekijken vóór
verwijderen). Opruimen zelf gebeurt in de consumerende repo, niet door dit script.

```powershell
./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\pad\naar\life-hub
./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\pad\naar\smartwatchbanden
```
