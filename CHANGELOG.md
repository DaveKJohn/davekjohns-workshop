# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #161 · Add .gitattributes (line-ending normalization) and SECURITY.md · Chore · 2026-07-23

Added a root `.gitattributes` (`* text=auto eol=lf`, plus explicit `text eol=lf` entries for
`.ps1`/`.md`/`.json`/`.jsonc`/`.yml`/`.yaml`/`.txt` and `binary` for common image/font types) to fix
the recurring "LF will be replaced by CRLF" warning on every commit in this Windows-authored repo.
`.ps1` files run fine with LF line endings on both PowerShell 5.1 and 7+, so `eol=lf` is the safe,
conventional choice here, not just for the Markdown/JSON/YAML content. Scoped deliberately to just
the new file — no repo-wide `git add --renormalize .` in this change, deliberately left for a
later, separate pass. Lint gate (`check-plugin-integrity.ps1`) verified green after the addition.

Added a root `SECURITY.md`: scope (unsafe agent-def/script/hook content, accidental secret
exposure) vs. out of scope (no hosted service/user data), the GitHub Security Advisory reporting
route, and best-effort/single-maintainer response expectations — no invented SLAs.

[PR #161](https://github.com/DaveKJohn/davekjohns-workshop/pull/161)

---

### #160 · Extend dead-link scan to cover CONTRIBUTING.md and connectors/README.md · Chore · 2026-07-23

The dead-link/anchor scan in `scripts/lint/check-plugin-integrity.ps1` (check 4) had an explicit
list of scanned files that had not been updated to include two files added by the docs
redistribution in PR #159: the root `CONTRIBUTING.md` and
`claude-code-plugins/claude-specialists/connectors/README.md`. Link/anchor changes in those two
files therefore silently escaped the automatic gate — spotted by Edith during copy edit.

`CONTRIBUTING.md` now joins the existing root loop (README.md/CHANGELOG.md/CLAUDE.md); the
connectors README is added as a single, targeted addition (it is not covered by any existing glob,
since the CHANGELOG.md glob under `claude-code-plugins/claude-specialists/**` explicitly excludes
`\connectors\`, and the family README/QUICKSTART loop only targets the family root, not the
`connectors/` subfolder). The scan docstring and the check-4 comment block were updated to match.

Verified: the lint gate still passes green (0 errors) after the change, and a temporary fake dead
link + broken anchor introduced in both files was correctly reported by the gate, then reverted.

[PR #160](https://github.com/DaveKJohn/davekjohns-workshop/pull/160)

---

### #159 · Redistribute root README content across family/connectors/releases READMEs + new CONTRIBUTING.md · Docs · 2026-07-23

The root `README.md` had grown to carry family-specific mechanics that broke its own "family
mechanics belong in the family README" rule. Moved out of root: "Manuals — the split model"
(merged into the family README as the single canonical explanation of manual/agent-def/persona-template,
replacing three near-duplicate versions across root, the family README, and the Specialists handbook),
"Shared agent-def blocks", "Where this runs: Chat, Cowork, and Claude Code", "How we use skills —
and what we deliberately don't", "Adoption: the bootstrap path" (next to the existing Quickstart
pointer), and "Adding a new plugin group" — all five now live in the family
README (`claude-code-plugins/claude-specialists/README.md`); "Maintenance: drift lint" moved into
`connectors/README.md`, consolidated with its existing drift/persona-drift sections instead of
duplicating them; "Cutting a release" and the scripty part of "Versioning" moved into
`releases/README.md` with proper section anchors; "Contributing — changelog & PR workflow" moved
into a new root `CONTRIBUTING.md`. The root README itself is slimmed to a short TOC (intro, plugin
families, what lives here, a shortened repo layout, a shortened consumption section, a short
versioning fact + link, a short contributing pointer, and a closing "Want to know more?" block) with
every internal/external cross-reference into the moved sections repointed to its new home
(`CLAUDE.md`, `CHANGELOG.md`, `QUICKSTART.md`, and the family README's own self-references included).

[PR #159](https://github.com/DaveKJohn/davekjohns-workshop/pull/159)

---

### #158 · Record how this repo uses Skills (and what it deliberately does not) · Docs · 2026-07-23

Adds a compact `### How we use Skills — and what we deliberately don't` subsection to `README.md`,
right after "Where this runs: Chat, Cowork, and Claude Code" and before "## Consumption", recording
as durable knowledge a reflection that otherwise only lived in a conversation. Notes: today every
skill (`fold-changelog`, `open-pr`, `new-branch`, `specialists-init`, `sync-roster`, `start-task`) is
a thin wrapper around a script — procedural mechanism, not craft, which lives in the persona/manual
context instead; Anthropic's Agent Skills model supports a third, unused level (bundled reference
material via progressive disclosure) that a future knowledge-skill could use; the discipline stays
"only where it's worth the maintenance cost," pointing at `cut-release` staying deliberately
skill-less (`scripts/sync/check-script-contract.ps1`) as the living example; and Cowork's non-code
positioning is why this code-maintenance repo rightly stays Claude-Code-centric.

[PR #158](https://github.com/DaveKJohn/davekjohns-workshop/pull/158)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
