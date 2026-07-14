# Changelog

De geschiedenis van de claude-specialists-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `master` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #18 · Bootstrap-adoptiepad: persona-sjablonen + specialists-init-skill · Feat · 2026-07-14

Dicht het adoptie-/bootstrap-gat: een verse repo die de `specialists`-plugin inschakelt kreeg wél de
werker-subagents, maar niet de dirigent (Chris) of de governance-/hooks-laag — die kunnen niet uit
een plugin komen (een plugin injecteert geen hoofdloop-context en bewerkt geen `CLAUDE.md`).
Opgelost via een hybride C+A:

- **C — canonieke bron.** Nieuwe map `specialists/personas/` met self-contained sjablonen voor de
  hoofdloop-persona's (Chris `01-01`, Derek `05-05`, Rendall `05-06`): draagbare body + een
  repo-lens-placeholder. Bewust géén agent-def (persona's draaien in de hoofdloop, niet als subagent).
- **A — levering.** Repo-neutrale skill `specialists/skills/specialists-init/` met `bootstrap.ps1`:
  kopieert de sjablonen naar `.claude/extensions/<g>-<id>-extension.md` (nooit overschrijven), zet de
  `@`-import onderaan `CLAUDE.md`, en schrijft een `settings.suggested.jsonc` (`permissions.deny` +
  hooks-stub; raakt `settings.json` niet aan). Documenteert de kip-en-ei stap 0 + de herstart-les.
- **Lint.** `check-plugin-integrity.ps1` valideert nu persona-frontmatter + bestandsnaam (check 3c),
  neemt personas mee in de link/anchor-scan, en parse-checkt ook plugin-skill-scripts; sectie 6 laat
  persona's bewust met rust. `check-consumer-drift.ps1` vergelijkt daarnaast de draagbare persona-body
  tegen de consument-kopie (informatief — telt niet mee in de exit-code).
- **Docs.** `README.md` (persona-artefact + sectie "Adoptie: het bootstrap-pad" + drift-uitleg),
  `CLAUDE.md` (structuur) en `.claude/README.md` (persona-representatie) bijgewerkt. `plugin.json`
  erkent de repo-neutrale skill als bewuste uitzondering op "geen skills".

Niet-brekend geverifieerd: lint groen, drift-lint tegen life-hub én smartwatchbanden toont 0 gedrifte
agent-defs (persona's informatief `DRIFTED` — de handgeschreven kopieën, later gecoördineerd te
reconciliëren). Bootstrap end-to-end + idempotentie getest tegen een verse wegwerp-consument.

[PR #18](https://github.com/DaveKJohn/claude-specialists/pull/18)

---

### #17 · Lint-poort: specialisten-systeem-integriteit (id-uniek, agent-def<->manual-paring) + code-spans overslaan bij link-scan · Feat · 2026-07-14

Punt 2 uit het consistentie-onderzoek: de bron-repo van het specialisten-systeem hoort minstens zo
streng te controleren als een consument. Nieuwe **check 6** in
[`check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1): per plugin is elk
`<group>-<id>` uniek over de agent-defs, heeft elke agent-def een geldige `name:` (Claude
Code-aanroepnaam) plus een bijbehorende `manuals/<g>-<id>-manual.md` die hij ook noemt, en heeft elke
manual omgekeerd een agent-def (geen wees-manual). Overgenomen uit life-hub's lint-brain, aangepast op
de plugin-topologie (de roster→lens-koppeling wordt al door de dode-link-scan gedekt; de
`## Eigen aan deze repo`-tweedeling zit hier tussen twee bestanden en is dus niet als within-file-check
overgenomen).

Onderweg een **latente bug** in de link/anchor-scan gevonden en gefixt: de scan behandelde
link-achtige tekst binnen inline-/fenced-code als echte links. Daardoor werd een illustratief
voorbeeld in een changelog-entry (via de fold-commit, zonder lint-gate, op master beland) ten onrechte
als kapotte anchor gemeld. De scan slaat code-spans nu over.

[PR #17](https://github.com/DaveKJohn/claude-specialists/pull/17)

---

### #16 · Lint-poort: CLAUDE.md + .claude/extensions/ meegescand en anchor-validatie toegevoegd; drift-lint docstring gecorrigeerd · Feat · 2026-07-14

Uit de vergelijking met life-hub bleek dat de lint-poort juist de link-dichtste bestanden niet dekte.
Twee punten opgepakt:

- **Lint-poort uitgebreid** ([`check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1)):
  de dode-link-scan omvat nu ook `CLAUDE.md` en elke `.claude/extensions/*.md`, én er is
  **anchor-validatie** bijgekomen — een `[..](file.md#anchor)` of `[..](#anchor)` faalt de poort als
  die anchor niet als kop in het doelbestand bestaat (GitHub-slugregels, incl. duplicaat-suffixen en
  het overslaan van code-fences). Vangt nu 24 bestaande kruisverwijzings-anchors af; geverifieerd dat
  een bewust kapotte anchor wordt betrapt.
- **Drift-lint docstring gecorrigeerd** ([`check-consumer-drift.ps1`](scripts/lint/check-consumer-drift.ps1)):
  de topologie-beschrijving zei nog "lokale directory-marketplace-source", terwijl life-hub én swb de
  remote `github`-source gebruiken (zoals de README al beschrijft).

Voortgekomen uit het consistentie-onderzoek claude-specialists ↔ life-hub. Dat onderzoek bevestigde
ook dat groep 1 een schone gedeelde kern vormt voor beide consumenten (nul drift).

[PR #16](https://github.com/DaveKJohn/claude-specialists/pull/16)

---

### #15 · releases/-map: release-notes per versie + overzichtstabel, CHANGELOG verwijst ernaar · Feat · 2026-07-14

Naar het model van life-hub (maar zonder GitHub Releases) krijgt de repo een **`releases/`-map**: per
versie een volledig notes-bestand `releases/development/<X.Y>/<X.Y.Z>.md` (uit de `## Pull Requests`-entries,
gegroepeerd per branch-type) plus een overzichtstabel `releases/README.md`. Het `## Releases`-blok in
`CHANGELOG.md` wordt voortaan een korte **verwijzing** naar dat notes-bestand in plaats van de volledige
inhoud inline.

- `cut-release.ps1` herzien: genereert de notes + de tabelrij, zet de CHANGELOG-verwijzing, met `-Title`
  voor een korte release-omschrijving.
- `release-lib.ps1`: nieuwe pure helpers `Get-BumpType`, `Get-PullRequestEntries`, `Build-ReleaseNotes`
  (+ herschrijving van repo-root-relatieve links met `../../../` zodat ze vanuit de diepere notes-locatie
  kloppen); `Convert-ChangelogForRelease` produceert nu de verwijzing.
- De lint-poort scant nu ook `CHANGELOG.md` en `releases/**` op dode links.
- **v1.0.0 gebackfilld**: `releases/development/1.0/1.0.0.md` + `releases/README.md` aangemaakt en het
  inline v1.0.0-blok in `CHANGELOG.md` vervangen door de verwijzing.
- Tests uitgebreid naar 31 asserts (de nieuwe helpers + de link-herschrijving). Docs bijgewerkt
  (README, `CLAUDE.md`, Rendall-manual, Sylvester/Tycho-lenzen).

[PR #15](https://github.com/DaveKJohn/claude-specialists/pull/15)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.0.0] - 2026-07-14 — Major

Zie [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) voor de volledige release-notes.
