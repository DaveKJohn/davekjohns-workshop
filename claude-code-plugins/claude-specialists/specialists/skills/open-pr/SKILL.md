---
name: open-pr
description: >-
  Push de huidige branch en open een Pull Request naar main via het gedeelde, gecentraliseerde
  open-pr-script uit de plugin (single source of truth, issue #81) -- zodat een consument dit script
  niet lokaal hoeft te dupliceren. Draait eerst de repo-eigen lint- en test-poort; bij een fout wordt
  er niet gepusht en geen PR geopend. Gebruik dit wanneer een branch klaar is en de PR mag worden
  geopend (op expliciet verzoek).
---

# open-pr — de gedeelde PR-opener voor consumenten

Dit is de **plugin-spiegel** van `open-pr.ps1`: dezelfde geteste bron als in de werkplaats-repo, hier
gedeeld zodat consumenten hem niet dupliceren. Achtergrond in
[issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81).

## Wat de skill doet

Draai het gedeelde script vanuit de **root van de consumerende repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/open-pr.ps1" -Title "feat: korte titel"
```

Het script:

1. Draait de **repo-eigen lint-poort** (via `Get-LintScript` uit `repo-config`) en daarna **alle
   testsuites** (`scripts/tests/*.tests.ps1`) -- exact zoals CI. Een fout blokkeert: er wordt niet
   gepusht en geen PR geopend. `-SkipLint` / `-SkipTests` zijn de bewuste noodkleppen.
2. Pusht de huidige branch en opent een PR naar `main` via `gh`, met een label op basis van het
   branch-prefix en een vooraf ingevulde PR-body uit `.github/pull_request_template.md` +
   het changelog entry-bestand.

## Vereisten in de consument

Het script is repo-agnostisch, maar leest zijn repo-data uit de **root** van de consument
(dual-context via `${CLAUDE_PROJECT_DIR}`):

- `scripts/repo-config.ps1` met `Get-RepoName` (de `gh --repo`-doel) en `Get-LintScript`
  (repo-root-relatief pad naar de eigen lint-poort).
- `scripts/lib/branch-info.ps1` (label/type uit het branch-prefix).
- `scripts/tests/*.tests.ps1` (de test-poort; conventie, geen config).
- `.github/pull_request_template.md`, `git` en een ingelogde `gh` CLI.

## Belangrijk

- **Een PR wordt alleen geopend op expliciet verzoek** -- dat blijft de governance-regel van de repo,
  los van dit script.
- De bron van dit script woont in de werkplaats-repo; wijzig het niet lokaal in de consument. Een
  wijziging landt eerst in de bron (`scripts/release/open-pr.ps1`) en reist daarna via een release naar
  de plugin-spiegel -- bewaakt door de shared-scripts-drift-lint.
