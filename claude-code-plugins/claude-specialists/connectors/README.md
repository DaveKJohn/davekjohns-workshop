# connectors/ — het register van aangesloten repo's

Dit is het register van **welke repo's de plugins van deze familie geïnstalleerd hebben en of ze
nog in sync zijn met deze repo** — één `<repo>.json`-manifest per aangesloten repo, direct in
deze map, met daarin per plugin de gesyncte versie en de extension-inventaris. De connector ís de
repo. Dit README is de doctrine; de manifesten zijn de data.

**Het register woont bewust op familie-niveau, náást de plugin-mappen — niet erin.** De
marketplace-sources wijzen naar de plugin-mappen zelf, dus dit register reist *niet* mee met de
plugin-cache van consumenten: geen enkele consument ziet zo de manifesten van een ander (besluit
Dave, 16 juli 2026, na de security-review). Het register is werkplaats-administratie.

## De doctrine: deze repo is de source of truth

davekjohns-workshop werkt als een **Customer Data Platform**: alle wijzigingen aan gedeelde
plugin-content (agent-defs, manuals, persona-bodies, skills) **landen éérst hier**, en worden pas
daarna doorgesynct naar de aangesloten repo's — nooit andersom (zie de safety-regels in de
repo-[`CLAUDE.md`](../../../CLAUDE.md)). Ontstaat er tóch een verbetering in een consument, dan
is dat een **inbound-signaal**: de wijziging wordt eerst hierheen teruggelegd en daarna opnieuw
uitgesynct.

Belangrijke nuance — **wat synct en wat niet**:

- **Wél gesynchroniseerd (bron hier):** de draagbare persona-bodies (alles boven de
  `## Eigen aan deze repo`-marker) en alle plugin-content zelf (agent-defs, manuals, skills).
- **Níét gesynchroniseerd (repo-eigen):** het `## Eigen aan deze repo`-slot van elke extension —
  de repo-lens is per consument verschillend en hoort daar thuis. Het register houdt alleen bij
  *dát* een lens bestaat, nooit wat erin staat.
- **Waarom extensions niet alléén hier kunnen staan:** de sessie in een consumerende repo leest
  de lens-bestanden runtime uit de **eigen checkout** (agent-defs verwijzen ernaar, en de
  persona van de orchestrator wordt via een `@`-import in de repo-CLAUDE.md geladen). De kopie in
  de consument is dus technisch noodzakelijk; dit register + de check houden hem eerlijk.

## Privacy-grens (harde regel)

Deze repo is **publiek**. Manifesten bevatten daarom uitsluitend **metadata**: repo-naam, plugin,
versies, extension-inventaris (alleen `<group>-<id>`-nummers), status en een relatief
checkout-pad. **Nooit** lens-inhoud, absolute machine-paden of andere gegevens uit de (private)
consumerende repo's. De relatieve `localCheckout`-paden onthullen de sibling-indeling van de
lokale checkouts; dat is een bewust geaccepteerde mate van transparantie (security-review,
16 juli 2026).

## Het manifest-format

```json
{
  "repo": "DaveKJohn/life-hub",
  "visibility": "private",
  "localCheckout": "../life-hub",
  "lastChecked": "2026-07-16",
  "status": "in-sync",
  "plugins": [
    {
      "id": "specialists@davekjohns-workshop",
      "syncedVersion": "1.1.1",
      "extensions": ["01-01", "05-05"]
    }
  ],
  "notes": ""
}
```

- `localCheckout` is **relatief aan de root van deze repo** (de werkplaats-checkout); staat de
  checkout niet op de machine, dan slaat de check hem over. Absolute paden en paden buiten de
  scope-root worden door de check geweigerd.
- `plugins` bevat per geïnstalleerde plugin de `syncedVersion` (de bronversie waarop deze
  connector het laatst is gesynct; loopt de bron vooruit, dan signaleert de check dat) en de
  `extensions`-inventaris van die plugin.
- `status`/`notes` zijn de menselijke samenvatting (`in-sync` of `attentie` + toelichting); ze
  worden bijgewerkt wanneer er daadwerkelijk gesynct is, niet bij elke check.

## De check

[`scripts/sync/check-connectors.ps1`](../../../scripts/sync/check-connectors.ps1) draait de
two-way-controle over alle manifesten: plugin nog enabled, geregistreerde extensions aanwezig
(outbound), niet-geregistreerde extensions gesignaleerd (inbound), manifest- en machine-versies
tegen de bron, en per consument de content-drift-check
([`check-consumer-drift.ps1`](../../../scripts/lint/check-consumer-drift.ps1)). Draai hem aan
het begin van een werkdag of sessie:

```powershell
.\scripts\sync\check-connectors.ps1              # alles
.\scripts\sync\check-connectors.ps1 -SkipDrift   # alleen de registerchecks (snel)
```

Synchroniseren zelf blijft **pull-based per consument**: elke aangesloten repo haalt wijzigingen
op in zijn eigen sessie, onder zijn eigen governance — dit register signaleert, het schrijft
nooit cross-repo.

## De sessie-check (automatisch)

De `specialists`-plugin draagt een **SessionStart-hook**
([`hooks/hooks.json`](../specialists/hooks/hooks.json) +
[`connector-sessioncheck.ps1`](../specialists/hooks/connector-sessioncheck.ps1)) die bij het
starten van een sessie — in élke repo die de plugin heeft, dus ook life-hub en smartwatchbanden —
de workshop-checkout zoekt en daar de connectors-check draait. Twee guardrails uit de
security-review: het gevonden pad wordt eerst **geverifieerd** (marker-check op de
marketplace-naam in `.claude-plugin/marketplace.json` — nooit code draaien op een padgok), en
buiten de workshop is de check **gescoped** tot het manifest van de eigen repo, zodat een sessie
nooit de registerdata van een andere consument in zijn context krijgt. De hook is verder bewust
zacht: geen geverifieerde workshop-checkout betekent een melding en verder niets, signalen komen
als compacte samenvatting in de sessie-context, en de hook blokkeert nooit een sessiestart
(altijd exit 0, read-only). Deze hook is — naast de skill `specialists-init` — de tweede
benoemde, repo-neutrale uitzondering op de regel dat plugins geen hooks/skills dragen (zie de
root-README). Let op de **versie-poort**: consumenten ontvangen de hook pas na een release-bump
én een `claude plugin update` + sessie-herstart aan hun kant.
