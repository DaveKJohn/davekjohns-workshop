# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #67 · Dossier: consumenten-quickstart voor collega-repos · Docs · 2026-07-17

Nieuwe deelbare quickstart-pagina (`claude-code-plugins/claude-specialists/QUICKSTART.md`) voor collega's die hun eigen repo willen aansluiten zonder het systeem gebouwd te hebben: wat je krijgt, aansluiten in drie stappen (settings.json → `specialists-init` → herstart + check), hoe je bijblijft via releases en de per-plugin CHANGELOGs, en de inbound-route voor terugmeldingen. Root-README en familie-README verwijzen ernaar; het werkdossier `dossiers/consumenten-quickstart.md` documenteert de afwegingen.

[PR #67](https://github.com/DaveKJohn/davekjohns-workshop/pull/67)

---

### #66 · Chris sluit af zonder vaste slotformule · Docs · 2026-07-17

Op verzoek van Dave: de vaste afsluitvraag ("hoe kan ik verder van dienst zijn?") is uit stap 6 van Chris' ritueel gehaald — die werd eentonig. Chris vat nog steeds samen en mag een concrete volgende stap noemen, maar sluit af zonder standaard slotformule. Aangepast in beide bronnen: de repo-lens (`.claude/extensions/01-01-extension.md`) en het canonieke persona-sjabloon in de plugin (`personas/01-01-persona.md`).

Plugins: specialists

[PR #66](https://github.com/DaveKJohn/davekjohns-workshop/pull/66)

---

### #65 · Dossier: review-herkansing op de gemergde 61-diff · Chore · 2026-07-17

De nooit afgeronde Victor/Edith-review op de gemergde #61-diff (per-plugin CHANGELOGs) is alsnog uitgevoerd en de vondsten zijn verwerkt. Belangrijkste fix: de interne `Plugins:`-metadataregel lekte via `cut-release.ps1` door in de consument-gerichte per-plugin CHANGELOGs — nieuwe pure functie `Remove-EntryPluginsLine` strips die regel vóór het bijschrijven (vier nieuwe asserts, 54 totaal). Daarnaast: de link-herschrijfregex samengetrokken in de gedeelde helper `Convert-RootRelativeLinks`, drie doc-correcties van Edith (typo "Rendall's" in de gefolde #61-entry, de niet-meebewogen `cut-release.ps1`-samenvatting in Rendall's lens, de ontbrekende `Plugins:`-afleiding in README-stap 6), en het werkdossier `dossiers/review-herkansing-61.md` met de uitkomst en zeven bewust geparkeerde verbeterpunten.

[PR #65](https://github.com/DaveKJohn/davekjohns-workshop/pull/65)

---

### #63 · Connectors-check kent het plugin-pad van repo-lenzen · Fix · 2026-07-17

`check-connectors.ps1` en `check-consumer-drift.ps1` zochten repo-lenzen alleen op het legacy-pad (`.claude/extensions/`), terwijl life-hub en smartwatchbanden hun lenzen inmiddels in `.claude/plugins/claude-specialists/<plugin>/` hebben staan — dat gaf valse "extension(s) ontbreken"-fouten en een persona-drift-check die stil in het luchtledige draaide. Beide scripts kennen nu beide locaties (plugin-pad eerst, legacy als terugval). Daarnaast: `06-23` (Sean) geregistreerd in het smartwatchbanden-manifest, en twee testgevallen toegevoegd voor de nieuwe lay-out (happy path + INFO-signaal vanaf het plugin-pad).

[PR #63](https://github.com/DaveKJohn/davekjohns-workshop/pull/63)

---

### #62 · Fold-plugindetectie hoofdlettergevoelig gemaakt (advies Sean) · Fix · 2026-07-16

Sean's advies uit de review van #61 verwerkt: de plugin-detectie in `fold-changelog-entry.ps1`
gebruikt nu `-cmatch` in plaats van het case-insensitieve `-match`, zodat de
kleine-letters-tekenklasse doet wat hij belooft en een vreemd-gecapitaliseerd pad geen ruis in de
`Plugins:`-regel kan zetten. Cosmetisch/defensief; het schrijfpad was al veilig.

[PR #62](https://github.com/DaveKJohn/davekjohns-workshop/pull/62)

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

Plugins: specialists, specialists-lifehub, specialists-shopify

[PR #61](https://github.com/DaveKJohn/davekjohns-workshop/pull/61)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.4.1] - 2026-07-16 — Patch

Zie [releases/development/1.4/1.4.1.md](releases/development/1.4/1.4.1.md) voor de volledige release-notes.

---

### [v1.4.0] - 2026-07-16 — Minor

Zie [releases/development/1.4/1.4.0.md](releases/development/1.4/1.4.0.md) voor de volledige release-notes.

---

### [v1.3.0] - 2026-07-16 — Minor

Zie [releases/development/1.3/1.3.0.md](releases/development/1.3/1.3.0.md) voor de volledige release-notes.

---

### [v1.2.0] - 2026-07-16 — Minor

Zie [releases/development/1.2/1.2.0.md](releases/development/1.2/1.2.0.md) voor de volledige release-notes.

---

### [v1.1.1] - 2026-07-15 — Patch

Zie [releases/development/1.1/1.1.1.md](releases/development/1.1/1.1.1.md) voor de volledige release-notes.

---

### [v1.1.0] - 2026-07-15 — Minor

Zie [releases/development/1.1/1.1.0.md](releases/development/1.1/1.1.0.md) voor de volledige release-notes.

---

### [v1.0.0] - 2026-07-14 — Major

Zie [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) voor de volledige release-notes.
