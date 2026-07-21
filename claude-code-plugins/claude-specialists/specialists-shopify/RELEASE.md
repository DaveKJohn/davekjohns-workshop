# Release v1.15.0

**Date:** 2026-07-21  
**Type:** Minor

English script layer, Shopify dev-first, consumer-fit open-pr/fold, and shared release/check helpers

You are on this release.

## v1.15.0 — 2026-07-21

### #126 · Shopify theme work is dev-first (shopify theme dev); a pushed preview theme is the fallback · Feat · 2026-07-21

Shopify theme work is now framed dev-first in the core doctrine: theme work is by default developed
and tested locally via `shopify theme dev`; a pushed preview theme is the fallback, used only when
something demonstrably can't be tested through the dev server (e.g. Shopify Markets/currency-specific
behavior, or a third-party integration that needs the real published storefront). Updated in
[Sandra #21](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/specialists-shopify/manuals/05-21-manual.md)
(primary owner of the preview/push flow),
[Steven #22](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/specialists-shopify/manuals/05-22-manual.md)
(CLI reference — repositions `shopify theme dev` as the default workflow), and
[Liam #20](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/specialists-shopify/manuals/04-20-manual.md)
(the theme builder — builds and tests dev-first, with the preview push as the fallback), so the
doctrine runs consistently across both the build and the push role. The live-theme,
preview-cleanup, and cross-browser hard rules are unchanged; only the default order (dev server
before a preview push) changes. Lands inbound issue #124 (from smartwatchbanden); the issue named
Sandra #21 and Steven #22, and Liam #20 (the builder) was folded in by decision so the doctrine runs
across the build role too.

[PR #126](https://github.com/DaveKJohn/davekjohns-workshop/pull/126)

---

### #123 · Translate the GEGENEREERD, bewerk sentinel marker to English across the agent defs · Docs · 2026-07-21

Translated the last Dutch fragment in the agent-def shared-block sentinel comments to English, in
line with the repo-wide English-content norm: `<!-- BEGIN shared:NAME -- GEGENEREERD, bewerk
agent-shared/NAME.md -->` becomes `<!-- BEGIN shared:NAME -- GENERATED, edit agent-shared/NAME.md
-->`. The marker is literal per-file text (the generator preserves the BEGIN/END sentinel lines
as-is and only fills the body between them), so all 21 agent-defs across the three plugins were
updated directly, plus the one docstring example in `agent-shared-lib.ps1` and the one test
fixture string in `agent-shared.tests.ps1`. No regex in the generator or the lint gate matched the
Dutch text, so nothing there needed changing. Verified: `build-agent-defs.ps1 -Check` (in sync),
`check-plugin-integrity.ps1` (0 errors), and all `scripts/tests/*.tests.ps1` suites green.

[PR #123](https://github.com/DaveKJohn/davekjohns-workshop/pull/123)

---

Full workshop notes: [releases/development/1.15/1.15.0.md](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/releases/development/1.15/1.15.0.md)
Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)
