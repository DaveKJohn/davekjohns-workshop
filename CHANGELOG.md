# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #26 · Versie-poort-les: zonder bump geen plugin-update bij consumenten · Docs · 2026-07-15

Geleerde les van de v1.1.0-release geborgd in `README.md` (Versiebeheer) en Rendalls lens
(`.claude/extensions/05-06-extension.md`): het `version`-nummer in `plugin.json` is niet alleen een
marker maar de **update-poort** — `claude plugin update` vergelijkt uitsluitend versienummers, dus
gemergde wijzigingen bereiken consumenten (en deze zelf-consumerende repo) pas na een bump. Werk dat
moet propageren, vraagt dus om een release (op Dave's expliciete verzoek, zoals altijd).

[PR #26](https://github.com/DaveKJohn/davekjohns-workshop/pull/26)

---

### #27 · cut-release leidt manifesten af uit marketplace.json · Chore · 2026-07-15

Victors robuustheidssuggestie uit PR #25 uitgewerkt: `Get-PluginManifests` in `cut-release.ps1`
scant niet langer repo-breed op `.claude-plugin/plugin.json`, maar leidt de manifesten af uit
`plugins[].source` in `marketplace.json` — de bron van waarheid over wat een plugin is. Een
toevallige geneste plugin.json (bv. toekomstig test- of voorbeeldmateriaal) kan zo nooit
stilzwijgend meegebumpt worden; een geregistreerde plugin zónder manifest breekt de release nu
met een duidelijke fout. Op advies van Sean 🛡️ (zijn eerste audit) is er ook een containment-check
bij: een `source` die via een absoluut of `..`-pad buiten de repo wijst, breekt de release vóór er
iets geschreven wordt.

[PR #27](https://github.com/DaveKJohn/davekjohns-workshop/pull/27)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.1.0] - 2026-07-15 — Minor

Zie [releases/development/1.1/1.1.0.md](releases/development/1.1/1.1.0.md) voor de volledige release-notes.

---

### [v1.0.0] - 2026-07-14 — Major

Zie [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) voor de volledige release-notes.
