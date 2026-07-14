### releases/-map: release-notes per versie + overzichtstabel, CHANGELOG verwijst ernaar · Feat · 2026-07-14

Naar het model van life-hub (maar zonder GitHub Releases) krijgt de repo een **`releases/`-map**: per
versie een volledig notes-bestand `releases/development/<X.Y>/<X.Y.Z>.md` (uit de `## Pull Requests`-entries,
gegroepeerd per branch-type) plus een overzichtstabel `releases/README.md`. Het `## Releases`-blok in
`CHANGELOG.md` wordt voortaan een korte **verwijzing** naar dat notes-bestand in plaats van de volledige
inhoud inline.

- `cut-release.ps1` herzien: genereert de notes + de tabelrij, zet de CHANGELOG-verwijzing, met `-Title`
  voor een korte release-omschrijving.
- `release-lib.ps1`: nieuwe pure helpers `Get-BumpType`, `Get-PullRequestEntries`, `Build-ReleaseNotes`
  (+ herschrijving van repo-root-relatieve links met `../../../` zodat ze vanuit de diepere notes-locatie
  kloppen); `Convert-ChangelogForRelease` produceert nu de verwijzing.
- De lint-poort scant nu ook `CHANGELOG.md` en `releases/**` op dode links.
- **v1.0.0 gebackfilld**: `releases/development/1.0/1.0.0.md` + `releases/README.md` aangemaakt en het
  inline v1.0.0-blok in `CHANGELOG.md` vervangen door de verwijzing.
- Tests uitgebreid naar 31 asserts (de nieuwe helpers + de link-herschrijving). Docs bijgewerkt
  (README, `CLAUDE.md`, Rendall-manual, Sylvester/Tycho-lenzen).