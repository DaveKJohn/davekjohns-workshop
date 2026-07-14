# CLAUDE.md — claude-specialists

Dit bestand is de operating guide voor deze repo. Het is opgebouwd zoals de guide van elke repo die
met de Claude Specialists werkt: **de draagbare werkwijze staat bovenaan** (de grondwet — de
safety-rules en de algemene werkwijze, geldig in elke repo), en **alles wat specifiek is voor déze
repo staat onderaan** onder [`## Eigen aan deze repo (claude-specialists)`](#eigen-aan-deze-repo-claude-specialists).

> **Deze repo is een buitenbeentje.** In een gewone repo (zoals life-hub of smartwatchbanden) *bestúren*
> de Claude Specialists de repo: elke opdracht loopt via Chris, de Chief of Staff, die classificeert en
> doorroutert. Déze repo is juist de **bron waaruit dat team komt** — de marketplace die de
> subagent-definities huisvest die andere repo's inschakelen. Hij consumeert zelf geen specialists
> (er is geen `.claude/`-map, geen roster, geen Chris-routing). Wat hieronder overblijft is dus de
> pure **grondwet**: de safety- en werkwijze-regels die óók gelden als er geen team wordt geladen.

---

## Safety rules

**Grondwet — lees dit eerst.** Deze regels staan boven elk gemak. De concrete invulling voor déze repo
(de hoofdbranch, de lint-poort, de fold-uitzondering, het publiek-zijn) staat in
[`## Eigen aan deze repo (claude-specialists)`](#eigen-aan-deze-repo-claude-specialists).

### Nooit zonder expliciete toestemming van Dave

- **Een PR openen.** Ook als het werk "klaar" is, opent niemand uit zichzelf een PR — zie de regel
  hieronder.
- **Een release/versie-bump** van een plugin (`version` in een `plugin.json` ophogen, een tag of
  GitHub Release maken) — alleen op expliciet verzoek.
- **`git push --force`** (welke branch dan ook), **`git reset --hard`**, **`git rebase`** op een
  gedeelde branch.
- **Iets naar buiten publiceren** dat verder gaat dan de normale PR-flow (issues op andere repo's,
  een gist, een externe post).

### Nooit direct op de hoofdbranch — via branch + PR

Alle wijzigingen gaan via een branch + Pull Request. **Een PR wordt alléén geopend wanneer Dave dat
expliciet zegt** — dat bepaalt Dave, nooit op eigen houtje. Ook als het werk klaar en gecommit is,
wordt dat gemeld en gewacht op Dave's woord. **Zégt Dave "open de PR"** (of "zet de PR op", "doe het
live" — een expliciet PR-commando), **dán is dat meteen goedkeuring voor de hele beweging**: openen →
mergen → de changelog-entry folden lopen daarna zonder verdere tussenvraag door. Let op: "open de
branch" (checkout), "check dit" (review) of "klaar?" (een vraag) zijn **géén** PR-commando.

Op de hoofdbranch bestaat één bewuste uitzondering op "nooit direct committen" — de **fold-commit**
na een merge — en er hoort een **lint-poort** als veiligheidswacht vóór elke PR. Hoe die hier precies
zijn ingevuld (scripts, scope) staat in het repo-slot.

---

## Algemene werkwijze

- **Geleerde lessen worden geborgd in de docs, niet alleen in het geheugen.** Wordt iets ontdekt dat
  de volgende keer onthouden moet worden, dan wordt dat direct vastgelegd in de relevante doc
  (`README.md`, dit `CLAUDE.md`, of een agent-def/manual) — een geheugen-notitie alleen is te
  vrijblijvend.
- Wees binnen een branch proactief met het aanmaken van nieuwe mappen/bestanden zodra een nieuw
  onderwerp opduikt. Vraag niet eerst om toestemming voor de bestandsstructuur zelf; wél voor de
  inhoud als iets gevoelig of onzeker is.
- Bij twijfel over prioriteit: vraag naar deadlines/urgentie in plaats van te gokken.
- **Approval-vragen zijn zeldzaam, niet de norm.** Onderbreek Dave alleen bij écht uitzonderlijke
  acties: onomkeerbaar, naar buiten gericht, of met reëel risico (de acties uit de safety-rules).
  Al het routinewerk — git, bash, config, branches, commits, tooling/scripts — wordt gewoon
  uitgevoerd en gemeld, niet eerst gevraagd. Bij twijfel: kies een verstandige default, voer die uit,
  en meld het. Dit staat los van de PR-regel hierboven: een PR blijft altijd wachten op Dave's
  expliciete woord — dat is de bewuste, met naam genoemde uitzondering op deze zeldzaamheidsregel.

---

## Eigen aan deze repo (claude-specialists)

> *Alles hierboven is de draagbare grondwet. Dit deel is de claude-specialists-lens: het beschrijft
> niet dát er safety-rules zijn, maar wát déze repo is en hoe de grondwet hier concreet is ingevuld.*

`claude-specialists` is de **standalone marketplace-repo** die het Claude-Specialists-systeem
huisvest, opgedeeld in **drie plugins**: de gedeelde, draagbare kern (`specialists`) plus twee
domein-groepen (`specialists-lifehub`, `specialists-shopify`). Deze repo is de **single source of
truth** voor alle deelbare subagent-definities — elke consumerende repo (life-hub, smartwatchbanden)
wijst hierheen via een `github`-marketplace-source en schakelt **per plugin aan of uit** welke
groepen hij nodig heeft.

De volledige uitleg — de drie groepen, wat hier wél/niet woont, het gesplitste manual-model, de
aanroep-namespaces, de consumptie-config en de drift-lint — staat in [`README.md`](README.md). Dit
`CLAUDE.md` dupliceert dat niet; het legt alleen de **werkwijze** vast waarmee aan deze repo wordt
gewerkt.

### Taal

Alles in deze repo is **Nederlands**, tenzij een technische identifier (code, bestandsnaam, flag)
zijn oorspronkelijke vorm hoort te houden.

### Structuur — waar wat woont

- **`.claude-plugin/marketplace.json`** — de marketplace-definitie: de drie plugins met hun `source`.
- **`specialists/`, `specialists-lifehub/`, `specialists-shopify/`** — de drie plugins, elk met een
  eigen `.claude-plugin/plugin.json` (`version`), `agents/` (subagent-defs) en — voor een gemigreerde
  groep — `manuals/` (het draagbare vakboek dat de agent-def via `${CLAUDE_PLUGIN_ROOT}/manuals/`
  inleest). `specialists-shopify` draagt daarnaast een `skills/`-map (`start-task`).
- **`scripts/lib/`** — gedeelde helpers (`branch-info.ps1`: de prefix→label→changelog-type-tabel).
- **`scripts/lint/`** — `check-plugin-integrity.ps1` (de PR-lint-poort) en `check-consumer-drift.ps1`
  (read-only drift-check tegen een consumerende repo).
- **`scripts/release/`** — `new-changelog-entry.ps1`, `open-pr.ps1`, `fold-changelog-entry.ps1`.
- **`CHANGELOG.md`** — `## Pull Requests` (gevouwen entries) + `## Releases`.
- **`.github/pull_request_template.md`** — de PR-template met type-checklist.

### Wijzigingen aan gedeelde agent-defs — richting van de waarheid

Een wijziging aan een gedeelde agent-def of manual landt **hier eerst**, wordt hier gecommit, en pas
daarna door de consumerende repo's opgehaald — **nooit andersom**. Geen enkele repo mag een gedeelde
agent-def lokaal overschrijven zonder die wijziging hier terug te leggen. De `check-consumer-drift.ps1`-lint
signaleert een verouderde lokale kopie in een consumerende repo (`MISSING`/`IDENTICAL`/`DRIFTED`);
het opruimen zelf gebeurt in díe repo, niet hier.

### Safety-invulling van claude-specialists

De grondwet hierboven, hier concreet ingevuld:

- **De hoofdbranch is `master`.** Alle wijzigingen via een `<prefix>/<korte-naam>`-branch + PR naar
  `master`. Geldige prefixes staan in [`scripts/lib/branch-info.ps1`](scripts/lib/branch-info.ps1)
  en in [`README.md`](README.md#bijdragen--changelog--pr-workflow): `feat/` → enhancement · `fix/` →
  bug · `docs/` → documentation · `chore/` → documentation.
- **De lint-poort is de veiligheidswacht vóór elke PR.**
  [`scripts/lint/check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1) valideert de
  manifesten (`marketplace.json` + elke `plugin.json`), de agent-def- en manual-frontmatter
  (`name`/`id`/`group` + bestandsnaam-match), en scant op dode links. `open-pr.ps1` draait die poort
  eerst; vindt hij een error, dan wordt er niet gepusht en geen PR geopend (`-SkipLint` is de bewuste
  noodklep). Draai de poort ook los tijdens het werk om vroeg te vangen.
- **De enige uitzondering op "nooit direct op `master`"** is de **fold-commit** na een merge:
  [`fold-changelog-entry.ps1`](scripts/release/fold-changelog-entry.ps1) vouwt het entry-bestand in
  `CHANGELOG.md` en verwijdert het — scope beperkt tot `CHANGELOG.md` + het verwijderde entry-bestand,
  rechtstreeks op `master`. Dit loopt door als onderdeel van een expliciet PR-commando (zie de
  grondwet), niet los.
- **Deze repo is `public`.** Bewuste keuze, zodat de remote `github`-marketplace-source zonder
  gh-auth te lezen is. Gevolg: hier hoort **niets vertrouwelijks** in — geen persoonlijke informatie,
  inloggegevens of secrets. De agent-defs van groep 1 zijn daarom bewust repo-neutraal; repo-specifieke
  context woont in de `.claude/extensions/`-lens van de consumerende (private) repo, niet hier.

### De changelog- & PR-workflow

De volledige stappen (branch → entry aanmaken → werk + commit → PR openen → merge → folden) staan in
[`README.md`](README.md#bijdragen--changelog--pr-workflow). In het kort blijft gelden: het
**entry-bestand** (`<branch-naam>.md` in de repo-root) wordt op de branch meegecommit en later door de
fold-stap in `CHANGELOG.md` opgenomen. Versiebeheer loopt per plugin via de `version` in elke
`plugin.json`; een repo-brede release-pijplijn is bewust **nog buiten scope**.
