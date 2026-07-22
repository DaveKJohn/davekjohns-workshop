### document the wait-for-CI step before merge (Chris lens + README) · Docs · 2026-07-22

The PR flow (Chris's lens 01-01-extension.md + README "Contributing" step 4) described the chain as
"open -> merge -> fold" without noting that branch protection on `main` blocks the merge until the
required CI check `lint-en-tests` is green -- a merge attempt before then returns BLOCKED. Someone
following the chain literally would try to merge immediately and get stuck. Added the explicit
"wait for CI green before merge" step in both places.
