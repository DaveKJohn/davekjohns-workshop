### cut-release uses shared Invoke-NativeCapture (#114 follow-up) · Chore · 2026-07-22

Follow-up to #114 item 1: `cut-release.ps1` now routes its five native git mutations (add, commit,
tag, push main, push tag) through the shared `Invoke-NativeCapture` helper instead of a hand-rolled
`ErrorActionPreference = 'Continue'` block with bare `git` calls. Same #107 protection, now from the
one tested source -- and the deliberate "EAP not restored, this is the last block" special case goes
away (each call restores EAP itself). Captured git chatter is echoed so a release run stays as
verbose as before. The sweep guard in `shared-scripts.tests.ps1` was re-pointed from the old inline
pattern to assert the helper is used.