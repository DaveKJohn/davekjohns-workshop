### cut-release leidt manifesten af uit marketplace.json · Chore · 2026-07-15

Victors robuustheidssuggestie uit PR #25 uitgewerkt: `Get-PluginManifests` in `cut-release.ps1`
scant niet langer repo-breed op `.claude-plugin/plugin.json`, maar leidt de manifesten af uit
`plugins[].source` in `marketplace.json` — de bron van waarheid over wat een plugin is. Een
toevallige geneste plugin.json (bv. toekomstig test- of voorbeeldmateriaal) kan zo nooit
stilzwijgend meegebumpt worden; een geregistreerde plugin zónder manifest breekt de release nu
met een duidelijke fout. Op advies van Sean 🛡️ (zijn eerste audit) is er ook een containment-check
bij: een `source` die via een absoluut of `..`-pad buiten de repo wijst, breekt de release vóór er
iets geschreven wordt.