### Roster-sync SessionStart hook (layer 2 of the feature) · Feat · 2026-07-20

Layer 2 of the roster-sync feature: the detection from layer 1 (#110) now surfaces itself at
session start, so a specialist missing from a consumer's roster is visible right after a plugin
update instead of only when someone happens to run the check.

- **`hooks/roster-sessioncheck.ps1` (new):** a SessionStart hook that runs the mirrored
  `check-roster-sync.ps1` against the current repo and, like `connector-sessioncheck.ps1`, is
  deliberately soft — it surfaces only blocking `[ERROR]` signals (a missing specialist) as a
  compact summary, keeps `[INFO]` (orphans, ignore-list skips, uncached plugins) silent, and always
  exits 0 (a session start never strands here). Read-only.
- **`hooks/hooks.json`:** a second `SessionStart` entry runs the new hook alongside the connector
  check.
- **`connectors/README.md`:** the named-exception note now covers this second hook.
- **Tests:** `roster-sync.tests.ps1` gains hook cases (missing check script → skipped; an `[ERROR]`
  stub → drift summary + exit 0, never blocking; an `[INFO]`/`[OK]`-only stub → silent in-sync
  message).

Version gate as usual: consumers receive the hook only after a release bump + `claude plugin
update` + session restart. Layer 3 (the semi-automatic `sync-roster` recovery skill) and the full
feature docs follow.
