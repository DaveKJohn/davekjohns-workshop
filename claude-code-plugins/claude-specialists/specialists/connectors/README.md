# connectors/ — het register van aangesloten repo's

Elke plugin in deze marketplace draagt een eigen `connectors/`-map: **het register van welke
repo's deze plugin geïnstalleerd hebben en of ze nog in sync zijn met deze repo.** Dit README is
de doctrine; de `<repo>.json`-manifesten zijn de data. De map reist mee met de plugin-cache, dus
elke consument kan zijn eigen verwachte staat inzien.

## De doctrine: deze repo is de source of truth

davekjohns-workshop werkt als een **Customer Data Platform**: alle wijzigingen aan gedeelde
plugin-content (agent-defs, manuals, persona-bodies, skills) **landen éérst hier**, en worden pas
daarna doorgesynct naar de aangesloten repo's — nooit andersom (zie de safety-regels in de
repo-[`CLAUDE.md`](../../../../../CLAUDE.md)). Ontstaat er tóch een verbetering in een consument,
dan is dat een **inbound-signaal**: de wijziging wordt eerst hierheen teruggelegd en daarna
opnieuw uitgesynct.

Belangrijke nuance — **wat synct en wat niet**:

- **Wél gesynchroniseerd (bron hier):** de draagbare persona-bodies (alles boven de
  `## Eigen aan deze repo`-marker) en alle plugin-content zelf (agent-defs, manuals, skills).
- **Níét gesynchroniseerd (repo-eigen):** het `## Eigen aan deze repo`-slot van elke extension —
  de repo-lens is per consument verschillend en hoort daar. Het register houdt alleen bij *dát*
  een lens bestaat, nooit wat erin staat.
- **Waarom extensions niet alléén hier kunnen staan:** de sessie in een consumerende repo leest
  de lens-bestanden at runtime uit de **eigen checkout** (agent-defs verwijzen ernaar, en de
  persona van de orchestrator wordt via een `@`-import in de repo-CLAUDE.md geladen). De kopie in
  de consument is dus technisch noodzakelijk; dit register + de check houden hem eerlijk.

## Privacy-grens (harde regel)

Deze repo is **publiek**. Manifesten bevatten daarom uitsluitend **metadata**: repo-naam, plugin,
versies, extension-inventaris (alleen `<group>-<id>`-nummers), status en een relatief
checkout-pad. **Nooit** lens-inhoud, absolute machine-paden of andere gegevens uit de (private)
consumerende repo's.

## Het manifest-format

```json
{
  "repo": "DaveKJohn/life-hub",
  "visibility": "private",
  "localCheckout": "../life-hub",
  "plugin": "specialists@davekjohns-workshop",
  "syncedVersion": "1.1.1",
  "lastChecked": "2026-07-16",
  "status": "in-sync",
  "extensions": ["01-01", "05-05"],
  "notes": ""
}
```

- `localCheckout` is **relatief aan de root van deze repo** (de werkplaats-checkout); staat de
  checkout niet op de machine, dan slaat de check hem over.
- `syncedVersion` is de bronversie waarop deze connector het laatst is gesynct; loopt de bron
  vooruit, dan signaleert de check dat.
- `status`/`notes` zijn de menselijke samenvatting (`in-sync` of `attentie` + toelichting); ze
  worden bijgewerkt wanneer er daadwerkelijk gesynct is, niet bij elke check.

## De check

[`scripts/sync/check-connectors.ps1`](../../../../../scripts/sync/check-connectors.ps1) draait de
two-way-controle over alle manifesten: plugin nog enabled, geregistreerde extensions aanwezig
(outbound), niet-geregistreerde extensions gesignaleerd (inbound), manifest- en machine-versies
tegen de bron, en per consument de content-drift-check
([`check-consumer-drift.ps1`](../../../../../scripts/lint/check-consumer-drift.ps1)). Draai hem
aan het begin van een werkdag of sessie:

```powershell
.\scripts\sync\check-connectors.ps1              # alles
.\scripts\sync\check-connectors.ps1 -SkipDrift   # alleen de registerchecks (snel)
```

Synchroniseren zelf blijft **pull-based per consument**: elke aangesloten repo haalt wijzigingen
op in zijn eigen sessie, onder zijn eigen governance — dit register signaleert, het schrijft
nooit cross-repo.
