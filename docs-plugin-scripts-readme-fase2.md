### Plugin-scripts-README: Fase 2-realiteit corrigeren (branch-info CI-pin + bin/-gaten) · Docs · 2026-07-19

Corrigeert twee onjuistheden in `claude-code-plugins/claude-specialists/specialists/scripts/README.md` die in #82 zelf ontstonden:

- **`branch-info.ps1` kan niet mee naar de plugin.** De README suggereerde dat dat kon zodra `open-pr.ps1` meeverhuist, maar dezelfde PR (#82) liet `release-lib.ps1` `branch-info` dot-sourcen; `release-lib` draait in CI vanaf een kale checkout, waardoor `branch-info` nu ook door CI aan de root is vastgeklonken.
- **De `bin/`-aanroepkeuze is niet settled.** `bin/` staat op de PATH van de Bash-tool (niet de PowerShell-tool), een mens kan het niet direct aanroepen, en Windows `.ps1`-als-kaal-commando + `${CLAUDE_PROJECT_DIR}`-beschikbaarheid zijn ongedocumenteerd. Een skill is het enige bevestigde alternatief. De README verwijst nu naar het Fase 2-addendum op [#81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81).