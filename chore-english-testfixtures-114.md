### translate remaining Dutch test fixtures (#114 item 3) · Chore · 2026-07-22

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