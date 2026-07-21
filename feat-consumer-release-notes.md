### Ship a per-plugin RELEASE.md card so consumers see which release they are on · Feat · 2026-07-21

Every plugin now carries a `RELEASE.md` card (version, one-line summary, and the entries for that
version) right next to its `CHANGELOG.md`. Chosen approach: **Model A, plugin-authored** — the card
lives inside the plugin folder and travels with the plugin cache via `claude plugin update`, so a
consumer can see exactly which release they're on without cross-referencing the workshop's own
`releases/` history. `cut-release.ps1` (re)generates the card for every plugin, in lockstep, on
every release; the lint gate's new check 9 guards that the card is present and its `vX.Y.Z` matches
that plugin's `plugin.json`. Deliberately **no SessionStart hook** announces this — the card is
discovered by opening the file in the plugin cache. Seeded on v1.12.1.