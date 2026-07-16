### Connectors-register: per plugin een sync-administratie van aangesloten repo's · Feat · 2026-07-16

Elke plugin draagt nu een `connectors/`-map: het register van welke repo's de plugin
geïnstalleerd hebben en of ze in sync zijn met deze repo als source of truth (CDP-model). Vijf
manifesten (metadata-only: repo, plugin, versies, extension-inventaris — nooit lens-inhoud of
absolute paden), een doctrine-README in de kern-plugin, het nieuwe
`scripts/sync/check-connectors.ps1` (two-way: enabled-check, extension-inventaris outbound én
inbound, versies tegen bron en machine-administratie, plus de bestaande drift-check per
consument) en een dependency-vrije testsuite (12 asserts). Live-run: alle vijf connectors groen.