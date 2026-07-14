### changelog + PR-workflow geport vanuit life-hub (branch-lib, scripts, plugin-lint, PR-template, CHANGELOG-backfill) · Feat · 2026-07-14

Dezelfde changelog- + PR-workflow als life-hub, geport en aangepast aan dit plugin-pakket-repo (default-branch `master`, geen Brains/geen roster).

- `scripts/lib/branch-info.ps1` — prefix-tabel voor dit repo: `feat`→Feat, `fix`→Fix, `docs`→Docs, `chore`→Chore (label enhancement/bug/documentation).
- `scripts/release/{new-changelog-entry,open-pr,fold-changelog-entry}.ps1` — geport; `master` i.p.v. `main`, repo `DaveKJohn/claude-specialists`, lint-poort via de nieuwe plugin-lint.
- `scripts/lint/check-plugin-integrity.ps1` — nieuwe lint-poort: valideert `marketplace.json` + elke `plugin.json`, agent-def-frontmatter (name/id/group) en dode links in README/SKILL.md.
- `.github/pull_request_template.md` — met de nieuwe type-checklist.
- `CHANGELOG.md` — nieuw, met `## Pull Requests` (#1-#4 gebackfilld) + `## Releases`.
- `README.md` — sectie "Bijdragen — changelog & PR-workflow".

Releases/versioning (per-plugin via `plugin.json`) blijven bewust buiten scope.