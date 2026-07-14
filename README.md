# claude-specialists

Standalone marketplace-repo die het **Claude-Specialists-systeem** huisvest, opgedeeld in **drie
plugins**: de gedeelde, draagbare kern plus twee domein-groepen. Deze repo is de **single source of
truth** voor alle deelbare subagent-definities — elke consumerende repo wijst ernaar toe in plaats
van eigen kopieën te onderhouden, en schakelt **per plugin aan of uit** welke groepen hij nodig
heeft.

## De drie groepen

Het systeem kent drie groepen specialisten, elk in een eigen plugin:

| Plugin | Groep | Voor wie | Inhoud |
|---|---|---|---|
| `specialists` | **1 · globaal** | elke repo | Paula, Rebecca, Vera, Gwen, Cody, Tycho, Sylvester, Tessa, Edith, Victor |
| `specialists-lifehub` | **2 · life-hub-achtig** | persoonlijke informatie-hub / brain-gebaseerde kennisrepo | Astrid, Fiona, Hugo, Ian, Onyx |
| `specialists-shopify` | **3 · Shopify** | Shopify-store-repo (bv. smartwatchbanden) | Liam, Sandra, Steven + de domein-skill `start-task` |

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

**Wél:** de drie plugin-mappen met **subagent-definities** (`agents/`); voor een gemigreerde
domein-groep ook het **draagbare vakboek** (`manuals/<group>-<id>-manual.md`) dat de agent-def via
`${CLAUDE_PLUGIN_ROOT}/manuals/` inleest.

**Niet:** governance (`CLAUDE.md`, de workflow-regels), safety-hooks of MCP-config. Die blijven
bewust op repo-niveau, want ze zijn per repo verschillend (of veiligheidskritisch). De plugins
dragen ook bewust **geen hooks** — alleen subagents (groep 2/3 mogen wél domein-skills meedragen als
een repo die deelt).

### Manuals — het gesplitste model

Een specialist-vakboek valt uiteen in een **draagbaar** deel (repo-neutraal, identiek in elke repo:
het vak, de harde regels, de toon) en een **repo-lens** (het `## Eigen aan deze repo`-deel: wélke
content/context van díe repo de specialist bedient). Het draagbare deel woont in
`<plugin>/manuals/<group>-<id>-manual.md` in deze marketplace; de consumerende repo houdt alleen de
lens in `.claude/extensions/<group>-<id>-extension.md`. De agent-def verwijst naar beide.

**Alle drie de groepen zijn inmiddels gemigreerd** — elk vakboek woont hier in de `manuals/`-map van
zijn plugin, en elke consumerende repo houdt daarvan enkel nog de repo-lens in `.claude/extensions/`:

- **`specialists` (groep 1)** → `specialists/manuals/` (Paula, Rebecca, Vera, Gwen, Cody, Tycho,
  Sylvester, Tessa, Edith, Victor).
- **`specialists-lifehub` (groep 2)** → `specialists-lifehub/manuals/` (Astrid, Fiona, Hugo, Ian, Onyx).
- **`specialists-shopify` (groep 3)** → `specialists-shopify/manuals/` (Liam, Sandra, Steven).

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

## Bijdragen — changelog & PR-workflow

Wijzigingen aan dit repo gaan via een branch + Pull Request naar `master`, met een gevouwen
changelog-entry — dezelfde workflow als de consumerende repo's. De stappen:

1. **Branch** met een `<prefix>/<korte-naam>`-naam. Geldige prefixes (prefix → label → changelog-type):
   `feat/` → enhancement → Feat · `fix/` → bug → Fix · `docs/` → documentation → Docs ·
   `chore/` → documentation → Chore (onderhoud: scripts, tooling, config). De tabel staat in
   [`scripts/lib/branch-info.ps1`](scripts/lib/branch-info.ps1).
2. **Changelog-entry aanmaken:** [`scripts/release/new-changelog-entry.ps1`](scripts/release/new-changelog-entry.ps1)`-Title "…"`
   maakt `<branch-naam>.md` in de repo-root met kop + datum + type al ingevuld; vul de beschrijving in.
3. **Werk + commit** op de branch (entry-bestand meecommitten).
4. **PR openen:** [`scripts/release/open-pr.ps1`](scripts/release/open-pr.ps1)`-Title "…"` draait eerst
   de **lint-poort** [`scripts/lint/check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1)
   (geldige manifesten, agent-def-frontmatter, geen dode links); bij een error wordt er niet gepusht en
   geen PR geopend. Slaagt de poort, dan pusht het script en opent de PR met label + auto-ingevulde body.
5. **Merge** (op Dave's woord).
6. **Folden:** op `master`, direct na de merge,
   [`scripts/release/fold-changelog-entry.ps1`](scripts/release/fold-changelog-entry.ps1)`-Branch <naam>`
   vouwt het entry-bestand in de `## Pull Requests`-sectie van [`CHANGELOG.md`](CHANGELOG.md) (met
   `#NN` + PR-link) en verwijdert het entry-bestand; commit dat rechtstreeks op `master`.

Versiebeheer loopt per plugin via de `version` in elke `plugin.json` (zie [Versiebeheer](#versiebeheer));
een repo-brede release-pijplijn (versie-bump, tags, GitHub Releases) is bewust **nog buiten scope**.
