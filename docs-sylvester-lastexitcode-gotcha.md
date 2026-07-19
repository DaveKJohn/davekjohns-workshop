### PowerShell-exitcode-valkuil geborgd in Sylvester's repo-lens · Docs · 2026-07-19

Legt de scriptregel vast die de flaky CI-jacht (#94/#95/#96) opleverde, zodat een vierde herhaling
wordt voorkomen.

- **`05-15-extension.md` (Repo-eigen regels):** bullet toegevoegd — `$LASTEXITCODE` altijd lezen
  vóór je een native command (bv. `git`) door een cmdlet pipt. `& git … | Select-Object -First 1`
  breekt de upstream vroegtijdig af, wat de exitcode timing-afhankelijk op non-nul kan zetten en zo een
  niet-deterministisch rode CI inbouwt. De regel: eerst de volledige output vangen, meteen
  `$code = $LASTEXITCODE` vastleggen, en pas daarna filteren op de vaste array. Geldt voor elke
  `scripts/**/*.ps1` die een native command aanroept.

Borgt de les uit #96 op een draagbare plek (de docs, niet alleen het geheugen).
