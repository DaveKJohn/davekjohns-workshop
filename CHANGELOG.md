# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

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

Plugins: specialists

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

Plugins: specialists

[PR #75](https://github.com/DaveKJohn/davekjohns-workshop/pull/75)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.6.0] - 2026-07-18 — Minor

Zie [releases/development/1.6/1.6.0.md](releases/development/1.6/1.6.0.md) voor de volledige release-notes.

---

### [v1.5.2] - 2026-07-18 — Patch

Zie [releases/development/1.5/1.5.2.md](releases/development/1.5/1.5.2.md) voor de volledige release-notes.

---

### [v1.5.1] - 2026-07-18 — Patch

Zie [releases/development/1.5/1.5.1.md](releases/development/1.5/1.5.1.md) voor de volledige release-notes.

---

### [v1.5.0] - 2026-07-17 — Minor

Zie [releases/development/1.5/1.5.0.md](releases/development/1.5/1.5.0.md) voor de volledige release-notes.

---

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
