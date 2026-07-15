### Hoofdbranch hernoemd: `master` → `main` in scripts en docs · Fix · 2026-07-15

Op GitHub is de standaardbranch van deze repo hernoemd van `master` naar `main`. De lokale clone is
gelijkgezet (branch hernoemd, tracking op `origin/main`), en alle verwijzingen naar de hoofdbranch
zijn meegenomen:

- **Scripts:** de vangrails en doelen in `open-pr.ps1` (`--base main`, weiger-op-hoofdbranch),
  `new-changelog-entry.ps1`, `cut-release.ps1` (release-commit, push, tag) en de commentaar/help-tekst
  in `fold-changelog-entry.ps1`, `branch-info.ps1` en `check-plugin-integrity.ps1`.
- **Docs & manuals:** `CLAUDE.md` (safety-invulling), `README.md`, `.claude/README.md`, de
  changelog-koptekst, en de repo-lenzen van Chris #01, Derek #05 (incl. het kopje "Mergen naar main"),
  Rendall #06 en Sylvester #15.

Historische records (`releases/development/1.0/1.0.0.md`, gevouwen changelog-entries) blijven bewust
ongewijzigd — die beschrijven het verleden. Beide testsuites en de lint-poort zijn groen.
