### Fase 2: open-pr gedeeld als plugin-spiegel (lint-gate via repo-config) · Feat · 2026-07-19

Tweede stap van Fase 2 uit [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81): `open-pr.ps1` wordt gedeeld met consumenten als plugin-spiegel, met dezelfde mechaniek als de fold-pilot.

- **`open-pr.ps1` dual-context** gemaakt (repo-root via `${CLAUDE_PROJECT_DIR}` of git-root); `repo-config` + `branch-info` uit de repo-root i.p.v. `$PSScriptRoot`.
- **Lint-gate geparametriseerd:** het repo-specifieke lint-script komt nu uit `Get-LintScript` in `repo-config` (workshop: `check-plugin-integrity`; een consument kan zijn eigen lint opgeven). De test-poort blijft conventie (`scripts/tests/*.tests.ps1`). Gate-meldingen zijn generiek gemaakt.
- **Spiegel + skill:** `open-pr` geregistreerd in `shared-scripts-lib.ps1`, spiegel gegenereerd, en een consument-skill `open-pr` toegevoegd.
- **Tests/docs:** `repo-config.tests.ps1` dekt `Get-LintScript`; `shared-scripts.tests.ps1` borgt dual-context voor álle gedeelde scripts; de README-statustabel bijgewerkt.

Daarmee zijn beide Fase 2-doelscripts (`fold` + `open-pr`) gedeeld; `branch-info`/`repo-config` blijven bewust per repo lokaal (CI-pin + repo-data).