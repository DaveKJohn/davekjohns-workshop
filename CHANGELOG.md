# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`README.md`](README.md#contributing--changelog--pr-workflow).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #143 · New specialists-ecomm plugin with three e-commerce specialists (SEO, CRO, SEA) · Feat · 2026-07-22

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

Plugins: agent-shared, specialists, specialists-ecomm, specialists-lifehub, specialists-shopify

[PR #143](https://github.com/DaveKJohn/davekjohns-workshop/pull/143)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.16/1.16.0.md](releases/development/1.16/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.15/1.15.1.md](releases/development/1.15/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.15/1.15.0.md](releases/development/1.15/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.14/1.14.0.md](releases/development/1.14/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.13/1.13.0.md](releases/development/1.13/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.12/1.12.1.md](releases/development/1.12/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.12/1.12.0.md](releases/development/1.12/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.11/1.11.0.md](releases/development/1.11/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.10/1.10.0.md](releases/development/1.10/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.9/1.9.2.md](releases/development/1.9/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.9/1.9.1.md](releases/development/1.9/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.9/1.9.0.md](releases/development/1.9/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.8/1.8.0.md](releases/development/1.8/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.7/1.7.0.md](releases/development/1.7/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.6/1.6.0.md](releases/development/1.6/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.5/1.5.2.md](releases/development/1.5/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.5/1.5.1.md](releases/development/1.5/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.5/1.5.0.md](releases/development/1.5/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.4/1.4.1.md](releases/development/1.4/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.4/1.4.0.md](releases/development/1.4/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.3/1.3.0.md](releases/development/1.3/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.2/1.2.0.md](releases/development/1.2/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.1/1.1.1.md](releases/development/1.1/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.1/1.1.0.md](releases/development/1.1/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) for the full release notes.
