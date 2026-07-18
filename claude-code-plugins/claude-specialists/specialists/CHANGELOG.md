# Changelog — specialists

Consument-gerichte geschiedenis van deze plugin: per release de wijzigingen die deze plugin
raakten. Automatisch bijgeschreven door `cut-release.ps1` van de marketplace-repo
(davekjohns-workshop); de volledige werkplaats-geschiedenis staat daar in `CHANGELOG.md` en
`releases/`.

## v1.8.0 — 2026-07-18

### #80 · Bootstrap seedt plugin-pad + lens-only (adoptie-laag) · Feat · 2026-07-18

De laatste stap om het plugin-pad + lens-only-model écht overal de standaard te maken: de
**adoptie-laag**. `bootstrap.ps1` (de `specialists-init`-skill) seedt een verse consument nu op het
**plugin-pad** met **lens-only** persona-lenzen — precies wat deze repo en life-hub al hebben — i.p.v.
het legacy-pad met volledige body-kopieën.

- **`bootstrap.ps1`** zet de lenzen op `.claude/plugins/<familie>/<plugin>/` (familie + plugin
  afgeleid uit het install-pad, met fallback voor de versie-cache-layout). De persona-lenzen zijn
  **lens-only**: alleen de lens-only-kop + het VUL-IN-repo-lens-slot, géén body-kopie. `CLAUDE.md`
  krijgt **twee** `@`-imports voor Chris: zijn draagbare body uit de plugin-install
  (`@~/.claude/plugins/marketplaces/<marketplace>/.../01-01-persona.md`) én zijn repo-lens.
- **Regressietests** (`bootstrap-drift.tests.ps1`) herschreven: plugin-pad, lens-only, de twee
  imports, de versie-cache-fallback en de behouden legacy-body-drift-vergelijking (30 asserts).
- **Docs** (`QUICKSTART.md`, `connectors/README.md`) bijgewerkt naar het plugin-pad + lens-only-model.

De body laadt runtime uit de plugin-install; dat `~`-import-pad is (net als bij life-hub) niet volledig
via de fixture-tests af te dwingen — de tests dekken de pad-/lens-only-structuur, het live `@`-import-
gedrag is bewezen doordat life-hub het draait. Lint + alle testsuites groen.

