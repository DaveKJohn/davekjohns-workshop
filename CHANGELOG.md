# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#contributing--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #133 · translate remaining Dutch test fixtures (#114 item 3) · Chore · 2026-07-22

Completes #114 item 3 (Phase D of the English switch). A survey showed three of the four sub-parts
were already done -- the `agent-shared/` block files are already English-named
(`language-behavior.md` etc.), `connector-sessioncheck.ps1`'s docblock is already English, and
`bootstrap.ps1`'s scaffold text is English apart from the intentional `VUL-IN` marker. The only
remaining internal Dutch was concentrated in `scripts/tests/release-lib.tests.ps1`: fixture sample
strings (the `$sample` CHANGELOG, entry titles/bodies, link text) plus the Dutch local variable
names. Those are now English, with every paired assertion translated in lockstep and the stale
header NOTE refreshed. Deliberate back-compat markers were left untouched: `Eigen aan deze repo`
(legacy slot heading), `[FOUT]`, the bilingual `-bestand aangemaakt`/`Aangevraagd door Dave` PR-template
recognizers, the `releases/README` header match in cut-release, and `VUL-IN` -- these recognize
not-yet-migrated consumer content or are Dave's explicit exceptions. All test suites stay green.

[PR #133](https://github.com/DaveKJohn/davekjohns-workshop/pull/133)

---

### #132 · cut-release uses shared Invoke-NativeCapture (#114 follow-up) · Chore · 2026-07-22

Follow-up to #114 item 1: `cut-release.ps1` now routes its five native git mutations (add, commit,
tag, push main, push tag) through the shared `Invoke-NativeCapture` helper instead of a hand-rolled
`ErrorActionPreference = 'Continue'` block with bare `git` calls. Same #107 protection, now from the
one tested source -- and the deliberate "EAP not restored, this is the last block" special case goes
away (each call restores EAP itself). Captured git chatter is echoed so a release run stays as
verbose as before. The sweep guard in `shared-scripts.tests.ps1` was re-pointed from the old inline
pattern to assert the helper is used.

[PR #132](https://github.com/DaveKJohn/davekjohns-workshop/pull/132)

---

### #131 · shared Invoke-NativeCapture helper (#114 item 1) · Chore · 2026-07-22

Centralized the native-command stderr-capture pattern (#114 item 1) into a new shared helper
`scripts/lib/native-capture-lib.ps1` (`Invoke-NativeCapture`), so the #96/#97/#107 lesson --
run under `ErrorActionPreference = 'Continue'`, capture output, then judge on `$LASTEXITCODE`
instead of on stderr -- lives in exactly one tested place. The helper takes `-FilePath`/`-Arguments`
(not a scriptblock, so the EAP override actually reaches the command) and returns `Output` +
`ExitCode`; `-DiscardStderr` keeps stderr out of machine-readable output. `open-pr.ps1` (git push +
`gh pr create`) and `fold-changelog-entry.ps1` (`gh pr list`) now call the helper instead of each
repeating the save/restore dance. Registered as a mirrored shared script and dot-sourced
`$PSScriptRoot`-relative, matching the `check-report-lib.ps1` precedent. Regression guards in
`shared-scripts.tests.ps1` were re-pointed from the old inline patterns to the centralized helper,
plus a new behavioral test of `Invoke-NativeCapture` (throws-nothing on native stderr under caller
EAP=Stop, real exit code, EAP restored, `-DiscardStderr`).

Plugins: specialists

[PR #131](https://github.com/DaveKJohn/davekjohns-workshop/pull/131)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.15/1.15.0.md](releases/development/1.15/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

Zie [releases/development/1.14/1.14.0.md](releases/development/1.14/1.14.0.md) voor de volledige release-notes.

---

### [v1.13.0] - 2026-07-21 — Minor

Zie [releases/development/1.13/1.13.0.md](releases/development/1.13/1.13.0.md) voor de volledige release-notes.

---

### [v1.12.1] - 2026-07-20 — Patch

Zie [releases/development/1.12/1.12.1.md](releases/development/1.12/1.12.1.md) voor de volledige release-notes.

---

### [v1.12.0] - 2026-07-20 — Minor

Zie [releases/development/1.12/1.12.0.md](releases/development/1.12/1.12.0.md) voor de volledige release-notes.

---

### [v1.11.0] - 2026-07-20 — Minor

Zie [releases/development/1.11/1.11.0.md](releases/development/1.11/1.11.0.md) voor de volledige release-notes.

---

### [v1.10.0] - 2026-07-19 — Minor

Zie [releases/development/1.10/1.10.0.md](releases/development/1.10/1.10.0.md) voor de volledige release-notes.

---

### [v1.9.2] - 2026-07-19 — Patch

Zie [releases/development/1.9/1.9.2.md](releases/development/1.9/1.9.2.md) voor de volledige release-notes.

---

### [v1.9.1] - 2026-07-19 — Patch

Zie [releases/development/1.9/1.9.1.md](releases/development/1.9/1.9.1.md) voor de volledige release-notes.

---

### [v1.9.0] - 2026-07-19 — Minor

Zie [releases/development/1.9/1.9.0.md](releases/development/1.9/1.9.0.md) voor de volledige release-notes.

---

### [v1.8.0] - 2026-07-18 — Minor

Zie [releases/development/1.8/1.8.0.md](releases/development/1.8/1.8.0.md) voor de volledige release-notes.

---

### [v1.7.0] - 2026-07-18 — Minor

Zie [releases/development/1.7/1.7.0.md](releases/development/1.7/1.7.0.md) voor de volledige release-notes.

---

### [v1.6.0] - 2026-07-18 — Minor

Zie [releases/development/1.6/1.6.0.md](releases/development/1.6/1.6.0.md) voor de volledige release-notes.

---

### [v1.5.2] - 2026-07-18 — Patch

Zie [releases/development/1.5/1.5.2.md](releases/development/1.5/1.5.2.md) voor de volledige release-notes.

---

### [v1.5.1] - 2026-07-18 — Patch

Zie [releases/development/1.5/1.5.1.md](releases/development/1.5/1.5.1.md) voor de volledige release-notes.

---

### [v1.5.0] - 2026-07-17 — Minor

Zie [releases/development/1.5/1.5.0.md](releases/development/1.5/1.5.0.md) voor de volledige release-notes.

---

### [v1.4.1] - 2026-07-16 — Patch

Zie [releases/development/1.4/1.4.1.md](releases/development/1.4/1.4.1.md) voor de volledige release-notes.

---

### [v1.4.0] - 2026-07-16 — Minor

Zie [releases/development/1.4/1.4.0.md](releases/development/1.4/1.4.0.md) voor de volledige release-notes.

---

### [v1.3.0] - 2026-07-16 — Minor

Zie [releases/development/1.3/1.3.0.md](releases/development/1.3/1.3.0.md) voor de volledige release-notes.

---

### [v1.2.0] - 2026-07-16 — Minor

Zie [releases/development/1.2/1.2.0.md](releases/development/1.2/1.2.0.md) voor de volledige release-notes.

---

### [v1.1.1] - 2026-07-15 — Patch

Zie [releases/development/1.1/1.1.1.md](releases/development/1.1/1.1.1.md) voor de volledige release-notes.

---

### [v1.1.0] - 2026-07-15 — Minor

Zie [releases/development/1.1/1.1.0.md](releases/development/1.1/1.1.0.md) voor de volledige release-notes.

---

### [v1.0.0] - 2026-07-14 — Major

Zie [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) voor de volledige release-notes.
