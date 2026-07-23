### Refine the CI-retrigger lesson for a very-late original run · Docs · 2026-07-23

Extends Derek's close/reopen lesson (`05-05-extension.md`, PR #152) with a nuance surfaced during
PR #155's own merge: the original `lint-en-tests` run was not truly missing, only extremely
delayed, and appeared shortly after the reopen-triggered run had already gone green. Adds two
practical refinements — verify via `gh api repos/<owner>/<repo>/actions/runs?head_sha=<sha>` that no
run exists at all before closing/reopening (ruling out an unrelated check suite from another
integration, e.g. `netlify`), and if a retrigger is already done and the late original run then
shows up, expect two runs briefly with `mergeStateStatus` dropping back to `BLOCKED`; wait for both
to go green and merge normally, never with `--admin`. Also aligns Chris's lens (`01-01-extension.md`)
to the same terminology: `main` is guarded by a ruleset, not classic branch protection, which
explains the "base branch policy" wording — that lens previously still said "branch protection".