[PR #80](https://github.com/DaveKJohn/davekjohns-workshop/pull/80)

---

## v1.7.0 — 2026-07-18

### #77 · Repo-lenzen naar het plugin-pad als standaard (primair + legacy-fallback) · Feat · 2026-07-18

De repo-lenzen van deze repo verhuizen van het legacy-pad (`.claude/extensions/`) naar het
**plugin-pad** (`.claude/plugins/claude-specialists/specialists/`) — de nieuwe standaard-locatie
(pariteit met life-hub). Om de andere consumerende repo's (life-hub, smartwatchbanden) niet te breken,
verwijst het gedeelde contract voortaan naar het **plugin-pad als primair, met het legacy-pad als
fallback** — een repo die nog op legacy staat blijft dus gewoon werken.

**Deze repo:**
- De 11 lenzen (incl. Ravi 06-24) + het handboek verplaatst naar het plugin-pad, met de relatieve
  link-diepte bijgesteld (2 → 4 niveaus). De 5 lege stubs (Paula/Bianca/Vera/Gwen/Cody) opgeruimd.
- De `@`-import onderaan `CLAUDE.md` → plugin-pad. Alle doc-verwijzingen (`CLAUDE.md`, `README.md`,
  het handboek) → plugin-pad. De persona-lens-index-regels naar locatie-onafhankelijke platte tekst.
- `check-plugin-integrity.ps1` scant nu de lenzen op het plugin-pad **én** het legacy-pad.

**Het gedeelde contract (raakt alle repo's, via de volgende release):**
- De ~20 agent-defs en de ~20 manuals verwijzen subagents nu naar het plugin-pad (primair) met het
  legacy-pad als fallback. De generieke lens-mention in het gedeelde `grens-inbound`-blok idem.

**Bewust uitgesteld (blijft werken via de fallback):** de **adoptie-laag** — `bootstrap.ps1` seedt
nieuwe consumenten nog op het legacy-pad, en `QUICKSTART.md` / `connectors/README.md` beschrijven dat
zo. Dat volledig omzetten (incl. de bootstrap-tests) is een aparte vervolgstap; tot die tijd landt een
verse consument op legacy en werkt hij via de fallback.

Lint en alle testsuites groen. De `## Releases`-CHANGELOG-entries zijn als historisch record ongemoeid
gelaten.

[PR #77](https://github.com/DaveKJohn/davekjohns-workshop/pull/77)

---

### #76 · Persona-sjabloon-intro's gededupliceerd (Ravi's eerste klus) · Chore · 2026-07-18

Ravi's eerste opdracht: de persona-sjablonen op duplicatie scannen. Bevinding — er zijn **geen
verbatim-gedeelde gedragsbullets** over de vier persona's (Chris, Bianca, Derek, Rendall); de
gedragsregels zijn bewust rol-geformuleerd (rol-nuance, niet harmoniseren). De énige verbatim-duplicatie
was het **intro-uitleg-commentaar** — een grotendeels identieke herhaling van het gesplitste model dat
`README.md` al vastlegt, en dat (in een HTML-commentaar) het gedeelde-blok-mechanisme sowieso niet kan
gebruiken.

Actie: het intro-commentaar in de vier sjablonen ingekort tot een korte verwijzing naar `README.md`,
met behoud van de rol-specifieke eerste regel. Netto ~33 regels boilerplate weg, en minder ruis die een
lens-only consument via de `@`-import meelaadt (sluit aan op de #69-schoonmaak). Het commentaar staat
boven de H1, dus `Get-PortableBody` raakt het niet — geen drift-regressie.

Conclusie voor de toekomst: het sentinel-mechanisme uitbreiden naar persona's heeft nú geen payload
(geen deelbaar body-blok); dat wacht tot een verbatim-gedeelde persona-bullet daadwerkelijk opduikt.

[PR #76](https://github.com/DaveKJohn/davekjohns-workshop/pull/76)

---

### #75 · Ravi (refactoring-specialist / DRY-bewaker) toegevoegd aan het team · Feat · 2026-07-18

Een nieuw teamlid in de `specialists`-plugin (groep 06, de vóór-de-merge-bewakers): **Ravi ♻️
#06-24**, de refactoring-specialist. Zijn vak is *single source of truth*: hij is de staande
verantwoordelijke voor duplicatie van **gedragsregels** (grenzen/werkwijzen) over agent-defs en
persona's. Zodra dezelfde regel op ≥2 plekken staat, slaat hij alarm en promoveert die tot één
gedeelde bron — beschikbaar voor de kring die de regel deelt, **niet** automatisch voor iedereen.

- **`specialists/agents/06-24-agent.md`** — de subagent-def (`@specialists:ravi`), die zelf het
  gedeelde `grens-inbound`-blok via sentinels gebruikt (dogfooding).
- **`specialists/manuals/06-24-manual.md`** — het draagbare vakboek, met "globaal = beschikbaar voor
  een deel, niet automatisch voor iedereen" als harde regel.
- **`.claude/extensions/06-24-extension.md`** — de repo-lens: wat Ravi hier bewaakt (de agent-defs +
  persona's van deze marketplace) en het `agent-shared/`-build-en-lint-mechanisme dat hij bedient.
- **Roster ingehaakt** in `CLAUDE.md`, Chris' routingtabel + twee ketens (parallelle
  kwaliteitscheck vóór PR én een eigen "duplicatie globaliseren"-keten), en het
  specialisten-handboek (`.claude/README.md`) + de root-README.

Ravi's eerste openstaande klussen: het gedeelde-blok-mechanisme uitbreiden naar de persona-sjablonen,
de Tier 2-sweep (eindbericht/gespreksgeschiedenis/branch), en een detectie-lint als
alarmbel-automatisering. Doel: het project zo klein en efficiënt mogelijk houden.

[PR #75](https://github.com/DaveKJohn/davekjohns-workshop/pull/75)

---

## v1.6.0 — 2026-07-18

### #74 · Gedeelde agent-def-blokken uit een enkele bron (build-en-lint) · Feat · 2026-07-18

Verbatim-gedeelde bullets onder **Grenzen** — de inbound-regel (19/19 agent-defs), de
webcontent-regel (3) en de Artifact-publiceer-regel (2) — werden tot nu toe in elke agent-def
handmatig gedupliceerd; één regel wijzigen betekende tot 19 bestanden aanraken. Ze komen nu uit
**één bron**, ingevuld door een generator en bewaakt door de lint-poort.

- **`claude-code-plugins/claude-specialists/agent-shared/<naam>.md`** — de canonieke bron van elk
  gedeeld blok (naast de plugin-mappen, zodat het niet met de plugin-cache meereist).
- **In de agent-defs** verschijnt elk blok tussen `<!-- BEGIN/END shared:<naam> -->`-sentinels. De
  inhoud staat er letterlijk (altijd-geladen, self-contained — Claude Code kent geen native
  transclusie in een agent-def), maar is als gegenereerd gemarkeerd.
- **`scripts/agents/build-agent-defs.ps1`** (+ `scripts/lib/agent-shared-lib.ps1`) — vult elke
  gemarkeerde regio uit zijn bron. Wijzig het bronbestand → draai het script → alle agent-defs bij.
  `-Check` meldt drift zonder te schrijven.
- **`check-plugin-integrity.ps1` (check 7)** faalt zodra een gemarkeerde regio afwijkt van zijn bron
  (hand-edit binnen de sentinels of een vergeten rebuild) — dezelfde poort die `open-pr.ps1` en CI
  al draaien.
- Regressietests in `scripts/tests/agent-shared.tests.ps1` (10 asserts) dekken de expansie, de
  drift-detectie, een BEGIN-zonder-END, een onbekend blok en de repo-in-sync-smoke.

De 19 agent-defs zijn puur omwikkeld met sentinels — nul inhoudelijke wijziging. Aanpassen van een
gedeelde grens kost voortaan één edit + één build in plaats van 19 handmatige wijzigingen.

[PR #74](https://github.com/DaveKJohn/davekjohns-workshop/pull/74)

---

## v1.5.2 — 2026-07-18

### #73 · Persona-indexregel locatie-onafhankelijk (bron-fix inbound #64) · Fix · 2026-07-18

De indexregel onder de titel van de vier persona-sjablonen (`01-01`, `03-02`, `05-05`, `05-06`) droeg een pad-diepte-afhankelijke markdown-link naar de repo-CLAUDE.md (`](../../CLAUDE.md)`). Die diepte klopt alleen op het legacy-pad (2 niveaus); op het plugin-pad (4 niveaus) was het een dode link, waardoor de draagbare body daar nooit byte-identiek aan de bron kon zijn.

- **De indexregel is nu platte tekst** (`Index: de repo-CLAUDE.md · …`), locatie-onafhankelijk. Een consument neemt de body op elk pad byte-identiek over — geen dode link meer.
- **De link-diepte-normalisatie in `check-consumer-drift.ps1` (`Get-PortableBody`) is verwijderd**, want overbodig geworden: er is geen pad-afhankelijke link meer om te normaliseren. Dit ruimt de workaround uit PR #68 (v1.5.0) op ten gunste van een bron-fix.
- De regressietests zijn navenant bijgewerkt: de twee normalisatie-tests zijn vervangen door één guard die borgt dat de indexregel geen pad-diepte-link meer draagt.

Dit is de bron-oplossing voor inbound life-hub [#64](https://github.com/DaveKJohn/davekjohns-workshop/issues/64): PR #68 doodde het vals-positieve `DRIFTED`-signaal aan de check-kant, deze wijziging neemt de wortel weg. Consumenten laten bij de volgende sync de link in hun indexregel vallen.

[PR #73](https://github.com/DaveKJohn/davekjohns-workshop/pull/73)

---

## v1.5.1 — 2026-07-18

### #72 · Persona-sjablonen en drift-check kennen het lens-only-model · Fix · 2026-07-18

Twee samenhangende punten uit inbound life-hub [#69](https://github.com/DaveKJohn/davekjohns-workshop/issues/69), beide gevolg van het lens-only-model dat een consument geen body-kopie meer laat bewaren:

- **Het `## Eigen aan deze repo (VUL-IN)`-slot is uit de vier persona-sjablonen gehaald** (`01-01`, `03-02`, `05-05`, `05-06`). Bij een consument die de body rechtstreeks importeert (lens-only) laadde dat slot — een bootstrap-instructie, geen persona-inhoud — als ruis mee in elke sessie. De sjabloon-intro-comments zijn navenant bijgewerkt.
- **`bootstrap.ps1` genereert het VUL-IN-slot nu zelf** bij het kopiëren van een persona, in plaats van het uit het sjabloon over te nemen — zo houdt een verse consument een duidelijke plek voor de repo-lens (DRY met de lens-scaffolds van stap 1b).
- **`check-consumer-drift.ps1` kent het lens-only-model.** Een consument-extension die met de `> Repo-lens (lens-only persona)`-blockquote opent, heeft per definitie geen body-kopie; de check meldt die nu als `LENS-ONLY` in plaats van de vals-positieve `DRIFTED`. Zo betekent een `DRIFTED`-melding weer altijd een écht werkpunt.

De regressietests in `scripts/tests/bootstrap-drift.tests.ps1` borgen dat het sjabloon schoon is, dat de bootstrap zelf een VUL-IN-slot toevoegt (geen drift-regressie op een verse kopie) en dat een lens-only extension als `LENS-ONLY` wordt gerapporteerd.

[PR #72](https://github.com/DaveKJohn/davekjohns-workshop/pull/72)

---

### #71 · Inbound-regel toegevoegd aan alle agent-defs · Docs · 2026-07-17

Elk van de 19 agent-defs in de drie plugins (`specialists`, `specialists-lifehub`,
`specialists-shopify`) heeft nu een eigen bullet in zijn **Grenzen**-sectie die de
inbound-route benoemt: verbeterpunten aan de gedeelde kern (de eigen agent-def en vakboek,
die van collega's, en alle andere onderdelen die de plugin draagt) bouwt een specialist
niet lokaal om; hij meldt ze via de vaste, afgesproken route — een issue met het label
`inbound` op de bron-repo van de plugin (het issue-sjabloon staat er al klaar), generiek
beschreven en zonder repo-eigen, persoonlijke of gevoelige details uit de eigen repo.
Werkt hij al in de bron-repo zelf, dan volgt hij daar gewoon de normale keten. Repo-eigen
aanvullingen horen in de repo-lens. Zo kent ook een rechtstreeks aangeroepen
werker-subagent deze regel, niet alleen Chris' persona-body en de QUICKSTART. De
formulering is na twee correctierondes (Edith's eindredactie: generieke plugin-onderdelen
+ collega's-agent-defs; Sean's security-review: standing-route-framing + de
anonimiseringscaveat) tot deze definitieve tekst gekomen.

[PR #71](https://github.com/DaveKJohn/davekjohns-workshop/pull/71)

---

## v1.5.0 — 2026-07-17

### #66 · Chris sluit af zonder vaste slotformule · Docs · 2026-07-17

Op verzoek van Dave: de vaste afsluitvraag ("hoe kan ik verder van dienst zijn?") is uit stap 6 van Chris' ritueel gehaald — die werd eentonig. Chris vat nog steeds samen en mag een concrete volgende stap noemen, maar sluit af zonder standaard slotformule. Aangepast in beide bronnen: de repo-lens (`.claude/extensions/01-01-extension.md`) en het canonieke persona-sjabloon in de plugin (`personas/01-01-persona.md`).

[PR #66](https://github.com/DaveKJohn/davekjohns-workshop/pull/66)

---

### #61 · Per-plugin CHANGELOGs: consument-gerichte release-geschiedenis die meereist · Feat · 2026-07-16

Elke plugin draagt nu een eigen `CHANGELOG.md` die met de plugin-cache meereist: de
consument-gerichte selectie uit de werkplaats-geschiedenis. De fold leidt per entry automatisch
een `Plugins:`-regel af uit de PR-bestanden (`gh pr view --json files`; de `connectors/`-map telt
niet mee), en `cut-release.ps1` schrijft bij elke release per plugin de rakende entries bij —
nieuwste bovenaan, met root-relatieve links herschreven naar absolute GitHub-URLs zodat ze in een
consument-cache blijven werken. Vier nieuwe pure functies in `release-lib.ps1` met twaalf nieuwe
asserts (50 totaal); drie seed-CHANGELOGs; Rendall's lens en het root-README beschrijven het
mechaniek. De root-`CHANGELOG.md` en `releases/` blijven de volledige werkplaats-geschiedenis.

[PR #61](https://github.com/DaveKJohn/davekjohns-workshop/pull/61)
