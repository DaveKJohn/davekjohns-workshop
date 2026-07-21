<#
Maakt het changelog entry-bestand voor de huidige branch aan in de repo-root:
<branch-naam-met-koppeltekens>.md, met branch-naam, datum en branch-type al ingevuld.

Gebruik:
  .\scripts\release\new-changelog-entry.ps1 -Title "Korte titel van de wijziging"

Branch-type wordt afgeleid uit het branch-prefix via de gedeelde tabel in
scripts/lib/branch-info.ps1 (feat/fix/docs/chore).
Onbekend prefix -> valt terug op "Chore" met een waarschuwing, zelf aanpassen in het bestand.

Interne handoff vanuit new-branch.ps1: dat script roept dit bestand aan als kindproces zonder
-Title, en geeft de titel in plaats daarvan door via de omgevingsvariabele
CLAUDE_NEWBRANCH_TITLE. Reden: vrije tekst (bv. gekopieerd uit een externe issue/PR-titel) als los
CLI-argument over een native procesgrens is een injectie-primitief (aanhalingstekens/backslashes
kunnen de argv-reconstructie van het kindproces breken); env-var-waarden gaan niet door
argv-requoting. Staat -Title er expliciet bij (standalone-gebruik), dan wint die altijd; alleen als
-Title op zijn eigen default staat EN de env-var gezet is, wordt de env-var gebruikt.
#>

param(
    [string]$Title = "TODO: titel"
)

$ErrorActionPreference = "Stop"

# Zie de handoff-uitleg hierboven: alleen overnemen als de param nog op zijn eigen default staat,
# zodat een expliciete -Title (standalone-gebruik) altijd voorrang houdt.
if ($Title -eq "TODO: titel" -and $env:CLAUDE_NEWBRANCH_TITLE) {
    $Title = $env:CLAUDE_NEWBRANCH_TITLE
}

# Repo-root -- dual-context: draait een consument de gedeelde plugin-spiegel, dan levert
# CLAUDE_PROJECT_DIR diens repo-root; in de workshop-root (of buiten een sessie) valt het terug op de
# git-root. Zo werkt DEZELFDE file in beide locaties, en blijven de root-kopie en de plugin-spiegel
# byte-identiek (bewaakt door de shared-scripts-drift-lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# Pre-flight (#86): dit script leunt ALLEEN op scripts\lib\branch-info.ps1 in de repo-root van de
# consument (geen repo-config, geen gh -- lichter dan fold/open-pr). Ontbreekt dat -- typisch op een
# schone consument -- stop met een duidelijke wegwijzer i.p.v. een rauwe dot-source-fout hieronder.
$branchInfoPath = Join-Path $repoRoot 'scripts\lib\branch-info.ps1'
if (-not (Test-Path -LiteralPath $branchInfoPath)) {
    Write-Error "new-changelog-entry kan niet draaien -- ontbrekend repo-eigen bestand: $branchInfoPath (Get-BranchInfo / de branch-prefix-tabel). Dit bestand is repo-specifiek en hoort in de repo-root van de consument. Maak het aan (de specialists-init-bootstrap zet een VUL-IN-scaffold neer, of neem een bestaande consument / de werkplaats-repo als model) en draai daarna opnieuw."
    exit 1
}

# BOM-loze UTF8 -- Set-Content -Encoding UTF8 voegt in Windows PowerShell 5.1 altijd een BOM
# toe, en de rest van de repo heeft geen BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq "main") {
    Write-Host "Je zit op main - maak eerst een branch aan." -ForegroundColor Red
    exit 1
}

. $branchInfoPath

$info = Get-BranchInfo -Branch $branch
$branchType = $info.Type
if (-not $branchType) {
    $branchType = "Chore"
    Write-Host "Onbekend branch-prefix '$($info.Prefix)' - 'Branch type' op 'Chore' gezet, pas dit handmatig aan indien nodig." -ForegroundColor Yellow
}

$fileName = $info.SafeName + ".md"
$filePath = Join-Path $repoRoot $fileName

if (Test-Path $filePath) {
    Write-Host "Entry-bestand '$fileName' bestaat al - niets gedaan." -ForegroundColor Yellow
    exit 0
}

$today = Get-Date -Format "yyyy-MM-dd"
$midDot = [char]0x00B7

# Compacte kop, gelijk aan het CHANGELOG-format (fold voegt straks alleen '#NN <midDot> ' vooraan en
# de '[PR #NN](url)'-link onderaan toe -- die bestaan pas na het openen van de PR).
$template = @"
### $Title $midDot $branchType $midDot $today

TODO: korte beschrijving van wat er veranderd is op deze branch.
"@

[System.IO.File]::WriteAllText($filePath, $template, $Utf8NoBom)
Write-Host "Aangemaakt: $fileName" -ForegroundColor Green
