### Roster-sync detection (layer 1 of the roster-sync feature) · Feat · 2026-07-20

When a plugin release adds a new specialist (e.g. Ravi 06-24), a consumer that updates the plugin
got no signal that its roster (the specialists table in CLAUDE.md) and its repo lenses now lag
behind — the Ravi and Sean cases were both caught by chance. This is layer 1 of the fix: **detection**.
The SessionStart signaling (layer 2) and the semi-automatic recovery skill (layer 3) follow; full
user-facing docs land with layer 3 when the feature is complete.

- **`scripts/sync/check-roster-sync.ps1` (new, shared):** run from a consumer root, it resolves the
  enabled plugins' agents from the highest-version cache dir, then flags per agent: no roster row
  (`[ERROR]`), no repo-lens (`[ERROR]`), and roster/lens ids with no backing agent or persona
  (`[INFO]` orphan). Same `[OK]/[INFO]/[ERROR]` + exit-code convention and path guardrails as
  `check-connectors.ps1`. Mirrored to the plugin via the shared-scripts pipeline (byte-identical,
  drift-linted).
- **`repo-config.ps1`:** `Get-RosterPath` (default `CLAUDE.md`) tells the check where the roster
  lives; `Get-RosterIgnoredIds` lists agents that are enabled but deliberately have no roster
  row/lens (here: Paula 02-09, Vera 04-11, Gwen 04-12, Cody 04-13 — a documented choice), so the
  workshop's own run is clean. A fresh consumer leaves the ignore-list empty.
- **Tests:** `roster-sync.tests.ps1` (28 asserts, fixture-driven) covers the happy path, a new agent
  missing from the roster, a missing lens, orphans, disabled/uncached plugins, highest-version
  resolution, persona-backing, the `Get-RosterPath` override, the legacy lens path, and the
  ignore-list. `repo-config.tests.ps1` gained asserts for the two new getters.

Layer 1 is not yet wired into any gate — it is a standalone check a consumer can run; the hook
(layer 2) will surface it at session start.
