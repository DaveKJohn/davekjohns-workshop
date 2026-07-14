### Release rechtstreeks op master (geen branch/PR): cut-release.ps1 herzien · Chore · 2026-07-14

Op Dave's aanwijzing (zoals in life-hub) loopt een release **niet** via een branch + PR, maar
rechtstreeks op `master` — net als de fold-commit, als **tweede** toegestane directe-op-`master`-actie.
`cut-release.ps1` is daarop herzien: geen release-branch en geen twee-fasen-opzet meer, maar in één
beweging op een schone `master`: lockstep-versiebump, `## Pull Requests` → `## Releases`-verplaatsing,
commit `release: vX.Y.Z`, annotated tag `vX.Y.Z`, en push van master + tag (`-NoPush` voor inspectie
vooraf). Het `release`-prefix in `branch-info.ps1` is verwijderd (niet meer nodig). Docs bijgewerkt:
README, `CLAUDE.md` (grondwet + safety-invulling: nu twee master-uitzonderingen), Rendall-manual en
Sylvester-lens. De pure logica in `release-lib.ps1` en de tests bleven ongewijzigd.