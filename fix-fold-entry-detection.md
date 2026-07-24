### fold-changelog: only fold real changelog-entry files, not root meta docs · Fix · 2026-07-24

**Bug:** in fold-all mode (`fold-changelog-entry.ps1` without `-Branch`) any root `*.md` that was not
in a tiny denylist (`CHANGELOG.md`/`CLAUDE.md`/`README.md`) was treated as a changelog entry — so
the repo-meta files `CONTRIBUTING.md` and `SECURITY.md` (added later) got folded into `CHANGELOG.md`
and then removed. Caught and reverted during the Marlowe fold; nothing shipped.

**Fix:** add a positive, structural gate. A changelog entry always opens with the compact
`### <title> · <type> · <date>` H3 heading (the fold code already relies on that `###` line);
repo-root meta docs open with an H1. Fold-all now folds a file only if its first non-empty line is
that H3 heading, so meta docs are never folded. Deliberately independent of the branch-prefix table,
so consumer-extended prefixes (Shopify's `style/`, `liquid/`, …) still fold. `-Branch` mode is
unchanged (it targets exactly the named entry).

- `scripts/release/fold-changelog-entry.ps1`: new `Test-IsChangelogEntryFile` helper + the fold-all
  filter; header doc updated. Plugin mirror re-synced byte-identical via `build-shared-scripts.ps1`.
- New regression suite `scripts/tests/fold-changelog.tests.ps1` (17 asserts): meta docs survive, a
  genuine entry folds, an extended-prefix entry still folds, a hyphen-named H1 doc is not folded,
  and `-Branch` mode is unaffected.
