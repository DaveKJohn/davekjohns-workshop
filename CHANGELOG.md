# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #87 · specialists-init scaffoldt repo-config + branch-info; open-pr/fold pre-flighten (schone consument) · Fix · 2026-07-19

Dicht het script-afhankelijkheden-gat van de gedeelde workflow-skills op een schone consument (inbound
[#86](https://github.com/DaveKJohn/davekjohns-workshop/issues/86), vervolg op [#81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81)).
`open-pr`/`fold` leunen op twee repo-eigen bestanden in de consument-root (`scripts/repo-config.ps1` +
`scripts/lib/branch-info.ps1`) die de bootstrap niet neerzette — bij een eerste install liep dat op een
rauwe dot-source-fout.

- **Bootstrap-scaffold:** `specialists-init/bootstrap.ps1` zet beide bestanden nu additief als
  `VUL-IN`-scaffold neer (nooit overschrijven), met een **lege** branch-prefix-tabel — de taxonomie is
  per repo anders en wordt bewust niet meegebakken.
- **Pre-flight:** `open-pr` (beide bestanden) en `fold` (alleen `repo-config`) checken vóór de
  dot-source op aanwezigheid én op niet-ingevulde `VUL-IN`-placeholders, en stoppen anders met een
  duidelijke wegwijzer i.p.v. een rauwe fout. De spiegels zijn via de generator opnieuw gegenereerd.
- **Tests:** bootstrap-drift dekt de scaffold + idempotentie; shared-scripts dekt het pre-flight-gedrag
  van beide bron-scripts.
- **Docs:** de skill-teksten (`specialists-init`, `open-pr`, `fold-changelog`) en de plugin-scripts-README
  volgen het nieuwe gedrag; de fold-vereisten corrigeren meteen dat fold géén `branch-info` gebruikt.

Plugins: specialists

[PR #87](https://github.com/DaveKJohn/davekjohns-workshop/pull/87)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.9.0] - 2026-07-19 — Minor

Zie [releases/development/1.9/1.9.0.md](releases/development/1.9/1.9.0.md) voor de volledige release-notes.

---

### [v1.8.0] - 2026-07-18 — Minor

Zie [releases/development/1.8/1.8.0.md](releases/development/1.8/1.8.0.md) voor de volledige release-notes.

---

### [v1.7.0] - 2026-07-18 — Minor

Zie [releases/development/1.7/1.7.0.md](releases/development/1.7/1.7.0.md) voor de volledige release-notes.

---

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
