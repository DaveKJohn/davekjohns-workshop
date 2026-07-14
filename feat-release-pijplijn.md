### Repo-brede release-pijplijn: cut-release.ps1 (lockstep-versiebump, git-tag, CHANGELOG-Releases) · Feat · 2026-07-14

De grootste ontbrekende schakel — Rendalls kernrol — is nu operationeel. Nieuw:
`scripts/release/cut-release.ps1` snijdt een **repo-brede release**: alle plugin-versies bumpen in
**lockstep**, de gevouwen `## Pull Requests`-entries verhuizen naar een nieuw `### vX.Y.Z`-blok onder
`## Releases`, en de staat wordt getagd als `vX.Y.Z` (git-tag + CHANGELOG, géén GitHub Release —
Dave's keuze). De cut verloopt in twee fasen via een `release/vX.Y.Z`-branch + PR (prepare) en een
tag-stap op `master` na de merge. De pure logica (versie-bump + CHANGELOG-transformatie) woont in
`scripts/lib/release-lib.ps1`, afgedekt door de eerste testsuite van de repo
`scripts/tests/release-lib.tests.ps1` (17 asserts, dependency-vrij). `branch-info.ps1` kreeg een
`release`-prefix. Docs (README, CLAUDE.md, Rendall/Sylvester/Tycho-lenzen) bijgewerkt — de
"buiten scope"-vermeldingen zijn vervangen door de echte pijplijn.