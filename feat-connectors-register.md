### Connectors-register: per plugin een sync-administratie van aangesloten repo's · Feat · 2026-07-16

Nieuw connectors-register op familie-niveau
(`claude-code-plugins/claude-specialists/connectors/<plugin>/<repo>.json`): welke repo's hebben
elke plugin geïnstalleerd en zijn ze in sync met deze repo als source of truth (CDP-model). Het
register woont bewust náást de plugin-mappen zodat het niet meereist met de plugin-cache van
consumenten (besluit Dave na Sean's cross-tenant-vondst). Vijf manifesten (metadata-only: repo,
plugin, versies, extension-inventaris — nooit lens-inhoud of absolute paden), één
doctrine-README, het nieuwe
`scripts/sync/check-connectors.ps1` (two-way: enabled-check, extension-inventaris outbound én
inbound, versies tegen bron en machine-administratie, plus de bestaande drift-check per
consument), een **SessionStart-hook in de plugin** die de check bij elke sessiestart draait — ook
in de consumenten, zacht en read-only (activering vergt een release-bump + update per consument)
— en een dependency-vrije testsuite (26 asserts). Na de reviews van Sean, Edith en
Victor gehard en aangescherpt: manifestvelden worden gevalideerd vóór gebruik (geen absolute
paden, geen pad-traversal buiten de scope-root, plugin-veld alleen als bestaande slug), de
StrictMode-crash bij een stale machine-record is gefixt en afgedekt, en de dode links in het
doctrine-README zijn hersteld. Live-run: alle vijf connectors groen.