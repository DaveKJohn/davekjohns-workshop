<#
.SYNOPSIS
    Regressietests voor de gedeelde agent-def-blokken: de lib (agent-shared-lib.ps1), de generator
    (build-agent-defs.ps1) en de drift-poort in check-plugin-integrity.ps1.

.DESCRIPTION
    Dependency-vrij: geen Pester, alleen PowerShell. De unit-tests dot-sourcen de lib en draaien
    Expand-AgentDefShared tegen in-geheugen-fixtures; de smoke-tests draaien de echte scripts als
    KINDPROCES (powershell -File) omdat ze zelf 'exit' aanroepen.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/agent-shared.tests.ps1

    Puur ASCII (repo-conventie voor .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot  = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Lib       = Join-Path $RepoRoot 'scripts\lib\agent-shared-lib.ps1'
$Build     = Join-Path $RepoRoot 'scripts\agents\build-agent-defs.ps1'
$Integrity = Join-Path $RepoRoot 'scripts\lint\check-plugin-integrity.ps1'
$Fixture   = Join-Path ([System.IO.Path]::GetTempPath()) 'agent-shared-test-fixture'

. $Lib

$script:pass = 0
$script:fail = 0
function Assert-Equal { param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Name`n         verwacht: '$Expected'`n         kreeg:    '$Actual'" -ForegroundColor Red }
}
function Assert-True { param([bool]$Condition, [string]$Name)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red }
}
function Invoke-Script { param([string]$Path, [string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}
function New-Problems { New-Object System.Collections.Generic.List[string] }

try {
    # --- Fixture-bron: een gedeeld blok 'greeting' ---------------------------------------------------
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null
    $blockText = "- hallo wereld`n- tweede regel"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'greeting.md'), "$blockText`n", (New-Object System.Text.UTF8Encoding($false)))

    $begin = '<!-- BEGIN shared:greeting -- GENERATED, edit agent-shared/greeting.md -->'
    $end   = '<!-- END shared:greeting -->'
    $inSync = "voor`n$begin`n$blockText`n$end`nna"

    # --- 1. In-sync inhoud blijft gelijk; geen problemen ---------------------------------------------
    Write-Host "Expand-AgentDefShared -- in sync" -ForegroundColor Cyan
    $p1 = New-Problems
    $o1 = Expand-AgentDefShared -Content $inSync -SharedDir $Fixture -Problems $p1
    Assert-Equal $inSync $o1 'in-sync inhoud blijft byte-gelijk'
    Assert-Equal 0 $p1.Count 'geen problemen op in-sync inhoud'

    # --- 2. Drift wordt gedetecteerd en hersteld naar de bron ----------------------------------------
    Write-Host "Expand-AgentDefShared -- drift" -ForegroundColor Cyan
    $stale = "voor`n$begin`n- HANDMATIG GEWIJZIGD`n$end`nna"
    $p2 = New-Problems
    $o2 = Expand-AgentDefShared -Content $stale -SharedDir $Fixture -Problems $p2
    Assert-True ($o2 -ne $stale) 'drift gedetecteerd (expand wijkt af van de input)'
    Assert-Equal $inSync $o2 'expand herstelt de regio naar de canonieke bron'

    # --- 3. BEGIN zonder END wordt gemeld ------------------------------------------------------------
    Write-Host "Expand-AgentDefShared -- BEGIN zonder END" -ForegroundColor Cyan
    $noEnd = "voor`n$begin`n- iets"
    $p3 = New-Problems
    $null = Expand-AgentDefShared -Content $noEnd -SharedDir $Fixture -Problems $p3
    Assert-True ($p3.Count -ge 1) 'BEGIN zonder END wordt als probleem gemeld'

    # --- 4. Onbekend blok (bron ontbreekt) wordt gemeld ----------------------------------------------
    Write-Host "Expand-AgentDefShared -- onbekend blok" -ForegroundColor Cyan
    $unknown = "voor`n<!-- BEGIN shared:bestaatniet -->`n- x`n<!-- END shared:bestaatniet -->`nna"
    $p4 = New-Problems
    $null = Expand-AgentDefShared -Content $unknown -SharedDir $Fixture -Problems $p4
    Assert-True ($p4.Count -ge 1) 'onbekend blok (ontbrekende bron) wordt gemeld'

    # --- 5. Meerdere blokken in EEN agent-def worden alle gevuld -------------------------------------
    Write-Host "Expand-AgentDefShared -- meerdere blokken" -ForegroundColor Cyan
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'tweede.md'), "- blok twee`n", (New-Object System.Text.UTF8Encoding($false)))
    $b2 = '<!-- BEGIN shared:tweede -->'; $e2 = '<!-- END shared:tweede -->'
    $multiStale = "kop`n$begin`n- oud`n$end`nmidden`n$b2`n- oud2`n$e2`nslot"
    $p5 = New-Problems
    $o5 = Expand-AgentDefShared -Content $multiStale -SharedDir $Fixture -Problems $p5
    Assert-True ($o5 -match 'hallo wereld' -and $o5 -match 'blok twee') 'beide blokken uit hun bron gevuld'
    Assert-True (-not ($o5 -match 'oud2')) 'stale inhoud van het tweede blok vervangen'

    # --- 6. Smoke: de echte repo is in sync ----------------------------------------------------------
    Write-Host "build-agent-defs.ps1 -Check + check-plugin-integrity.ps1 -- repo in sync" -ForegroundColor Cyan
    $rb = Invoke-Script -Path $Build -ScriptArgs @('-Check')
    Assert-Equal 0 $rb.Code 'build -Check: alle gedeelde blokken in sync op de repo'
    $ri = Invoke-Script -Path $Integrity -ScriptArgs @()
    Assert-Equal 0 $ri.Code 'lint-poort groen op de repo (incl. shared-check)'
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
