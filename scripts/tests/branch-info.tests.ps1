<#
.SYNOPSIS
    Regressietests voor scripts/lib/branch-info.ps1 (de gedeelde branch-conventies + type-SSOT).

.DESCRIPTION
    Dependency-vrij: geen Pester nodig, alleen PowerShell. Dot-source't de lib en draait een reeks
    asserts. Exit-code 0 als alles slaagt, 1 bij een faal -- zo bruikbaar in een CI-poort.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/branch-info.tests.ps1

    Bewaakt in het bijzonder het SSOT-contract dat het DRY-lek dichtte (issue #81): de branch-typen
    hebben een enige bron (Get-BranchTypes) die release-lib.ps1 leest i.p.v. een eigen kopie.

    Puur ASCII (repo-conventie voor .ps1).
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\branch-info.ps1')

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         verwacht: '$Expected'`n         kreeg:    '$Actual'" -ForegroundColor Red
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

Write-Host "Get-BranchPrefix" -ForegroundColor Cyan
Assert-Equal 'feat'  (Get-BranchPrefix -Branch 'feat/nieuwe-plugin') "slash-prefix 'feat/...' -> feat"
Assert-Equal 'fix'   (Get-BranchPrefix -Branch 'fix/kapotte-frontmatter') "slash-prefix 'fix/...' -> fix"
Assert-Equal 'chore' (Get-BranchPrefix -Branch 'chore-losse-naam') "koppelteken-prefix zonder slash -> chore"

Write-Host "Get-BranchInfo" -ForegroundColor Cyan
$feat = Get-BranchInfo -Branch 'feat/nieuwe-plugin'
Assert-Equal $true        $feat.IsKnown  'bekend prefix -> IsKnown'
Assert-Equal 'enhancement' $feat.Label   'feat -> label enhancement'
Assert-Equal 'Feat'        $feat.Type    'feat -> type Feat'
Assert-Equal 'feat-nieuwe-plugin' $feat.SafeName 'SafeName vervangt / door -'

$docs = Get-BranchInfo -Branch 'docs/readme-bijwerken'
Assert-Equal 'documentation' $docs.Label 'docs -> label documentation'
Assert-Equal 'Docs'          $docs.Type  'docs -> type Docs'

$unknown = Get-BranchInfo -Branch 'wip/experiment'
Assert-Equal $false $unknown.IsKnown 'onbekend prefix -> niet IsKnown'
Assert-Equal $null  $unknown.Label   'onbekend prefix -> geen label'
Assert-Equal $null  $unknown.Type    'onbekend prefix -> geen type'

Write-Host "Get-BranchTypes (type-SSOT, issue #81)" -ForegroundColor Cyan
$types = @(Get-BranchTypes)
Assert-Equal 'Feat Fix Docs Chore' ($types -join ' ') 'canonieke typen in vaste volgorde'

# SSOT-contract: elke Type-waarde in de prefix-tabel is lid van Get-BranchTypes, en andersom heeft
# elk canoniek type ten minste een prefix. Zo kan de tabel niet driften t.o.v. de canonieke lijst
# (en release-lib.ps1, dat de lijst hergebruikt, blijft in sync).
$tableTypes = @($script:BranchPrefixTable.Values | ForEach-Object { $_.Type } | Sort-Object -Unique)
foreach ($t in $tableTypes) {
    Assert-True ($types -contains $t) "tabel-type '$t' zit in Get-BranchTypes"
}
foreach ($t in $types) {
    Assert-True ($tableTypes -contains $t) "canoniek type '$t' heeft een prefix in de tabel"
}

Write-Host "Test-BranchName (SSOT-validatiehelper, new-branch.ps1)" -ForegroundColor Cyan
$validCheck = Test-BranchName -Branch 'feat/nieuwe-plugin'
Assert-Equal $true $validCheck.IsValid 'geldige naam -> IsValid'
Assert-Equal $null  $validCheck.Reason 'geldige naam -> geen Reason'
Assert-Equal $true  $validCheck.IsKnown 'geldige naam (bekend prefix) -> IsKnown'

$mainCheck = Test-BranchName -Branch 'main'
Assert-Equal $false $mainCheck.IsValid "'main' -> IsValid false"
Assert-Equal "Branch-naam mag niet 'main' zijn." $mainCheck.Reason "'main' -> verwachte Reason"

$finalCheck = Test-BranchName -Branch 'feat/final-versie'
Assert-Equal $false $finalCheck.IsValid "naam met token 'final' -> IsValid false"
Assert-Equal "Branch-naam mag het token 'final' niet bevatten." $finalCheck.Reason "token 'final' -> verwachte Reason"

$emptyCheck = Test-BranchName -Branch ''
Assert-Equal $false $emptyCheck.IsValid 'lege naam -> IsValid false'
Assert-Equal "Branch-naam mag niet leeg zijn." $emptyCheck.Reason 'lege naam -> verwachte Reason'

$wsCheck = Test-BranchName -Branch '   '
Assert-Equal $false $wsCheck.IsValid 'whitespace-only naam -> IsValid false'
Assert-Equal "Branch-naam mag niet leeg zijn." $wsCheck.Reason 'whitespace-only naam -> verwachte Reason'

$unknownCheck = Test-BranchName -Branch 'wip/experiment'
Assert-Equal $true  $unknownCheck.IsValid 'onbekend prefix -> IsValid true (soft-warn-pad, geen hard-reject)'
Assert-Equal $false $unknownCheck.IsKnown 'onbekend prefix -> IsKnown false'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAALT: $($script:fail) fout, $($script:pass) goed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: alle $($script:pass) asserts geslaagd." -ForegroundColor Green
exit 0
