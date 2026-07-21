# Changelog — specialists-lifehub

Consumer-facing history of this plugin: per release, the changes that touched this plugin.
Automatically appended by `cut-release.ps1` of the marketplace repo (davekjohns-workshop); the full
workshop history lives there in `CHANGELOG.md` and `releases/`.

## v1.13.0 — 2026-07-21

### #119 · Ship a per-plugin RELEASE.md card so consumers see which release they are on · Feat · 2026-07-21

Every plugin now carries a `RELEASE.md` card (version, one-line summary, and the entries for that
version) right next to its `CHANGELOG.md`. Chosen approach: **Model A, plugin-authored** — the card
lives inside the plugin folder and travels with the plugin cache via `claude plugin update`, so a
consumer can see exactly which release they're on without cross-referencing the workshop's own
`releases/` history. `cut-release.ps1` (re)generates the card for every plugin, in lockstep, on
every release; the lint gate's new check 9 guards that the card is present and its `vX.Y.Z` matches
that plugin's `plugin.json`. Deliberately **no SessionStart hook** announces this — the card is
discovered by opening the file in the plugin cache. Seeded on v1.12.1.

[PR #119](https://github.com/DaveKJohn/davekjohns-workshop/pull/119)

---

### #117 · English names for agent-shared blocks + script-comment translations · Docs · 2026-07-21

Completed the in-progress English-norm cleanup of the agent-shared machinery. Renamed the four verbatim-shared source blocks to English file names (`grens-inbound` → `inbound-behaviour`, `gedrag-taalkeuze` → `language-behavior`, `grens-webcontent` → `webcontent-boundary`, `grens-artifact-publish` → `artifact-publishing-boundary`) and pulled the whole chain along: the `shared:<name>` sentinels in all 21 agent defs across the three plugins, the generator-lib docstring, and the current-doc references in `README.md` and Ravi's lens. Also folded in the NL→EN comment translation of `connector-sessioncheck.ps1` and `bootstrap.ps1`. Functional/canonical markers deliberately keep their original form per the language convention's technical-identifier exception — the `VUL-IN` scaffold sentinel and a couple of marker phrases the drift tests key on stay as-is. History (`CHANGELOG.md` files, `releases/`) is left untouched. Generator, lint (0 errors), and all test suites are green.

[PR #117](https://github.com/DaveKJohn/davekjohns-workshop/pull/117)

---

## v1.12.0 — 2026-07-20

### #109 · Shared block for the language directive (Ravi) · Feat · 2026-07-20

Phase B left the closing "respond in the user's language" line verbatim-identical in 19 of the 20
agent defs. Ravi's duplication check recommended promoting it to a single source via the existing
`agent-shared/` mechanism — no new machinery needed, since the generator is line-based.

- **New source `agent-shared/gedrag-taalkeuze.md`** with the canonical line; the 19 identical agent
  defs now carry it between `<!-- BEGIN/END shared:gedrag-taalkeuze -->` sentinels, filled and
  verified by `build-agent-defs.ps1` like the `grens-*` blocks.
- **03-07 (Rebecca) stays local:** its line has a deliberate source-quoting nuance ("...quoting
  sources in another language is fine") — a near-duplicate that Ravi's own rule says not to force-merge.
- **Ravi's lens (06-24)** scope updated: the shared-block circle now names a third category
  (standalone behavior directives outside Boundaries/Working method) and lists `gedrag-taalkeuze`.

Naming note: the new source keeps the Dutch-style name of its `grens-*` siblings for uniformity;
renaming the whole `agent-shared/` set to English is a later-phase consistency item.

[PR #109](https://github.com/DaveKJohn/davekjohns-workshop/pull/109)

---

### #106 · Workshop switched to English — phase B: plugin content · Feat · 2026-07-20

Follow-up to phase A (#105): the shipped plugin content itself is now English, so consumers
worldwide read an English team. Covers all three plugins.

- **Translated:** the 20 agent definitions (prose outside the shared sentinel blocks), all 26
  manuals/playbooks, the 4 personas, `agent-shared/` (the canonical shared-bullet source), the
  three core skills + the shopify `start-task` skill, `specialists/scripts/README.md`, and the
  intro paragraphs of the three plugin `CHANGELOG.md` files (release history left as written).
- **Shared blocks regenerated:** `build-agent-defs.ps1` refilled every `<!-- BEGIN/END shared -->`
  region from the translated `agent-shared/`, so the sentinel content is English and byte-in-sync
  in all 20 agent defs.
- **Language directive aligned with the approved policy:** each agent def ended with a hard
  "work in Dutch" instruction. That contradicts the phase-A Language policy (specialists reply in
  the language the user writes in) and the worldwide-sharing goal, so all 20 now read "Respond in
  the language the user addresses you in." This is a behavior change beyond pure translation —
  flagged for review.
- **Slot-heading canon:** the human-readable `## Specific to this repo` section heading is now
  used consistently across manuals, lenses, and CLAUDE.md.

**Deliberately deferred to a later phase (scripts):** the machine-coupled Dutch marker
`## Eigen aan deze repo` still lives in `bootstrap.ps1` (the scaffold it writes),
`check-consumer-drift.ps1` (`Get-PortableBody` splits on it) and its test fixture; likewise the
`[FOUT]`/`[DRIFTED]` signal tokens, the `VUL-IN` scaffold marker, and the three Dutch PR-template
strings `open-pr.ps1` matches. Migrating those to English needs bilingual back-compat for
consumers that still carry the Dutch slot — a dedicated scripts phase. Lint and all seven test
suites pass.

[PR #106](https://github.com/DaveKJohn/davekjohns-workshop/pull/106)

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

## v1.5.1 — 2026-07-18

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
