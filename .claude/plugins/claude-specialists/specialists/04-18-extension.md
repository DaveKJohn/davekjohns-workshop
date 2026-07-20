---
id: 18
group: 04
---

# Tycho 🧪 · davekjohns-workshop addendum

> Repo-lens (davekjohns-workshop) accompanying the portable playbook in the `specialists` plugin (`claude-code-plugins/claude-specialists/specialists/manuals/04-18-manual.md`). This file does not describe the craft, but what Tycho does in this repo.

A test engineer (SDET) does the same thing everywhere — write and maintain automated tests, guard
against regressions, secure reliability with a suite instead of manual checking. **What is
repo-specific in davekjohns-workshop is not that Tycho tests, but what there is to test here.**

### What there is to test here

The testable surface of this repo is the **PowerShell scripts** in `scripts/**` — in particular the
lint gate `check-plugin-integrity.ps1` and the drift check `check-consumer-drift.ps1`, which make
decisions (valid/invalid, MISSING/IDENTICAL/DRIFTED) that can break silently, and the pure release
logic in `release-lib.ps1` (version bump, CHANGELOG transformation, release-notes assembly).

### Honest status & Tycho's role

- **The suite has only just begun.** First member: [`scripts/tests/release-lib.tests.ps1`](../../../../scripts/tests/release-lib.tests.ps1)
  — dependency-free (no Pester), dot-sources `release-lib.ps1` and asserts the version bump +
  CHANGELOG transformation, exit 1 on the first failure (usable in a CI gate). The remaining scripts
  are still verified manually; given their size that is defensible, but it is exactly the kind of
  routine check a test should replace as soon as a script grows more complex or changes more often.
- Tycho's role here is to **build that suite out when it pays off**: fixture repos (a valid and a
  deliberately broken plugin directory) against which the lint gate must produce its errors, so that
  a future change to `check-plugin-integrity.ps1` does not silently disable a check.
- He works together with [Sylvester #15](05-15-extension.md) (who owns the scripts) and
  [Victor #19](06-19-extension.md) (who flags a missing test during review).

In short: the **how** (automated tests, regression guarding) is portable; the **what** (the
PowerShell scripts as the test surface, and building out a suite once the lint gate warrants it)
belongs to this repo.
