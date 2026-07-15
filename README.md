# davekjohns-workshop

De **werkplaats van Dave (DaveKJohn)**: de marketplace-repo waar al zijn Claude-Code-plugins worden
gebouwd en onderhouden — ontworpen door een mens, uitgevoerd met zijn team van specialisten. De
eerste product-familie is het **Claude-Specialists-systeem** in
[`claude-code-plugins/claude-specialists/`](claude-code-plugins/claude-specialists/), opgedeeld in **drie plugins**: de gedeelde,
draagbare kern plus twee domein-groepen. Deze repo is de **single source of truth** voor alle
deelbare subagent-definities — elke consumerende repo wijst ernaar toe in plaats van eigen kopieën
te onderhouden, en schakelt **per plugin aan of uit** welke groepen hij nodig heeft.

## De plugin-families

Elke plugin-familie woont in een eigen map onder `claude-code-plugins/`, met een **eigen README** die
uitlegt wat de familie doet en wat de verschillen tussen haar sub-plugins zijn. Vooralsnog is er één
familie:

- **[`claude-specialists/`](claude-code-plugins/claude-specialists/README.md)** — het
  Claude-Specialists-systeem: de gedeelde, repo-neutrale kern `specialists` (groep 1, voor elke
  repo) plus de twee bewust domein-gekleurde groepen `specialists-lifehub` (groep 2) en
  `specialists-shopify` (groep 3). Wélke specialisten in welke sub-plugin zitten, voor wie ze
  bedoeld zijn en hoe je ze aanroept, staat in die README — dit bestand herhaalt dat niet.

## Wat hier wél en niet woont

