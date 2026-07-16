### Nacorrecties van Victor op de test-poort · Fix · 2026-07-16

Twee nacorrecties uit Victor's review van PR #56: het root-README beschrijft de PR-flow nu met de
dubbele poort (lint + tests) in plaats van alleen de lint-poort, en de test-poort in `open-pr.ps1`
waarschuwt voortaan expliciet wanneer er nul testsuites gevonden worden in plaats van stilzwijgend
te slagen. Victor's helper-suggestie (gedeeld poort-patroon) is bewust geparkeerd tot er een derde
poort bijkomt.