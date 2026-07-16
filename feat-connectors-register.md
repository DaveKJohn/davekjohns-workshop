### Connectors-register: sync-administratie van aangesloten repo's + sessie-check · Feat · 2026-07-16

Nieuw connectors-register op familie-niveau
(`claude-code-plugins/claude-specialists/connectors/<repo>.json`, één manifest per aangesloten
repo met per plugin de versie en extension-inventaris — de connector ís de repo): welke repo's
hebben de plugins geïnstalleerd en zijn ze in sync met deze repo als source of truth (CDP-model).
Het register woont bewust náást de plugin-mappen zodat het niet meereist met de plugin-cache van
consumenten (besluit Dave na Sean's cross-tenant-vondst); manifesten zijn metadata-only (nooit
lens-inhoud of absolute paden). Verder: één doctrine-README, het nieuwe
`scripts/sync/check-connectors.ps1` (two-way: enabled-check, extension-inventaris outbound én
inbound, versies tegen bron en machine-administratie, plus de bestaande drift-check per
consument, met `-OnlyConsumer`-scoping), en een **SessionStart-hook in de plugin** die de check
bij elke sessiestart draait — ook in de consumenten, zacht en read-only, met marker-verificatie
van de workshop-checkout en scoping tot de eigen repo (activering vergt een release-bump + update
per consument; samen met `specialists-init` de tweede benoemde uitzondering op de
geen-hooks/skills-regel, doctrine-teksten bijgewerkt). Alle bevindingen van Sean, Victor en Edith
zijn verwerkt: manifest-validatie (geen absolute paden/pad-traversal/ongeldige plugin-ids),
StrictMode-fixes, de signaal-filter die boilerplate niet meer als signaal telt, en herstelde
links. Dependency-vrije testsuite: 34 asserts; live-run alle drie connectors groen.