**Wél:** de drie plugin-mappen met **subagent-definities** (`agents/`); voor een gemigreerde
domein-groep ook het **draagbare vakboek** (`manuals/<group>-<id>-manual.md`) dat de agent-def via
`${CLAUDE_PLUGIN_ROOT}/manuals/` inleest. Groep 1 draagt daarnaast twee dingen die de
**hoofdloop-laag** dekken (zie [Adoptie: het bootstrap-pad](#adoptie-het-bootstrap-pad)): de
**persona-sjablonen** (`personas/<group>-<id>-persona.md`) van de orchestrator + hoofdloop-specialisten
(Chris, Derek, Rendall), en de **repo-neutrale bootstrap-skill** `specialists-init`.

**Niet:** governance (`CLAUDE.md`, de workflow-regels), safety-hooks of MCP-config. Die blijven
bewust op repo-niveau, want ze zijn per repo verschillend (of veiligheidskritisch). De plugins
dragen bewust **geen hooks** en **geen repo-specifieke skills** — de enige skill hier (`specialists-init`)
is repo-neutraal (het adoptiepad zelf), een bewuste uitzondering; domein-groep 2/3 mogen wél
domein-skills meedragen als een repo die deelt.

### Manuals — het gesplitste model

Een specialist-vakboek valt uiteen in een **draagbaar** deel (repo-neutraal, identiek in elke repo:
het vak, de harde regels, de toon) en een **repo-lens** (het `## Eigen aan deze repo`-deel: wélke
content/context van díe repo de specialist bedient). Het draagbare deel woont in
`<plugin>/manuals/<group>-<id>-manual.md` in deze marketplace; de consumerende repo houdt alleen de
lens in `.claude/extensions/<group>-<id>-extension.md`. De agent-def verwijst naar beide.

**Alle drie de groepen zijn inmiddels gemigreerd** — elk vakboek woont hier in de `manuals/`-map van
zijn plugin, en elke consumerende repo houdt daarvan enkel nog de repo-lens in `.claude/extensions/`:

- **`specialists` (groep 1)** → `claude-code-plugins/claude-specialists/specialists/manuals/` (Paula, Rebecca, Vera, Gwen, Cody, Tycho,
  Sylvester, Tessa, Edith, Victor, Sean).
- **`specialists-lifehub` (groep 2)** → `claude-code-plugins/claude-specialists/specialists-lifehub/manuals/` (Astrid, Fiona, Hugo, Ian, Onyx).
- **`specialists-shopify` (groep 3)** → `claude-code-plugins/claude-specialists/specialists-shopify/manuals/` (Liam, Sandra, Steven).

**Persona-sjablonen — een derde artefact naast agent-def en manual.** De orchestrator en de
hoofdloop-specialisten (Chris #01, Derek #05, Rendall #06) draaien in de **hoofdloop**, niet als
subagent — een plugin kan geen altijd-aan-hoofdloop-context injecteren. Ze hebben daarom bewust
**geen** agent-def; hun draagbare bron woont in `claude-code-plugins/claude-specialists/specialists/personas/<group>-<id>-persona.md` als
**self-contained sjabloon** (draagbare body + een repo-lens-placeholder). De consument krijgt geen
plugin-verwijzing maar een **kopie** in `.claude/extensions/<group>-<id>-extension.md`, die via een
`@`-import in zijn `CLAUDE.md` wordt auto-geladen. De [bootstrap-skill](#adoptie-het-bootstrap-pad)
zet die kopie neer; de [drift-lint](#onderhoud-drift-lint) bewaakt de draagbare body ervan tegen de
canonieke bron. De agent-def↔manual-koppeling van de lint laat persona's bewust met rust (ze hebben
geen agent-def).

## Consumptie

Een consumerende repo voegt deze marketplace toe via `extraKnownMarketplaces` in
`.claude/settings.json` en schakelt de gewenste plugins in via `enabledPlugins`. Beide huidige
consumenten (life-hub en smartwatchbanden) gebruiken een remote **`github`-marketplace-source**
(`"source": "github", "repo": "DaveKJohn/davekjohns-workshop"`) — machine-onafhankelijk, want de
Claude Code CLI clonet en cachet dit repo zelf; een verse clone van de consumerende repo krijgt de
plugins zonder handmatige lokale stap.

```jsonc
// .claude/settings.json (consumerende repo)
"extraKnownMarketplaces": {
  "davekjohns-workshop": {
    "source": { "source": "github", "repo": "DaveKJohn/davekjohns-workshop" }
  }
},
"enabledPlugins": {
  "specialists@davekjohns-workshop": true,          // groep 1 — altijd
  "specialists-lifehub@davekjohns-workshop": true   // óf specialists-shopify@… , naar keuze
}
```

Een nieuw ingeschakelde plugin is pas in een **volgende** Claude Code-sessie zichtbaar.

## Adoptie: het bootstrap-pad

De plugin inschakelen levert de **werker-subagents**, maar niet de **dirigent** (Chris) of de
governance-/hooks-laag — die kunnen niet uit een plugin komen (een plugin injecteert geen
hoofdloop-context en bewerkt geen `CLAUDE.md`). De skill **`specialists-init`** (groep 1) dicht dat
gat in een consumerende repo. Omdat een plugin-skill zichzelf niet kan aanhaken, is het pad
tweetraps:

- **Stap 0 (handmatig).** Zet de marketplace-source + `enabledPlugins` in `.claude/settings.json`
  (zie [Consumptie](#consumptie)) en **herstart** de sessie — pas dán is de skill beschikbaar.
- **Stap 1 (de skill).** Roep `specialists-init` aan. Het bijgeleverde
  [`bootstrap.ps1`](claude-code-plugins/claude-specialists/specialists/skills/specialists-init/bootstrap.ps1) doet alleen **additieve**
  handelingen: het kopieert de persona-sjablonen naar `.claude/extensions/<group>-<id>-extension.md`
  (nooit overschrijven), zet de `@.claude/extensions/01-01-extension.md`-import onderaan `CLAUDE.md`
  (of maakt een scaffold), en schrijft een `settings.suggested.jsonc` met een `permissions.deny` +
  hooks-**stub**. Het raakt `settings.json` niet aan — die merge en de repo-lens invullen zijn
  daarna handwerk (repo-specifiek), waarna nog één **herstart** de nieuwe context activeert.

## Versiebeheer

Elke plugin (`claude-code-plugins/claude-specialists/specialists/…`, `claude-code-plugins/claude-specialists/specialists-lifehub/…`, `claude-code-plugins/claude-specialists/specialists-shopify/…`) draagt een eigen
`version` in zijn `plugin.json`. Bij een release bewegen die versies **in lockstep** — ze krijgen
allemaal hetzelfde nummer en één repo-brede tag `vX.Y.Z` (zie [Een release snijden](#een-release-snijden)).
**Dat versienummer is óók de update-poort**: `claude plugin update` vergelijkt uitsluitend
versienummers, dus een consumerende repo (inclusief deze repo zelf, die zichzelf consumeert) haalt
gemergde wijzigingen pas binnen nadat de `version` is gebumpt — een merge zonder release blijft voor
consumenten onzichtbaar. Moet werk naar consumenten propageren, dan hoort daar dus een release bij
(op Dave's expliciete verzoek, zoals altijd).
Wijzigingen aan een gedeelde agent-def landen hier eerst, worden hier gecommit, en pas daarna door de
consumerende repo's opgehaald — nooit andersom (geen repo mag een gedeelde agent-def lokaal
overschrijven zonder dat hier terug te leggen).

## Onderhoud: drift-lint

Via de `github`-marketplace-source clonet en cachet de Claude Code CLI dit repo zelf voor elke
consument, dus is er geen fysieke kopie in de consumerende repo nodig en dus ook geen sync-stap —
elke consument consumeert letterlijk dezelfde bestanden. Uit een overgang kan een consumerende repo
echter nog een verouderde lokale kopie van een agent-def hebben die inmiddels hier gedeeld is.
[`scripts/lint/check-consumer-drift.ps1`](scripts/lint/check-consumer-drift.ps1) vergelijkt zo'n
lokale kopie (read-only, wijzigt niets) met de canonieke versie hier en meldt `MISSING` (al
gemigreerd), `IDENTICAL` (dode kopie, veilig te verwijderen) of `DRIFTED` (eerst bekijken vóór
verwijderen). Opruimen zelf gebeurt in de consumerende repo, niet door dit script.

Hetzelfde script vergelijkt ook de **persona's**: het legt de draagbare body van elke
`personas/<group>-<id>-persona.md` naast de body van de consument-kopie in
`.claude/extensions/<group>-<id>-extension.md` (alles boven de `## Eigen aan deze repo`-marker; de
repo-lens eronder is per repo verschillend en wordt niet vergeleken). Die persona-bevindingen zijn
**informatief** — ze tellen niet mee in de exit-code, want een consument met een handgeschreven
persona is per definitie `DRIFTED` tot hij gecoördineerd is gereconcilieerd.

```powershell
./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\pad\naar\life-hub
./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\pad\naar\smartwatchbanden
```

## Bijdragen — changelog & PR-workflow

Wijzigingen aan dit repo gaan via een branch + Pull Request naar `main`, met een gevouwen
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
6. **Folden:** op `main`, direct na de merge,
   [`scripts/release/fold-changelog-entry.ps1`](scripts/release/fold-changelog-entry.ps1)`-Branch <naam>`
   vouwt het entry-bestand in de `## Pull Requests`-sectie van [`CHANGELOG.md`](CHANGELOG.md) (met
   `#NN` + PR-link) en verwijdert het entry-bestand; commit dat rechtstreeks op `main`.

### Een release snijden

Een release is een **vastgelegd moment**: alle drie de plugins krijgen hetzelfde versienummer
(**lockstep, repo-breed**) en de staat wordt getagd als `vX.Y.Z`. Er wordt niets naar GitHub Releases
gepubliceerd — alleen een git-tag, de volledige notes in [`releases/`](releases/README.md), en een
verwijzing daarnaartoe in [`CHANGELOG.md`](CHANGELOG.md). Een release wordt **alleen op Dave's
expliciete verzoek** gesneden en loopt bewust **niet via een branch + PR**: net als de fold-commit is
de release-commit een toegestane directe-op-`main`-actie (de tweede uitzondering op "alles via
branch + PR").

In één beweging, op een schone `main`:
[`scripts/release/cut-release.ps1`](scripts/release/cut-release.ps1)`(-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"]`

1. bumpt alle `plugin.json`-versies in lockstep naar `X.Y.Z`;
2. genereert de volledige release-notes in `releases/development/<X.Y>/<X.Y.Z>.md` (uit de gevouwen
   `## Pull Requests`-entries, per branch-type), voegt een rij toe aan `releases/README.md`, en zet in
   `CHANGELOG.md` een verwijzing onder `## Releases` (de Pull-Requests-sectie wordt geleegd tot zijn intro);
3. commit dat rechtstreeks op `main` (`release: vX.Y.Z`) en zet een annotated tag `vX.Y.Z`;
4. pusht `main` + de tag (tenzij `-NoPush` voor inspectie vooraf).

Vangrails: schone `main`, geen ongevouwen entry-bestanden, lint-poort groen, tag bestaat nog niet.
De pure logica (versie-bump, CHANGELOG-transformatie, notes-opbouw) woont in
[`scripts/lib/release-lib.ps1`](scripts/lib/release-lib.ps1) en wordt gedekt door
[`scripts/tests/release-lib.tests.ps1`](scripts/tests/release-lib.tests.ps1).
