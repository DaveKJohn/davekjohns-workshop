# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #58 · Lens-scaffolds bij adoptie: elke specialist krijgt een leeg VUL-IN-sjabloon · Feat · 2026-07-16

Wens van Dave: bij adoptie moet direct zichtbaar zijn wáár repo-specifieke taken per specialist
worden aangevuld. `bootstrap.ps1` (skill `specialists-init`) zet nu — naast de persona-kopieën —
voor elke subagent van de ingeschakelde plugin(s) een leeg lens-scaffold neer in
`.claude/extensions/<g>-<id>-extension.md`: frontmatter + duidelijke `VUL-IN`-markering, nooit
overschrijvend, werkend in zowel de bron- als de plugin-cache-layout. Een install-hook bestaat
niet en de sessie-hook blijft bewust read-only; het bootstrap-adoptiepad is dus de plek. SKILL.md,
root-README en de bootstrap-testsuite (20 asserts) bewegen mee.

[PR #58](https://github.com/DaveKJohn/davekjohns-workshop/pull/58)

---

### #57 · Nacorrecties van Victor op de test-poort · Fix · 2026-07-16

Twee nacorrecties uit Victor's review van PR #56: het root-README beschrijft de PR-flow nu met de
dubbele poort (lint + tests) in plaats van alleen de lint-poort, en de test-poort in `open-pr.ps1`
waarschuwt voortaan expliciet wanneer er nul testsuites gevonden worden in plaats van stilzwijgend
te slagen. Victor's helper-suggestie (gedeeld poort-patroon) is bewust geparkeerd tot er een derde
poort bijkomt.

[PR #57](https://github.com/DaveKJohn/davekjohns-workshop/pull/57)

---

### #56 · Test-poort in open-pr.ps1: alle suites draaien voor elke PR · Feat · 2026-07-16

De les van PR #54 (een rode testsuite viel pas op CI op) geborgd volgens de automation-first-regel:
`open-pr.ps1` draait na de lint-poort nu ook een **test-poort** — alle `scripts/tests/*.tests.ps1`,
exact zoals CI — en blokkeert de push + PR bij een falende suite (`-SkipTests` is de noodklep).
Dereks lens en de safety-invulling in `CLAUDE.md` beschrijven de dubbele poort.

[PR #56](https://github.com/DaveKJohn/davekjohns-workshop/pull/56)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

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
