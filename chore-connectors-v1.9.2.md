### connector-register bijgewerkt voor v1.9.2 (workshop gesynct, consumenten op attentie) · Chore · 2026-07-19

Werkt het connectors-register bij na de v1.9.1/v1.9.2-releases.

- **davekjohns-workshop** (consumeert zichzelf, cache op v1.9.2): `syncedVersion` `1.4.1` → `1.9.2`,
  en `06-24` (Ravi) toegevoegd aan de extension-inventaris (bestond wel, stond niet in het register).
- **life-hub** en **smartwatchbanden**: `status` → `attentie` met een gedateerde notitie dat de bron
  op v1.9.2 staat en zij nog niet gepulld hebben. `syncedVersion` **bewust ongewijzigd** — die wordt
  per doctrine pas gebumpt wanneer de consument daadwerkelijk synct (`claude plugin update` in de
  eigen sessie); het register schrijft nooit cross-repo.