### ship-pr.ps1: open PR -> wait for CI -> merge -> fold in one command · Feat · 2026-07-22

Adds `scripts/release/ship-pr.ps1`, which orchestrates the whole "on Dave's word" PR chain that was
being run by hand every time: open-pr.ps1 (lint + test gate, push, open) -> look up the PR number ->
wait for the required CI check `lint-en-tests` (gh pr checks --watch) -> merge (gh pr merge --merge,
no --admin so the CI gate is never bypassed) -> checkout main, fold the entry, commit + push the
fold. Stops on the first failure and never forces a merge past red CI. `-NoMerge` opens the PR only;
`-SkipLint`/`-SkipTests` pass through to open-pr. Native git/gh calls run through the shared
Invoke-NativeCapture helper (#107 stderr guard). Deliberately workshop-local (like cut-release.ps1),
not mirrored to the plugin: merge policy and the CI check name are repo-specific. Run only on Dave's
explicit request, exactly like open-pr.ps1. Test gap noted in the script header: like open-pr it
drives live git/gh and is not covered by an automated suite (its sub-steps are tested on their own).
