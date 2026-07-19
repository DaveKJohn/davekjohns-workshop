### Canoniek marketplace-kanaal gedocumenteerd (oude claude-specialists-naam is een redirect) · Docs · 2026-07-19

Legt de marketplace-kanaal-strategie vast, na een inbound-bevinding uit de djcylow-react-acceptatietest
van v1.10.0: een consument zag op het `claude-specialists`-kanaal stil de oude v1.9.2.

- **Bevinding (geen codegat):** `DaveKJohn/claude-specialists` is **geen aparte repo** maar de oude
  naam van deze repo — een GitHub-rename-redirect naar `DaveKJohn/davekjohns-workshop`
  (`git ls-remote` op de oude naam geeft de actuele `HEAD`, v1.10.0). De "1.9.2 op dat kanaal" was een
  **verouderde lokale marketplace-clone**, geen achterlopende bron. Route "mirror v1.10.0 naar
  claude-specialists" is dus niet van toepassing — het is dezelfde repo.
- **`README.md` (Consumptie):** notitie toegevoegd dat `davekjohns-workshop` het enige canonieke
  kanaal is, dat de oude `claude-specialists`-naam via redirect naar dezelfde repo wijst (geen tweede
  bron), en dat een oude lokale registratie kan achterlopen — bij te werken met een marketplace-update
  of opnieuw toe te voegen onder de canonieke naam. Een verse install gebruikt altijd
  `DaveKJohn/davekjohns-workshop`.

Geen open issues om te sluiten; v1.10.0 dekt #90, #91 (incl. userinfo-tolerantie) en #92 aantoonbaar
af (in een echte consument geverifieerd).