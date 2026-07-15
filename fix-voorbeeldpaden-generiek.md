### Voorbeeldpaden gegeneraliseerd (geen lokale accountnamen) · Fix · 2026-07-15

De laag-ernst-bevinding uit Sean's security-nulmeting (`research/security/nulmeting-2026-07-15.md`)
opgelost: de letterlijke lokale Windows-paden mét accountnamen zijn vervangen door generieke
placeholders. De twee `.EXAMPLE`-regels in `scripts/lint/check-consumer-drift.ps1` gebruiken nu de
`C:\pad\naar\…`-stijl die `bootstrap.ps1` en de `README.md` al hanteerden, en de profielnamen in
`research/plugin-sharing/vervolgstappen.md` zijn vervangen door "beide Windows-profielen". Een
repo-brede scan bevestigt dat er geen lokale accountnamen meer in de werkboom staan.