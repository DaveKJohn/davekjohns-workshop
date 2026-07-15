# Plugin-sharing-traject — stand & vervolgstappen

> Logboek van de afronding van het marketplace-migratie-traject
> (claude-specialists → davekjohns-workshop). Spiegelt de traject-documentatie in
> smartwatchbanden (`research/plugin-sharing/`). Laatst bijgewerkt: **15 juli 2026**.

## Stand van zaken (geverifieerd 15 juli 2026)

Beide consumerende repo's zijn over op de `davekjohns-workshop`-marketplace
(github-source `DaveKJohn/davekjohns-workshop`):

| Consument | Status | Bewijs |
|---|---|---|
| **smartwatchbanden** | ✅ Over | swb PR #185; rooktest geslaagd — 13 specialist-agents geladen uit de plugin-cache (10× `specialists`, 3× `specialists-shopify`) |
| **life-hub** | ✅ Over | commit `ade7d4b` ("config: marketplace hernoemd naar davekjohns-workshop"); `specialists` + `specialists-lifehub` ingeschakeld; drift-check vanuit dit repo: exit 0 (18 agent-defs MISSING = gemigreerd, persona's IDENTICAL) |

Dit repo zelf: drie plugins (`specialists`, `specialists-lifehub`, `specialists-shopify`),
alle **v1.0.0**; `check-plugin-integrity.ps1` groen; de repo consumeert zichzelf via de
github-source (zie [`CLAUDE.md`](../../CLAUDE.md)).

## Vervolgstappen

1. **Oude `claude-specialists`-marketplace-kloon opruimen** — nu beide consumenten over
   zijn, is de blokkade weg. Handmatige actie van Dave, op **beide machines** (beide
   Windows-profielen):
   `/plugin marketplace remove claude-specialists`
   De kloon staat in `~/.claude/plugins/cache/claude-specialists/`.
2. **Borging in smartwatchbanden** — de migratie-afronding (rooktest, stale
   `.in_use`-marker-les: sessie-herstart was de fix) daar vastleggen in
   `research/plugin-sharing/README.md`; staat nu alleen in swb-sessiegeheugen.
3. **Klein, geen haast:** de lokale checkout-map van dit repo heet nog
   `...\DaveKJohn\claude-specialists` terwijl de remote `davekjohns-workshop` is.
   Lokale hernoem-actie kan later; raakt het memory-pad van lopende sessies.

## Geleerde lessen

- **Stale `.in_use`-marker** op een oud marketplace-pad kan verhinderen dat agents laden;
  een sessie-herstart is de fix (swb-rooktest, 15 juli 2026).
- **Context-overdrachten verouderen snel:** de swb-overdracht van 15 juli meldde life-hub
  nog als openstaand, terwijl die dezelfde dag al gemigreerd en gecommit bleek. Verifieer
  een overdracht altijd tegen de actuele repo-staat vóór je erop routeert.
