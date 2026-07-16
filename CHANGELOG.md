# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #59 · Nacorrecties van Victor en Edith op de lens-scaffolds · Fix · 2026-07-16

Nacorrecties op de in v1.4.0 uitgebrachte lens-scaffolds. Van Victor: de versie-sortering in de
cache-layout sorteert nu semantisch via `[version]` (een string-sort zette 1.9.0 boven 1.10.0),
mét een cache-layout-regressietest (1.9.0 naast 1.10.0), een waarschuwing bij een ongeldige
plugin-slug en een verhelderende comment over de dubbele rol van `$parent`. Van Edith: het
"1b."-lijstitem in SKILL.md rendert niet als lijstitem (hernummerd naar 1–4), een onvolledige zin
hersteld, de scaffold-H1 volgt nu de bestaande lens-titelconventie (middot via `[char]0x00B7`,
ASCII-regel), en "lens-sjabloon"/"leeg" zijn geharmoniseerd naar "lege lens-scaffold".

[PR #59](https://github.com/DaveKJohn/davekjohns-workshop/pull/59)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

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
