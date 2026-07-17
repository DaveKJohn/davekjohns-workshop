# Dossier — Persona-drift: uitzoeken en een doctrine vastleggen

> Werkbriefing voor deze branch. Opgesteld 2026-07-17 (Tessa #16, op aanwijzing van Dave).
> Dit dossier verdwijnt weer zodra het werk is afgerond en gemergd.

## Wat moet er gebeuren

**Stap 1 — uitzoeken ([Rebecca #07](../.claude/extensions/03-07-extension.md)).** De
connectors-check (`scripts/sync/check-connectors.ps1`) meldt persona-drift bij beide consumenten:

| Consument | Drifted persona's |
|---|---|
| `DaveKJohn/life-hub` | `01-01` (Chris), `03-02`, `05-05` (Derek), `05-06` (Rendall) |
| `davekokbwj/smartwatchbanden` | `01-01` (Chris), `05-05` (Derek), `05-06` (Rendall) |

Per drifted persona vaststellen: is de afwijking **bewuste repo-eigen aanpassing** (de consument
heeft zijn lens/persona doelbewust anders ingericht) of **achterstand** (de canonieke bron in de
plugin is doorontwikkeld en de kopie is blijven staan)? Concreet: de body-diff per bestand
bekijken en de aard van de afwijking benoemen. Let op: life-hub-werk gebeurt op Dave's andere
machine — hier alleen lezen, niets in de consument-repo's wijzigen.

**Stap 2 — doctrine vastleggen ([Tessa #16](../.claude/extensions/06-16-extension.md)).** Op basis
van de bevindingen een regel formuleren en documenteren (in het
[connectors-README](../claude-code-plugins/claude-specialists/connectors/README.md) en/of de
persona-sjablonen): hoe markeert een consument een **bewust afwijkende** persona zodat de check die
niet elke sessie opnieuw als ruis meldt, en hoe blijft **echte achterstand** wél zichtbaar?
Mogelijke richtingen (keuze bij uitvoering, met Dave): een marker in de persona-frontmatter, een
veld in het connector-manifest, of een uitgebreidere check-uitvoer. Raakt de oplossing
`check-consumer-drift.ps1`/`check-connectors.ps1`, dan schuift dat deel naar
[Sylvester #15](../.claude/extensions/05-15-extension.md) + [Tycho #18](../.claude/extensions/04-18-extension.md)
(script + tests) en wordt deze branch mogelijk geherclassificeerd.

## Waarom

- De drift-melding is nu **informatief** (telt niet mee in de exit-code) en verschijnt bij elke
  sessiestart. Zonder doctrine went het team aan de ruis — en precies dan wordt échte achterstand
  (een persona die een belangrijke bron-update mist) onzichtbaar.
- Het onderscheid bewust/achterstand is nooit vastgesteld; de melding is daardoor nu niet
  actionable.
- Dit wordt urgenter zodra **collega's als consument aansluiten**: die hebben de context van "dit
  is waarschijnlijk bewust" niet en moeten op de check kunnen vertrouwen.

## Klaar wanneer

- [x] Per drifted persona is vastgesteld: bewust of achterstand — zie de uitkomst hieronder.
- [x] Achterstand is gemeld als werkpunt (sync in de betreffende consument-repo, op de juiste
      machine) — vastgelegd in het sessie-geheugen én hieronder.
- [x] De doctrine staat in de docs (connectors-README, sectie "Persona-drift: hoe je een
      DRIFTED-melding leest") en de check gedraagt zich ernaar.
- [ ] Dit dossier is opgeruimd (na de merge).

## Uitkomst (2026-07-17, onderzoek Rebecca)

**De cijfers over de zeven meldingen:** 0× bewuste aanpassing van een draagbare body, 1× echte
achterstand, 6× vals-positief door één structureel padverschil.

- **Vals-positief (6×):** de index-link in de blockquote onder de titel wijst in het sjabloon twee
  niveaus omhoog (`../../CLAUDE.md`, het legacy-pad), terwijl beide consumenten terecht vier
  niveaus omhoog linken vanaf het plugin-pad. Elke correct gesyncte consument werd daardoor
  permanent als `DRIFTED` gemeld. **Fix op deze branch:** `check-consumer-drift.ps1` normaliseert
  het link-doel vóór de body-vergelijking — na Victor's review bewust beperkt tot de twee geldige
  diepten (2 en 4 niveaus), zodat een écht kapot pad drift blijft melden (+ drie nieuwe
  asserts in `bootstrap-drift.tests.ps1`, 26 totaal).
- **Echte achterstand (1×):** smartwatchbanden's Chris (`01-01`) mist de sectie
  "Kern-verbeterpunten — de inbound-route" (toegevoegd in v1.3.0, PR #54). **Werkpunt in de
  smartwatchbanden-repo:** de persona-kopie verversen vanaf de bron (en daarna het
  connector-manifest bijwerken).
- **Administratief naijlpunt:** `connectors/life-hub.json` boekt een refresh als openstaand die
  inmiddels is uitgevoerd — het manifest bijwerken is een werkpunt voor een life-hub-sessie
  (andere machine).
- **Doctrine:** geen "bewust afwijkend"-mechaniek nodig (de praktijk kent geen bewuste
  body-afwijkingen); een `DRIFTED`-persona is voortaan per definitie een werkpunt. Vastgelegd in
  het [connectors-README](../claude-code-plugins/claude-specialists/connectors/README.md).
- **Herclassificatie:** de branch heet nu `fix/persona-drift-ruis` (was `docs/persona-drift-doctrine`)
  — het zwaartepunt bleek een fout in de bestaande check, niet een doc-wijziging; de doctrine-tekst
  beweegt mee met het gedrag.
