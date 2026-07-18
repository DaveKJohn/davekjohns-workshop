<#
.SYNOPSIS
    Regressietests voor de gedeelde-workflow-scripts-mechaniek (issue #81): shared-scripts-lib.ps1,
    de generator/drift-check, en de repo-invariant dat elke plugin-spiegel in sync is met zijn bron.

.DESCRIPTION
    Dependency-vrij: geen Pester nodig, alleen PowerShell. Exit-code 0 als alles slaagt, 1 bij een faal.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/shared-scripts.tests.ps1

    Puur ASCII (repo-conventie voor .ps1).
#>
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')

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

Write-Host "Get-SharedScriptPairs" -ForegroundColor Cyan
$pairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot)
Assert-True ($pairs.Count -ge 1) 'ten minste een gedeeld script geregistreerd'
$fold = $pairs | Where-Object { $_.Name -eq 'fold-changelog-entry' }
Assert-True ($null -ne $fold) 'fold-changelog-entry staat in het register'
Assert-True ($fold.SourceRel -like 'scripts\*') 'bron is repo-root-relatief onder scripts\'
Assert-True ($fold.MirrorRel -like 'claude-code-plugins\*') 'spiegel ligt onder de plugin'

Write-Host "Repo-invariant: elke spiegel in sync met zijn bron" -ForegroundColor Cyan
foreach ($pair in $pairs) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    $mirror = Get-NormalizedScriptContent -Path $pair.MirrorPath
    Assert-True ($null -ne $src) "bron bestaat: $($pair.SourceRel)"
    Assert-True ($null -ne $mirror) "spiegel bestaat: $($pair.MirrorRel)"
    Assert-Equal $src $mirror "in sync: $($pair.Name)"
}

Write-Host "Dual-context resolutie geborgd in elke bron" -ForegroundColor Cyan
# De hele spiegel-mechaniek leunt erop dat een gedeeld script zijn repo-root dual-context oplost.
# Verdwijnt CLAUDE_PROJECT_DIR uit een bron, dan breekt de consument-aanroep stil -- dit vangt dat.
foreach ($pair in $pairs) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    Assert-True ($src -match 'CLAUDE_PROJECT_DIR') "$($pair.Name): bron lost repo-root via CLAUDE_PROJECT_DIR op"
}

Write-Host "Get-NormalizedScriptContent" -ForegroundColor Cyan
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-test-$PID.ps1")
[System.IO.File]::WriteAllText($tmp, "regel1`r`nregel2`r`n", (New-Object System.Text.UTF8Encoding $false))
try {
    $norm = Get-NormalizedScriptContent -Path $tmp
    Assert-Equal "regel1`nregel2`n" $norm 'CRLF wordt LF-genormaliseerd'
} finally {
    Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
}
Assert-Equal $null (Get-NormalizedScriptContent -Path (Join-Path $RepoRoot 'bestaat-niet-xyz.ps1')) 'ontbrekend bestand -> $null'

Write-Host "build-shared-scripts.ps1 -Check -- repo in sync" -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\sync\build-shared-scripts.ps1') -Check | Out-Null
Assert-Equal 0 $LASTEXITCODE 'generator -Check groen op de repo'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAALT: $($script:fail) fout, $($script:pass) goed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: alle $($script:pass) asserts geslaagd." -ForegroundColor Green
exit 0
