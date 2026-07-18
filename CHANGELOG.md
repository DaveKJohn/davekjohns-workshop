# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

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

Plugins: specialists

[PR #80](https://github.com/DaveKJohn/davekjohns-workshop/pull/80)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

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
