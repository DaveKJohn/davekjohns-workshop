### Roster-sync recovery skill (layer 3, feature complete) · Feat · 2026-07-20

The final layer of the roster-sync feature: after the SessionStart hook (layer 2, #111) flags a
specialist missing from a consumer's roster, the `sync-roster` skill stages the catch-up — without
ever writing to `CLAUDE.md`, committing, or touching main. With this, the feature is complete:
detection (#110) → signaling (#111) → recovery.

- **`skills/sync-roster/sync-roster.ps1` (new):** delegates drift detection to
  `check-roster-sync.ps1` (it does not re-decide drift), then for each flagged agent creates the
  missing lens scaffold (`## Specific to this repo (VUL-IN)`, byte-for-byte the bootstrap format,
  additive — never overwriting) and prints a proposed roster row built from the agent's frontmatter
  (name + description, best-effort matched to the roster's table-or-list style). It prints a summary
  with an explicit "main is sacred — review and branch this yourself" reminder. The roster file is
  never modified.
- **`skills/sync-roster/SKILL.md` (new):** when to run it (after the hook flags drift), what it
  stages, and the human follow-up — mirroring the `open-pr`/`specialists-init` skill tone.
- **`roster-sessioncheck.ps1`:** the drift hint now points at the `sync-roster` skill (the forward
  reference deliberately held back in layer 2 until the skill existed).
- **`QUICKSTART.md`:** a "new specialist" note in *Staying up to date* points consumers at the hook
  + skill.
- **Tests:** `sync-roster.tests.ps1` (22 asserts) covers scaffold creation, the never-overwrite
  guard, a proposed row printed for a missing-roster agent, and that the roster file's bytes are
  never changed.

Version gate as usual: consumers get the skill after a release bump + `claude plugin update`.
