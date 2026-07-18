### Persona-sjabloon-intro's gededupliceerd (Ravi's eerste klus) · Chore · 2026-07-18

Ravi's eerste opdracht: de persona-sjablonen op duplicatie scannen. Bevinding — er zijn **geen
verbatim-gedeelde gedragsbullets** over de vier persona's (Chris, Bianca, Derek, Rendall); de
gedragsregels zijn bewust rol-geformuleerd (rol-nuance, niet harmoniseren). De énige verbatim-duplicatie
was het **intro-uitleg-commentaar** — een grotendeels identieke herhaling van het gesplitste model dat
`README.md` al vastlegt, en dat (in een HTML-commentaar) het gedeelde-blok-mechanisme sowieso niet kan
gebruiken.

Actie: het intro-commentaar in de vier sjablonen ingekort tot een korte verwijzing naar `README.md`,
met behoud van de rol-specifieke eerste regel. Netto ~33 regels boilerplate weg, en minder ruis die een
lens-only consument via de `@`-import meelaadt (sluit aan op de #69-schoonmaak). Het commentaar staat
boven de H1, dus `Get-PortableBody` raakt het niet — geen drift-regressie.

Conclusie voor de toekomst: het sentinel-mechanisme uitbreiden naar persona's heeft nú geen payload
(geen deelbaar body-blok); dat wacht tot een verbatim-gedeelde persona-bullet daadwerkelijk opduikt.
