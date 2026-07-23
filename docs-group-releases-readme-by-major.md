### Group the releases overview by major version · Docs · 2026-07-23

Groups the `releases/README.md` overview table by major version (`### 2.x`, `### 1.x`, newest
first), each group its own table, now that `v2.0.0` is a natural dividing point — the flat 27-row
list was getting long. The `2.x` table sits at the top with the same English header
(`| Version | Date | Type | Title |`), so `cut-release.ps1`'s row insertion (which targets the
first matching header) keeps landing new minor/patch rows in the current-major table without a
behavior change; verified by simulating a `2.1.0` insertion. `cut-release.ps1` gets a clarifying
comment documenting that layout assumption and that a brand-new major starts its top section
manually first (a deliberate milestone moment). Doc + comment only; no functional change.