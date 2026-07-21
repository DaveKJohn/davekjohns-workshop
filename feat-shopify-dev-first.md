### Shopify theme work is dev-first (shopify theme dev); a pushed preview theme is the fallback · Feat · 2026-07-21

Shopify theme work is now framed dev-first in the core doctrine: theme work is by default developed
and tested locally via `shopify theme dev`; a pushed preview theme is the fallback, used only when
something demonstrably can't be tested through the dev server (e.g. Shopify Markets/currency-specific
behavior, or a third-party integration that needs the real published storefront). Updated in
[Sandra #21](claude-code-plugins/claude-specialists/specialists-shopify/manuals/05-21-manual.md)
(primary owner of the preview/push flow),
[Steven #22](claude-code-plugins/claude-specialists/specialists-shopify/manuals/05-22-manual.md)
(CLI reference — repositions `shopify theme dev` as the default workflow), and
[Liam #20](claude-code-plugins/claude-specialists/specialists-shopify/manuals/04-20-manual.md)
(the theme builder — builds and tests dev-first, with the preview push as the fallback), so the
doctrine runs consistently across both the build and the push role. The live-theme,
preview-cleanup, and cross-browser hard rules are unchanged; only the default order (dev server
before a preview push) changes. Lands inbound issue #124 (from smartwatchbanden); the issue named
Sandra #21 and Steven #22, and Liam #20 (the builder) was folded in by decision so the doctrine runs
across the build role too.