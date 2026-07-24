### Add Marlowe #29 -- adversarial conclusion reviewer (investigative journalist / watchdog) · Feat · 2026-07-24

New specialist in the shared `specialists` plugin (flows back to every consumer via a release):
**Marlowe 🕵️ #29, the Investigative Journalist / consumer watchdog** — the independent devil's
advocate on the *substance and conclusions* of the team's work.

Where Victor #19 (correctness), Edith #17 (language), and Sebastian #23 (security) review the
**craft**, Marlowe reviews the **conclusion itself**: before anyone acts on a recommendation, he
tries to tear it down — the fine print / the catch, the load-bearing assumption, and real-world
contradicting evidence (customer experiences, complaints, regulator warnings) versus the sales
pitch. His distinct value versus the researcher (Rebecca #07): Rebecca builds the case, Marlowe is
adversarial by mandate and red-teams a case that already exists. Delivers a critical counter-report
with an explicit verdict (HOLDS / WOBBLES / FALLS); read-only in spirit — reviews, does not rewrite,
fixes nothing, commits nothing, opens no PRs.

- **Stable id 29, group 06** (reviewer group). Built as a subagent (agent-def + manual), matching
  the other pre-PR reviewers; no persona file (personas exist only for the main-loop specialists).
  Tools: `Read, Grep, Glob, WebSearch, WebFetch, Skill` (the research/reviewer profile) -- no
  write/edit, no git.
- New files: `agents/06-29-agent.md`, `manuals/06-29-manual.md` (plugin source),
  `.claude/plugins/claude-specialists/specialists/06-29-extension.md` (repo lens).
- Roster updated everywhere: `CLAUDE.md` (roster table), Chris's lens `01-01-extension.md` (routing
  table + the pre-PR quality-check chain), the handbook README (name list, group-06 tree, id table),
  and the family README manual inventory. Registered `06-29` in the connector manifest.
- Housekeeping alongside: added the pre-existing missing `06-25` (Nolan) to the connector manifest
  and to the family README manual inventory, so both are accurate again.
