### cut-release: stop flagging legitimate root docs (CONTRIBUTING/SECURITY) as unfolded entries · Fix · 2026-07-23

`cut-release.ps1` refuses to cut a release while an unfolded changelog entry file sits in the repo
root, recognising an entry by exclusion: every root `*.md` not in the `$reservedRootMd` allowlist is
treated as one. The allowlist listed only `CHANGELOG/CLAUDE/README/LICENSE.md`, so the permanent
root docs `CONTRIBUTING.md` and `SECURITY.md` (added in #159/#161) were mistaken for unfolded
entries and falsely blocked a release. Added both to the allowlist, with a comment noting that any
new permanent root doc must be listed there.

Added `scripts/tests/cut-release-guardrail.tests.ps1`: a drift guard asserting that every tracked,
non-branch-prefixed root `*.md` is covered by the allowlist, so this exact drift (a new root doc
silently blocking releases) is caught automatically going forward.
