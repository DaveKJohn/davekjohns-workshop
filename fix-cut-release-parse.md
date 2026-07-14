### cut-release.ps1 parse-fout gefixt + parse-check aan de lint-poort toegevoegd · Fix · 2026-07-14

`cut-release.ps1` bevatte een parse-fout (een pipeline binnen een `[System.IO.Path]::GetFileName(...)`-
method-call), waardoor het script bij uitvoering meteen brak — de pure logica was getest, de
orkestratie niet. De regel is herschreven (plugin-naam vooraf berekend met `Split-Path`). Om deze
klasse fouten structureel te vangen kreeg de lint-poort
[`check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1) een vijfde check: elke
`scripts/**/*.ps1` moet foutloos parsen (via de PowerShell-parser). Geverifieerd dat de poort een
bewust kapot script betrapt en daarna weer groen is.