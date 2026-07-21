<#
.SYNOPSIS
    Regression tests for the shared agent-def blocks: the lib (agent-shared-lib.ps1), the generator
    (build-agent-defs.ps1) and the drift gate in check-plugin-integrity.ps1.

.DESCRIPTION
    Dependency-free: no Pester, only PowerShell. The unit tests dot-source the lib and run
    Expand-AgentDefShared against in-memory fixtures; the smoke tests run the real scripts as a
    CHILD PROCESS (powershell -File) because they call 'exit' themselves.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/agent-shared.tests.ps1

    Pure ASCII (repo convention for .ps1).
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
    else { $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
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
    # --- Fixture source: a shared block 'greeting' ---------------------------------------------------
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null
    $blockText = "- hello world`n- second line"
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'greeting.md'), "$blockText`n", (New-Object System.Text.UTF8Encoding($false)))

    $begin = '<!-- BEGIN shared:greeting -- GENERATED, edit agent-shared/greeting.md -->'
    $end   = '<!-- END shared:greeting -->'
    $inSync = "before`n$begin`n$blockText`n$end`nafter"

    # --- 1. In-sync content stays the same; no problems ---------------------------------------------
    Write-Host "Expand-AgentDefShared -- in sync" -ForegroundColor Cyan
    $p1 = New-Problems
    $o1 = Expand-AgentDefShared -Content $inSync -SharedDir $Fixture -Problems $p1
    Assert-Equal $inSync $o1 'in-sync content stays byte-equal'
    Assert-Equal 0 $p1.Count 'no problems on in-sync content'

    # --- 2. Drift is detected and restored from the source ----------------------------------------
    Write-Host "Expand-AgentDefShared -- drift" -ForegroundColor Cyan
    $stale = "before`n$begin`n- MANUALLY CHANGED`n$end`nafter"
    $p2 = New-Problems
    $o2 = Expand-AgentDefShared -Content $stale -SharedDir $Fixture -Problems $p2
    Assert-True ($o2 -ne $stale) 'drift detected (expand deviates from the input)'
    Assert-Equal $inSync $o2 'expand restores the region from the canonical source'

    # --- 3. BEGIN without END is reported ------------------------------------------------------------
    Write-Host "Expand-AgentDefShared -- BEGIN without END" -ForegroundColor Cyan
    $noEnd = "before`n$begin`n- something"
    $p3 = New-Problems
    $null = Expand-AgentDefShared -Content $noEnd -SharedDir $Fixture -Problems $p3
    Assert-True ($p3.Count -ge 1) 'BEGIN without END is reported as a problem'

    # --- 4. Unknown block (missing source) is reported ----------------------------------------------
    Write-Host "Expand-AgentDefShared -- unknown block" -ForegroundColor Cyan
    $unknown = "before`n<!-- BEGIN shared:doesnotexist -->`n- x`n<!-- END shared:doesnotexist -->`nafter"
    $p4 = New-Problems
    $null = Expand-AgentDefShared -Content $unknown -SharedDir $Fixture -Problems $p4
    Assert-True ($p4.Count -ge 1) 'unknown block (missing source) is reported'

    # --- 5. Multiple blocks in ONE agent-def all get filled -------------------------------------
    Write-Host "Expand-AgentDefShared -- multiple blocks" -ForegroundColor Cyan
    [System.IO.File]::WriteAllText((Join-Path $Fixture 'second.md'), "- block two`n", (New-Object System.Text.UTF8Encoding($false)))
    $b2 = '<!-- BEGIN shared:second -->'; $e2 = '<!-- END shared:second -->'
    $multiStale = "top`n$begin`n- old`n$end`nmiddle`n$b2`n- old2`n$e2`nbottom"
    $p5 = New-Problems
    $o5 = Expand-AgentDefShared -Content $multiStale -SharedDir $Fixture -Problems $p5
    Assert-True ($o5 -match 'hello world' -and $o5 -match 'block two') 'both blocks filled from their source'
    Assert-True (-not ($o5 -match 'old2')) 'stale content of the second block replaced'

    # --- 6. Smoke: the real repo is in sync ----------------------------------------------------------
    Write-Host "build-agent-defs.ps1 -Check + check-plugin-integrity.ps1 -- repo in sync" -ForegroundColor Cyan
    $rb = Invoke-Script -Path $Build -ScriptArgs @('-Check')
    Assert-Equal 0 $rb.Code 'build -Check: all shared blocks in sync on the repo'
    $ri = Invoke-Script -Path $Integrity -ScriptArgs @()
    Assert-Equal 0 $ri.Code 'lint gate green on the repo (incl. shared check)'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
