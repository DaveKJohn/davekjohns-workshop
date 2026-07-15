### CLI-scope-les geborgd: plugin update filtert niet op werkdirectory · Docs · 2026-07-15

Geleerde les uit de v1.1.1-plugin-update geborgd in `research/plugin-sharing/vervolgstappen.md`:
`claude plugin update -s project` filtert níét op de werkdirectory (vanuit deze repo gedraaid werkte
het commando het record van smartwatchbanden bij) en `claude plugin list` toont zonder `--json` niet bij welk
project een record hoort. De vastgelegde werkwijze: controleren met `claude plugin list --json`
(`projectPath`), bijwerken via `claude plugin install -s project` vanuit de doel-repo, en herstarten
om de nieuwe versie te laden. Daarnaast is vervolgstap 3 geactualiseerd (de map-hernoem is gebeurd;
er resteert een verweesd plugin-record op het oude pad) en de plugin-versie-vermelding bijgewerkt
naar v1.1.1.