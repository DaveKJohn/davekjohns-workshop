# Release v2.0.2

**Date:** 2026-07-23  
**Type:** Patch

Skill invocation hardening, path hygiene, and workflow-lesson docs

You are on this release.

## Maintenance

### #154 · Flatten release notes into per-major folders · Chore · 2026-07-23

Flattens the release-notes layout from per-minor folders
(`releases/development/<X.Y>/<X.Y.Z>.md`) to one folder per major
(`releases/development/<X>.x/<X.Y.Z>.md`) — so all 1.x notes now live in `1.x/` and all 2.x notes
in `2.x/`, matching the per-major grouping already applied to the overview table (#152). The 27
existing 1.x notes and the two 2.x notes were moved via `git mv` (renames preserved); the empty
minor folders are gone.

Because the depth is unchanged (a single `<X>.x` folder replaces the single `<X.Y>` folder), the
root-relative links inside the notes (`../../../`) keep resolving — no note body was touched.
Updated: `cut-release.ps1` + `release-lib.ps1` now derive `<major>.x` (was `<major>.<minor>`); the
29 note-path links in `releases/README.md` + the `## Releases` block in `CHANGELOG.md`, the four
per-plugin `RELEASE.md` cards, the descriptive `<X.Y>` references in `README.md`/`05-06-extension.md`,
and the `release-lib` test's expected paths. Git tags (`vX.Y.Z`) are unaffected — they point to
commits, not paths. Archived note bodies keep their original (historical, sometimes Dutch) path
mentions on purpose. Lint gate green (dead-link scan clean); all test suites pass.

[PR #154](https://github.com/DaveKJohn/davekjohns-workshop/pull/154)

---

Full workshop notes: [releases/development/2.x/2.0.2.md](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/releases/development/2.x/2.0.2.md)
Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)
