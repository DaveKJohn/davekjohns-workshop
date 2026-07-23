### Park move (intent + push) and portable post-merge branch cleanup · Feat · 2026-07-23

Two inbound improvements to the shared branch lifecycle, landing in the source (closes #162 and #163).

**#162 — parking a branch (intent + push, no PR).** `new-changelog-entry.ps1` gains an optional
`-Intent`; when given it becomes the recorded entry body, and when omitted the body now falls back
to a directional block (`**To do / where I left off:**` + a prompting TODO) instead of a bare
one-line TODO — so a forgotten intent still leaves a "what is next / where was I" prompt. `new-branch.ps1`
gains `-Intent` (passed to the child via `CLAUDE_NEWBRANCH_INTENT`, the same injection-safe env-var
handoff as `-Title`) and an opt-in `-Park` switch that commits the entry and pushes the branch to
`origin` with `git push -u` — **no PR** (push is not a PR; the PR rule stays intact and separate).
The push reuses the shared `Invoke-NativeCapture` helper (the `#107` stderr guard). The default
path is unchanged: without `-Park` nothing is committed or pushed.

**#163 — post-merge branch cleanup as a fixed closing step.** Documented in the portable layer: the
`fold-changelog` skill (the last chain step) now names the local cleanup — `git fetch --prune` +
`git branch -d <branch>`, with the remote handled by the repo's auto-delete-on-merge setting — as a
fixed closing step (the canonical exact commands live there); Derek's portable persona body and repo
lens cross-reference that rule, and the `specialists-init` setup checklist tells a new consumer to
enable `deleteBranchOnMerge`.

Regression tests for `-Intent`, the directional fallback, and `-Park` (branch pushed to a bare
`origin`, entry committed, upstream set, no PR) added to `scripts/tests/new-branch.tests.ps1`; the
plugin mirrors were regenerated from the canonical source.
