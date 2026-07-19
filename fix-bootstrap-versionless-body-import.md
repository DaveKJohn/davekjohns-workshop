### Bootstrap schrijft een durabel, versie-loos body-importpad · Fix · 2026-07-19

Dicht een durability-gat dat een acceptatietest van consument djcylow-react aan het licht bracht
(Gat C): bij een user-scope install schreef de `specialists-init`-bootstrap een **versie-gepind**
body-importpad in `CLAUDE.md`
(`@~/.claude/plugins/cache/<marketplace>/<plugin>/<versie>/personas/01-01-persona.md`). De cache is
ephemeer — na een plugin-update wordt de oude versie-map opgeruimd (~7 dagen), waarna de `@`-import
naar een niet-bestaand pad wijst en de **body van de orchestrator (Chris) stil niet meer laadt**.

- **`bootstrap.ps1`**: nieuwe `Get-DurablePersonaDir` vertaalt een cache-pad
  (`…/plugins/cache/<marketplace>/…`) naar de versie-loze marketplaces-clone
  (`…/plugins/marketplaces/<marketplace>/…`) — het durabele anker dat een update overleeft (git-pull,
  pad verandert niet). De marketplace-naam wordt uit het cache-pad gerecupereerd; de clone wordt
  geverifieerd (bestaat, bevat de plugin-personas met `01-01-persona.md`) vóór hij wordt gebruikt.
  Bij elke twijfel terugval op het oorspronkelijke pad — geen regressie voor de source/marketplaces-
  layout (de bron die zichzelf consumeert verandert niet). De feitelijke *read* blijft de cache;
  alleen het geschreven pad wordt durabel.
- **Onderbouwing (research)**: `@`-imports in `CLAUDE.md` kennen géén variabele-expansie
  (`${CLAUDE_PLUGIN_ROOT}` e.d. werken daar niet), dus een vast versie-loos pad is de enige route.
- **`bootstrap-drift.tests.ps1`**: case (2c) toegevoegd die de user-scope layout nabootst
  (`plugins/cache/<mp>/…` naast een `plugins/marketplaces/<mp>/`-clone) en assert dat de geschreven
  `@`-import naar de clone wijst, niet naar de versie-gepinde cache.