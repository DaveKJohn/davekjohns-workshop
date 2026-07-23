# Changelog — specialists-ecomm

Consumer-facing history of this plugin: per release, the changes that touched this plugin.
Automatically appended by `cut-release.ps1` of the marketplace repo (davekjohns-workshop); the full
workshop history lives there in `CHANGELOG.md` and `releases/`.

## v2.0.2 — 2026-07-23

### Maintenance

#### #154 · Flatten release notes into per-major folders · Chore · 2026-07-23

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

## v1.17.0 — 2026-07-22

### Features

#### #143 · New specialists-ecomm plugin with three e-commerce specialists (SEO, CRO, SEA) · Feat · 2026-07-22

New fourth domain group — the plugin `specialists-ecomm`, for commercial webshop repos of any
platform (not Shopify-only) — with its first three specialists, all group 06 (the
measure-and-optimize family):

- **Sergio 📈 #26 — SEO Specialist.** Technical/on-site SEO: anchor links and internal linking,
  canonical tags, structured data (schema.org/JSON-LD), XML sitemaps, and pagespeed. Auditor and
  builder: measure first, fix at the source, validate, white-hat only.
- **Craig 🎯 #27 — CRO Specialist.** Conversion Rate Optimization: funnel/drop-off analysis, A/B
  experiments, checkout and landing-page optimization. Test, don't guess — keep only what a measured
  experiment proves.
- **Sean 💸 #28 — Performance / SEA Specialist.** The paid side of acquisition and its in-repo
  footprint: conversion tracking, product feeds, UTM conventions, ad-to-landing-page alignment.
  Honest about the boundary that live campaigns live in the ad platforms, and coordinates with
  Sergio so paid doesn't cannibalize organic.

All three carry the standard shared blocks (inbound-behaviour, laziness-automation,
language-behavior), defer visual/front-end changes to the design owner, and defer any preview/live
push to the platform's store owner.

**Rename to free the name for the SEA pun:** the existing Security Engineer **Sean 🛡️ #23** is
renamed to **Sebastian** (keeps 🛡️, #23, and its call name changes `@specialists:sean` →
`@specialists:sebastian`), so the new SEA specialist can be "Sean". Updated across the living
team-definition surfaces — the #23 agent def, manual, and repo lens; the roster in `CLAUDE.md`; the
family handbook; Chris's routing/chains lens; and the cross-references in the Ravi/Victor/Edith
lenses; plus the group-1 listing in `README.md`. History (CHANGELOG/releases, the dated security
baseline) and past-advice attribution comments in scripts/hooks/tests/CI are deliberately left as
records.

- **New plugin:** `claude-code-plugins/claude-specialists/specialists-ecomm/` with `plugin.json`
  (version 1.16.0, lockstep), `CHANGELOG.md`, and `RELEASE.md` card; registered as the fourth entry
  in `.claude-plugin/marketplace.json`.
- **Specialists:** agent defs `agents/06-26|27|28-agent.md` and portable manuals
  `manuals/06-26|27|28-manual.md`.
- Group deliberately set up to grow further (lifecycle/email, analytics) without restructuring.

**Quality-round follow-ups (Victor/Edith/Sebastian/Ravi/Nolan on the diff):**
- Registered the new plugin in the docs that describe the family — root `README.md`, the family
  `README.md`, and `QUICKSTART.md` now say "four plugins" and list `specialists-ecomm`; reframed
  "a repo needs at most one domain group" as **complementary** (a Shopify repo can enable
  `specialists-shopify` + `specialists-ecomm`).
- Fixed a real functional gap: `check-consumer-drift.ps1` hardcoded three plugins, so a consumer's
  drift check would never cover ids 26/27/28 — added `specialists-ecomm`.
- Language norm: translated the three pre-existing Dutch manifests (`marketplace.json` + the
  `specialists`/`lifehub`/`shopify` `plugin.json`) to English, closing the mixed-language state
  instead of extending it; generalized stale "three plugins" wording in scripts and lenses.
- Ravi: promoted three verbatim-shared boundaries across the ecomm agent-defs to `agent-shared/`
  blocks (`design-owner-boundary`, `changelog-entry-boundary`, `storefront-preview-boundary`),
  scoped to Sergio/Craig/Sean.

Verified: `build-agent-defs.ps1 -Check` (shared blocks in sync), `check-plugin-integrity.ps1`
(0 errors), and all test suites green.

[PR #143](https://github.com/DaveKJohn/davekjohns-workshop/pull/143)
