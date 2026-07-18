---
name: fold-changelog
description: >-
  Vouw de changelog entry-bestanden van een branch in CHANGELOG.md via het gedeelde,
  gecentraliseerde fold-script uit de plugin (single source of truth, issue #81) -- zodat een
  consument dit script niet lokaal hoeft te dupliceren. Gebruik dit op main, direct na het mergen
  van een branch, om de entry-bestanden (<branch-naam>.md in de repo-root) in de ## Pull Requests-
  sectie te vouwen en daarna te verwijderen.
---

# fold-changelog — de gedeelde fold voor consumenten

Dit is de **plugin-spiegel** van `fold-changelog-entry.ps1`: dezelfde geteste bron als in de
werkplaats-repo, hier gedeeld zodat consumenten (life-hub, smartwatchbanden, …) hem niet dupliceren.
De achtergrond staat in [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81).

## Wat de skill doet

Draai het gedeelde script vanuit de **root van de consumerende repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/fold-changelog-entry.ps1" -Branch <prefix>/<naam>
```

Zonder `-Branch` vouwt het alle aanwezige entry-bestanden in de root. Het script:

1. Vouwt elk entry-bestand (`<branch-naam-met-koppeltekens>.md`) in de `## Pull Requests`-sectie van
   `CHANGELOG.md`, met het PR-nummer + de link erbij (opgehaald via `gh pr list`).
2. Verwijdert het entry-bestand daarna.

Commit het resultaat (`CHANGELOG.md` + de verwijderde entry-bestanden) daarna rechtstreeks op main.

## Vereisten in de consument

Het script is repo-agnostisch, maar leest een klein blokje repo-data uit de **root** van de consument
(dual-context: het lost de repo-root op via `${CLAUDE_PROJECT_DIR}`):

- `scripts/repo-config.ps1` met `Get-RepoName` (voor de `gh --repo`-calls).
- `scripts/lib/branch-info.ps1` (voor de branch-/type-afleiding).
- Een `CHANGELOG.md` met een `## Pull Requests`-sectie in het verwachte format.
- `git` en een ingelogde `gh` CLI.

Ontbreekt `repo-config.ps1` of `branch-info.ps1`, neem dan eerst het repo-config-patroon over (zie de
werkplaats-repo als model) voordat je deze skill gebruikt.

## Belangrijk

- **Draai dit op main, na de merge** (nadat de PR is gemergd) — dan bestaat het PR-nummer.
- Het script raakt alleen `CHANGELOG.md` + de entry-bestanden aan; verder niets.
- De bron van dit script woont in de werkplaats-repo; wijzig het niet lokaal in de consument. Een
  wijziging landt eerst in de bron (`scripts/release/fold-changelog-entry.ps1`) en reist daarna via
  een release naar de plugin-spiegel — bewaakt door de shared-scripts-drift-lint.
