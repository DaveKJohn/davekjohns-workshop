# Changelog

De geschiedenis van de claude-specialists-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `master` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #15 · releases/-map: release-notes per versie + overzichtstabel, CHANGELOG verwijst ernaar · Feat · 2026-07-14

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

[PR #15](https://github.com/DaveKJohn/claude-specialists/pull/15)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.0.0] - 2026-07-14 — Major

Zie [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) voor de volledige release-notes.
