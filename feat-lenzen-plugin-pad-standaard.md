### Repo-lenzen naar het plugin-pad als standaard (primair + legacy-fallback) · Feat · 2026-07-18

De repo-lenzen van deze repo verhuizen van het legacy-pad (`.claude/extensions/`) naar het
**plugin-pad** (`.claude/plugins/claude-specialists/specialists/`) — de nieuwe standaard-locatie
(pariteit met life-hub). Om de andere consumerende repo's (life-hub, smartwatchbanden) niet te breken,
verwijst het gedeelde contract voortaan naar het **plugin-pad als primair, met het legacy-pad als
fallback** — een repo die nog op legacy staat blijft dus gewoon werken.

**Deze repo:**
- De 11 lenzen (incl. Ravi 06-24) + het handboek verplaatst naar het plugin-pad, met de relatieve
  link-diepte bijgesteld (2 → 4 niveaus). De 5 lege stubs (Paula/Bianca/Vera/Gwen/Cody) opgeruimd.
- De `@`-import onderaan `CLAUDE.md` → plugin-pad. Alle doc-verwijzingen (`CLAUDE.md`, `README.md`,
  het handboek) → plugin-pad. De persona-lens-index-regels naar locatie-onafhankelijke platte tekst.
- `check-plugin-integrity.ps1` scant nu de lenzen op het plugin-pad **én** het legacy-pad.

**Het gedeelde contract (raakt alle repo's, via de volgende release):**
- De ~20 agent-defs en de ~20 manuals verwijzen subagents nu naar het plugin-pad (primair) met het
  legacy-pad als fallback. De generieke lens-mention in het gedeelde `grens-inbound`-blok idem.

**Bewust uitgesteld (blijft werken via de fallback):** de **adoptie-laag** — `bootstrap.ps1` seedt
nieuwe consumenten nog op het legacy-pad, en `QUICKSTART.md` / `connectors/README.md` beschrijven dat
zo. Dat volledig omzetten (incl. de bootstrap-tests) is een aparte vervolgstap; tot die tijd landt een
verse consument op legacy en werkt hij via de fallback.

Lint en alle testsuites groen. De `## Releases`-CHANGELOG-entries zijn als historisch record ongemoeid
gelaten.
