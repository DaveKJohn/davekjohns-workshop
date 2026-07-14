<#
.SYNOPSIS
    Regressietests voor het bootstrap-adoptiepad: de skill-bootstrap (bootstrap.ps1) en de
    persona-drift-detectie in check-consumer-drift.ps1.

.DESCRIPTION
    Dependency-vrij: geen Pester, alleen PowerShell. Integratie-stijl -- het draait de echte scripts
    tegen een wegwerp-fixture-consument in de temp-map en assert op hun exit-code + output. De
    scripts roepen zelf 'exit' aan, dus ze worden in een KINDPROCES (powershell -File) gedraaid,
    anders zou 'exit' de testrunner zelf afbreken.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/bootstrap-drift.tests.ps1

    Puur ASCII (repo-conventie voor .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Bootstrap  = Join-Path $RepoRoot 'specialists\skills\specialists-init\bootstrap.ps1'
$DriftLint  = Join-Path $RepoRoot 'scripts\lint\check-consumer-drift.ps1'
$Integrity  = Join-Path $RepoRoot 'scripts\lint\check-plugin-integrity.ps1'
$Fixture    = Join-Path ([System.IO.Path]::GetTempPath()) 'specialists-init-test-fixture'

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

# Draait een .ps1 in een kindproces en geeft [pscustomobject]@{ Code; Out } terug. Out = de
# gecombineerde stdout (incl. Write-Host van het kind). Geen 2>&1 -- de scripts schrijven op de
# happy path niet naar stderr, en 2>&1 op een native exe is in PS 5.1 juist een bron van ruis.
function Invoke-Script {
    param([string]$Path, [string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

function Reset-Fixture {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null
}

try {
    # --- 1. Bootstrap tegen een verse repo -----------------------------------------------------------
    Write-Host "bootstrap.ps1 -- verse repo" -ForegroundColor Cyan
    Reset-Fixture
    $r1 = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-Equal 0 $r1.Code 'bootstrap exit 0 op verse repo'
    foreach ($f in '01-01-extension.md', '05-05-extension.md', '05-06-extension.md') {
        Assert-True (Test-Path -LiteralPath (Join-Path $Fixture ".claude\extensions\$f")) "persona-kopie $f aangemaakt"
    }
    $claudeMd = Join-Path $Fixture 'CLAUDE.md'
    Assert-True (Test-Path -LiteralPath $claudeMd) 'CLAUDE.md-scaffold aangemaakt'
    $mdText = [System.IO.File]::ReadAllText($claudeMd, [System.Text.Encoding]::UTF8)
    Assert-True ($mdText -match [regex]::Escape('@.claude/extensions/01-01-extension.md')) 'CLAUDE.md draagt de orchestrator-import'
    Assert-True (Test-Path -LiteralPath (Join-Path $Fixture '.claude\settings.suggested.jsonc')) 'settings.suggested.jsonc neergezet'

    # --- 2. Idempotentie: tweede run overschrijft niets ----------------------------------------------
    Write-Host "bootstrap.ps1 -- idempotent (tweede run)" -ForegroundColor Cyan
    $r2 = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-Equal 0 $r2.Code 'tweede bootstrap exit 0'
    Assert-True ($r2.Out -match '0 persona') 'tweede run kopieert 0 persona (alles al aanwezig)'
    Assert-True ($r2.Out -match 'bestaat al') 'tweede run laat bestaande kopie met rust'

    # --- 3. Drift op een verse kopie: IDENTICAL ------------------------------------------------------
    Write-Host "check-consumer-drift.ps1 -- verse kopie = IDENTICAL" -ForegroundColor Cyan
    $d1 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-Equal 0 $d1.Code 'drift exit 0 (geen agent-def-drift)'
    Assert-True ($d1.Out -match 'IDENTICAL\] 01-01-persona') 'persona 01-01 body IDENTICAL'
    Assert-True (-not ($d1.Out -match 'DRIFTED\]')) 'geen enkele DRIFTED op verse kopie'

    # --- 4. Drift na een body-wijziging: DRIFTED (informatief, exit blijft 0) ------------------------
    Write-Host "check-consumer-drift.ps1 -- gewijzigde body = DRIFTED" -ForegroundColor Cyan
    $ext = Join-Path $Fixture '.claude\extensions\01-01-extension.md'
    $extText = [System.IO.File]::ReadAllText($ext, [System.Text.Encoding]::UTF8)
    # Wijzig een regel BOVEN de '## Eigen aan deze repo'-marker, zodat de draagbare body afwijkt.
    $extText = $extText.Replace('Chief of Staff', 'OPPERBAAS-TESTWIJZIGING')
    [System.IO.File]::WriteAllText($ext, $extText, (New-Object System.Text.UTF8Encoding($false)))
    $d2 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-Equal 0 $d2.Code 'drift exit blijft 0 (persona-drift is informatief)'
    Assert-True ($d2.Out -match 'DRIFTED\]   01-01-persona') 'persona 01-01 nu DRIFTED na body-wijziging'

    # --- 5. Lint-smoke: de repo zelf blijft groen ----------------------------------------------------
    Write-Host "check-plugin-integrity.ps1 -- smoke" -ForegroundColor Cyan
    $li = Invoke-Script -Path $Integrity -ScriptArgs @()
    Assert-Equal 0 $li.Code 'lint-poort groen op de repo'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAALT: $($script:fail) fout, $($script:pass) goed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: alle $($script:pass) asserts geslaagd." -ForegroundColor Green
exit 0
