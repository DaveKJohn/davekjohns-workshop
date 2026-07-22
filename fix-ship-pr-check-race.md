### ship-pr.ps1: wait for the CI check to register before watching/merging · Fix · 2026-07-22

`ship-pr.ps1` (added in #136) called `gh pr checks <pr> --watch` once. But the CI checks can lag a
few seconds behind the push, and `gh pr checks` prints "no checks reported" and exits 0 while none
are registered yet -- indistinguishable by exit code from "all passed". So a fast run could sail
past the watch and hit `gh pr merge`, which branch protection then blocks (BLOCKED); the script
stopped safely but never actually shipped. Added a registration-wait loop before the watch: poll
`gh pr checks` (inspecting the TEXT for "no checks reported", not the exit code) until at least one
check exists, up to a 180s cap, then --watch as before. This is the same race the manual flow
handled with a re-check. Test gap unchanged (the script drives live git/gh; not covered by a suite).
