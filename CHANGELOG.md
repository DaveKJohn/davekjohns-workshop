# Changelog

De geschiedenis van de claude-specialists-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `master` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #5 · changelog + PR-workflow geport vanuit life-hub (branch-lib, scripts, plugin-lint, PR-template, CHANGELOG-backfill) · Feat · 2026-07-14

Dezelfde changelog- + PR-workflow als life-hub, geport en aangepast aan dit plugin-pakket-repo (default-branch `master`, geen Brains/geen roster).

- `scripts/lib/branch-info.ps1` — prefix-tabel voor dit repo: `feat`→Feat, `fix`→Fix, `docs`→Docs, `chore`→Chore (label enhancement/bug/documentation).
- `scripts/release/{new-changelog-entry,open-pr,fold-changelog-entry}.ps1` — geport; `master` i.p.v. `main`, repo `DaveKJohn/claude-specialists`, lint-poort via de nieuwe plugin-lint.
- `scripts/lint/check-plugin-integrity.ps1` — nieuwe lint-poort: valideert `marketplace.json` + elke `plugin.json`, agent-def-frontmatter (name/id/group) en dode links in README/SKILL.md.
- `.github/pull_request_template.md` — met de nieuwe type-checklist.
- `CHANGELOG.md` — nieuw, met `## Pull Requests` (#1-#4 gebackfilld) + `## Releases`.
- `README.md` — sectie "Bijdragen — changelog & PR-workflow".

Releases/versioning (per-plugin via `plugin.json`) blijven bewust buiten scope.

[PR #5](https://github.com/DaveKJohn/claude-specialists/pull/5)

---

### #4 · start-task-skill toegevoegd aan specialists-shopify · Feat · 2026-07-14

De Shopify-domeingroep `specialists-shopify` kreeg naast de 3 subagents ook de skill `start-task`
(dunne wrapper om `scripts/task/start-task.ps1`: nieuwe branch + Shopify preview-thema). Bij het
consolideren van groep 3 in de gedeelde marketplace verhuisde die skill mee; de aanroep werd
`/specialists-shopify:start-task`.

[PR #4](https://github.com/DaveKJohn/claude-specialists/pull/4)

---

### #3 · marketplace opgesplitst in drie plugin-groepen (core + lifehub + shopify) · Feat · 2026-07-14

De marketplace huisvestte alleen groep 1 (de gedeelde kern, plugin `specialists`). Nu wonen alle
drie de groepen hier, elk als eigen plugin — `specialists` (groep 1, globaal), `specialists-lifehub`
(groep 2: Astrid, Fiona, Hugo, Ian, Onyx) en `specialists-shopify` (groep 3: Liam, Sandra, Steven) —
zodat elke consumerende repo per plugin aan/uit schakelt.

[PR #3](https://github.com/DaveKJohn/claude-specialists/pull/3)

---

### #2 · Consumptie-sectie bijwerken naar github-source · Docs · 2026-07-14

De README beschreef de marketplace nog als lokale `directory`-source; bijgewerkt naar de remote
`github`-source (`DaveKJohn/claude-specialists`) die de consumerende repo's nu gebruiken —
machine-onafhankelijk, want de Claude Code CLI clonet en cachet het repo zelf.

[PR #2](https://github.com/DaveKJohn/claude-specialists/pull/2)

---

### #1 · drift-lint voor gedeelde agent-defs (optie e) · Feat · 2026-07-14

`scripts/lint/check-consumer-drift.ps1` toegevoegd: vergelijkt (read-only) een eventuele verouderde
lokale agent-def-kopie in een consumerende repo met de canonieke versie hier en meldt
`MISSING`/`IDENTICAL`/`DRIFTED`.

[PR #1](https://github.com/DaveKJohn/claude-specialists/pull/1)

---

## Releases

Nog geen releases vastgelegd. Versiebeheer loopt per plugin via de `version` in elke `plugin.json`;
een repo-brede release-pijplijn is (nog) buiten scope.
