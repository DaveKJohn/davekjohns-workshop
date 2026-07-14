### CLAUDE.md operating guide voor de marketplace-repo · Docs · 2026-07-14

De repo had zelf geen operating guide (life-hub's `CLAUDE.md` diende als naslag). Nu heeft
`claude-specialists` een eigen `CLAUDE.md`, opgebouwd volgens hetzelfde model als life-hub —
draagbare grondwet bovenaan, repo-lens onderaan — maar eerlijk afgestemd op wat déze repo is.

- `CLAUDE.md` — nieuw. Grondwet (safety-rules + algemene werkwijze) bovenaan; een repo-slot
  `## Eigen aan deze repo (claude-specialists)` onderaan. Expliciet gemarkeerd als buitenbeentje: deze
  repo *bestúurt* geen specialist-team (geen `.claude/`, geen Chris-routing) maar is de **bron** ervan,
  dus alleen de pure grondwet blijft over. Het repo-slot legt de `master`-branch-discipline, de
  lint-poort (`check-plugin-integrity.ps1`), de fold-uitzondering, de richting-van-de-waarheid voor
  gedeelde agent-defs, en het publiek-zijn (geen secrets/persoonlijke info) vast; de mechaniek-details
  verwijzen naar `README.md` i.p.v. die te dupliceren.
