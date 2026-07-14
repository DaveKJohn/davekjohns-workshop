<#
Maakt het changelog entry-bestand voor de huidige branch aan in de repo-root:
<branch-naam-met-koppeltekens>.md, met branch-naam, datum en branch-type al ingevuld.

Gebruik:
  .\scripts\release\new-changelog-entry.ps1 -Title "Korte titel van de wijziging"

Branch-type wordt afgeleid uit het branch-prefix via de gedeelde tabel in
scripts/lib/branch-info.ps1 (feat/fix/docs/chore).
Onbekend prefix -> valt terug op "Chore" met een waarschuwing, zelf aanpassen in het bestand.
#>

param(
    [string]$Title = "TODO: titel"
)

$ErrorActionPreference = "Stop"

# BOM-loze UTF8 -- Set-Content -Encoding UTF8 voegt in Windows PowerShell 5.1 altijd een BOM
# toe, en de rest van de repo heeft geen BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq "master") {
    Write-Host "Je zit op master - maak eerst een branch aan." -ForegroundColor Red
    exit 1
}

. (Join-Path $PSScriptRoot '..\lib\branch-info.ps1')

$info = Get-BranchInfo -Branch $branch
$branchType = $info.Type
if (-not $branchType) {
    $branchType = "Chore"
    Write-Host "Onbekend branch-prefix '$($info.Prefix)' - 'Branch type' op 'Chore' gezet, pas dit handmatig aan indien nodig." -ForegroundColor Yellow
}

$fileName = $info.SafeName + ".md"
$repoRoot = (git rev-parse --show-toplevel).Trim()
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
