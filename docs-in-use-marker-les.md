### Marker-structuur-les geborgd: .in_use is een map met PID-bestanden · Docs · 2026-07-15

Geleerde les uit de cache-opruiming na de v1.1.1-herstart geborgd in
`research/plugin-sharing/vervolgstappen.md`: de `.in_use`-marker van een plugin-cache-versie is geen
bestand maar een **map**, waarin elke gebruikende sessie een eigen PID-bestand (`{"pid":N}`)
schrijft. In-gebruik-zijn check je dus niet met een file-lock-test (die geeft op een map altijd vals
alarm), maar door in de map te kijken: leeg = vrij, en een aanwezig PID-bestand wijst exact de
gebruikende sessie aan. Daarnaast is vervolgstap 3 geactualiseerd: de twee verweesde cache-mappen
(`specialists/1.0.0` en `1.1.0`) zijn na de sessie-herstart daadwerkelijk verwijderd, met de
v1.1.1-verificatie erbij vermeld.