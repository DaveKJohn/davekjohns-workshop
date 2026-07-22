### Group the e-commerce-related plugins in the family README · Docs · 2026-07-22

Added an "E-commerce-related plugins" reading aid to the family README
(`claude-code-plugins/claude-specialists/README.md`): a short subsection that presents
`specialists-shopify` (the platform layer) and `specialists-ecomm` (the platform-agnostic
disciplines — SEO/CRO/SEA) together as the two plugins that serve a commercial webshop, and notes
that a Shopify store repo typically enables both while a non-Shopify webshop enables just
`specialists-ecomm`. Deliberately **documentary only** — no folder move: a feasibility check found
that physically nesting the plugins under an `ecommerce/` sub-family would functionally break the
release-pipeline plugin detection (`release-lib.ps1`), the connector check (`check-connectors.ps1`),
and silently skip the drift check (`check-consumer-drift.ps1`), for a purely cosmetic gain — so the
conceptual grouping is captured in the docs instead, at zero regression risk. Every plugin remains
independently enable-able.