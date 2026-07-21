<#
.SYNOPSIS
    Regression tests for the shared-workflow-scripts mechanics (issue #81): shared-scripts-lib.ps1,
    the generator/drift check, and the repo invariant that every plugin mirror is in sync with its source.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Exit code 0 if everything passes, 1 on a failure.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/shared-scripts.tests.ps1

    Pure ASCII (repo convention for .ps1).
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
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red
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
Assert-True ($pairs.Count -ge 1) 'at least one shared script registered'
$fold = $pairs | Where-Object { $_.Name -eq 'fold-changelog-entry' }
Assert-True ($null -ne $fold) 'fold-changelog-entry is in the register'
Assert-True ($fold.SourceRel -like 'scripts\*') 'source is repo-root-relative under scripts\'
Assert-True ($fold.MirrorRel -like 'claude-code-plugins\*') 'mirror lives under the plugin'
# Explicit -- the generic loops further down already cover these two implicitly, but a missing
# pair in the register would then slip through silently instead of giving a targeted failure.
$newChangelogPair = $pairs | Where-Object { $_.Name -eq 'new-changelog-entry' }
Assert-True ($null -ne $newChangelogPair) 'new-changelog-entry is in the register'
$newBranchPair = $pairs | Where-Object { $_.Name -eq 'new-branch' }
Assert-True ($null -ne $newBranchPair) 'new-branch is in the register'

Write-Host "Repo invariant: every mirror in sync with its source" -ForegroundColor Cyan
foreach ($pair in $pairs) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    $mirror = Get-NormalizedScriptContent -Path $pair.MirrorPath
    Assert-True ($null -ne $src) "source exists: $($pair.SourceRel)"
    Assert-True ($null -ne $mirror) "mirror exists: $($pair.MirrorRel)"
    Assert-Equal $src $mirror "in sync: $($pair.Name)"
}

Write-Host "Dual-context resolution guarded in every source" -ForegroundColor Cyan
# The whole mirror mechanism relies on a shared script resolving its repo root dual-context.
# If CLAUDE_PROJECT_DIR disappears from a source, the consumer call breaks silently -- this catches that.
foreach ($pair in $pairs) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    Assert-True ($src -match 'CLAUDE_PROJECT_DIR') "$($pair.Name): source resolves the repo root via CLAUDE_PROJECT_DIR"
}

Write-Host "Get-NormalizedScriptContent" -ForegroundColor Cyan
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-test-$PID.ps1")
[System.IO.File]::WriteAllText($tmp, "line1`r`nline2`r`n", (New-Object System.Text.UTF8Encoding $false))
try {
    $norm = Get-NormalizedScriptContent -Path $tmp
    Assert-Equal "line1`nline2`n" $norm 'CRLF is LF-normalized'
} finally {
    Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
}
Assert-Equal $null (Get-NormalizedScriptContent -Path (Join-Path $RepoRoot 'does-not-exist-xyz.ps1')) 'missing file -> $null'

Write-Host "build-shared-scripts.ps1 -Check -- repo in sync" -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\sync\build-shared-scripts.ps1') -Check | Out-Null
Assert-Equal 0 $LASTEXITCODE 'generator -Check green on the repo'

Write-Host "Pre-flight (#86): missing repo-config stops with a clear pointer" -ForegroundColor Cyan
# Run every source against an EMPTY repo root (via CLAUDE_PROJECT_DIR) -- without repo-config/branch-info
# the pre-flight should stop with a pointer instead of a raw dot-source error. Child process, because
# the scripts call 'exit' themselves.
$pfDir = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-preflight-$PID")
New-Item -ItemType Directory -Path $pfDir -Force | Out-Null
$prevPd = $env:CLAUDE_PROJECT_DIR
$prevEap = $ErrorActionPreference
$vfDir = $null
try {
    $env:CLAUDE_PROJECT_DIR = $pfDir
    # Continue, not Stop: the child writes its pointer via Write-Error to stderr; with 2>&1,
    # Windows PowerShell 5.1 would treat that as a terminating NativeCommandError and abort this test.
    $ErrorActionPreference = 'Continue'
    # The CHILD PROCESS itself already renders Write-Error to plain stderr lines at its own
    # (non-interactive) console width, BEFORE that text is ever captured here -- a word like
    # 'branch-info.ps1' can coincidentally split exactly at the hyphen wrap boundary
    # ('branch-'\n'info.ps1'), which would make a bare -match below fail flakily, purely depending
    # on the (arbitrary) temp-path length. Stripping newlines before the match restores the
    # original continuous text -- no functional change, only deterministic matching.
    function Test-OutputContains { param([string]$Text, [string]$Pattern) return (($Text -replace "`r?`n", '') -match $Pattern) }

    $foldSrc = ($pairs | Where-Object { $_.Name -eq 'fold-changelog-entry' }).SourcePath
    $foldOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $foldSrc 2>&1 | Out-String)
    $foldCode = $LASTEXITCODE
    Assert-Equal 1 $foldCode 'fold stops (exit 1) without repo-config'
    Assert-True (Test-OutputContains $foldOut 'repo-config') 'fold names repo-config in the pointer'
    $prSrc = ($pairs | Where-Object { $_.Name -eq 'open-pr' }).SourcePath
    $prOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $prSrc -Title 'fix: preflight-test' 2>&1 | Out-String)
    $prCode = $LASTEXITCODE
    Assert-Equal 1 $prCode 'open-pr stops (exit 1) without repo-config/branch-info'
    Assert-True (Test-OutputContains $prOut 'branch-info') 'open-pr names branch-info in the pointer'

    # new-changelog-entry and new-branch rely ONLY on branch-info.ps1 (no repo-config, no gh --
    # lighter than fold/open-pr), so no VUL-IN follow-up scenario for these two: their only pre-flight
    # check is the bare existence check on branch-info.ps1 below.
    $nceSrc = ($pairs | Where-Object { $_.Name -eq 'new-changelog-entry' }).SourcePath
    $nceOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $nceSrc -Title 'fix: preflight-test' 2>&1 | Out-String)
    $nceCode = $LASTEXITCODE
    Assert-Equal 1 $nceCode 'new-changelog-entry stops (exit 1) without branch-info'
    Assert-True (Test-OutputContains $nceOut 'branch-info') 'new-changelog-entry names branch-info in the pointer'
    $nbSrc = ($pairs | Where-Object { $_.Name -eq 'new-branch' }).SourcePath
    $nbOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $nbSrc -Name 'feat/preflight-test' 2>&1 | Out-String)
    $nbCode = $LASTEXITCODE
    Assert-Equal 1 $nbCode 'new-branch stops (exit 1) without branch-info'
    Assert-True (Test-OutputContains $nbOut 'branch-info') 'new-branch names branch-info in the pointer'

    # Second scenario: scaffolds PRESENT but not yet filled in (VUL-IN) -> also stops with a pointer.
    # Minimal scaffolds (repo-config with VUL-IN + an empty branch-info so open-pr's existence check
    # succeeds and the placeholder check is reached).
    $vfDir = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-vulin-$PID")
    New-Item -ItemType Directory -Path (Join-Path $vfDir 'scripts\lib') -Force | Out-Null
    $Utf8 = New-Object System.Text.UTF8Encoding $false
    $rcVulin = @'
$script:RepoName = 'VUL-IN/repo'
function Get-RepoName { return $script:RepoName }
function Get-RepoBlobUrl { return "https://github.com/$($script:RepoName)/blob/main/" }
$script:LintScript = 'VUL-IN'
function Get-LintScript { return $script:LintScript }
'@
    $biVulin = @'
$script:BranchTypeOrder = @()
$script:BranchPrefixTable = @{}
function Get-BranchTypes { return $script:BranchTypeOrder }
function Get-BranchPrefix { param([string]$Branch) if ($Branch -match '/') { return ($Branch -split '/')[0] } return ($Branch -split '-')[0] }
function Get-BranchInfo { param([string]$Branch) [pscustomobject]@{ Branch = $Branch; Prefix = (Get-BranchPrefix $Branch); IsKnown = $false; Label = $null; Type = $null; SafeName = ($Branch -replace '/', '-') } }
'@
    [System.IO.File]::WriteAllText((Join-Path $vfDir 'scripts\repo-config.ps1'), $rcVulin, $Utf8)
    [System.IO.File]::WriteAllText((Join-Path $vfDir 'scripts\lib\branch-info.ps1'), $biVulin, $Utf8)
    $env:CLAUDE_PROJECT_DIR = $vfDir
    $foldV = (& powershell -NoProfile -ExecutionPolicy Bypass -File $foldSrc 2>&1 | Out-String)
    $foldVCode = $LASTEXITCODE
    Assert-Equal 1 $foldVCode 'fold stops (exit 1) on an unfilled VUL-IN scaffold'
    Assert-True ($foldV -match 'VUL-IN') 'fold names VUL-IN in the pointer'
    $prV = (& powershell -NoProfile -ExecutionPolicy Bypass -File $prSrc -Title 'fix: vulin-test' 2>&1 | Out-String)
    $prVCode = $LASTEXITCODE
    Assert-Equal 1 $prVCode 'open-pr stops (exit 1) on an unfilled VUL-IN scaffold'
    Assert-True ($prV -match 'VUL-IN') 'open-pr names VUL-IN in the pointer'
} finally {
    $ErrorActionPreference = $prevEap
    if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
    else { $env:CLAUDE_PROJECT_DIR = $prevPd }
    Remove-Item -Path $pfDir -Recurse -Force -ErrorAction SilentlyContinue
    if ($vfDir) { Remove-Item -Path $vfDir -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host "git-push-stderr pitfall (open-pr.ps1)" -ForegroundColor Cyan
# The push in open-pr.ps1 used to die on git's 'remote:' stderr: under ErrorActionPreference=Stop,
# PS 5.1 promotes native stderr to a terminating NativeCommandError, before the exit-code check.
# (a) Mechanism proof: the bare pattern breaks, the capture pattern does not -- on a real native
# command (cmd.exe echoes to stderr and gives exit 0). NB: .ps1 is pure ASCII, so no diacritics.
$naiveThrew = $false
try {
    $prevE = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
    & cmd /c 'echo remote: something 1>&2 & exit 0' 2>&1 | Out-Null
    $ErrorActionPreference = $prevE
} catch { $naiveThrew = $true; $ErrorActionPreference = 'Stop' }
Assert-True $naiveThrew 'bare pattern (native stderr under EAP=Stop) is indeed terminating'

$fixThrew = $false; $fixCode = $null
try {
    $prevE = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
    $prevInner = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $out = & cmd /c 'echo remote: something 1>&2 & exit 0' 2>&1
    $fixCode = $LASTEXITCODE
    $ErrorActionPreference = $prevInner
    $out | Out-Null
    $ErrorActionPreference = $prevE
} catch { $fixThrew = $true }
Assert-True (-not $fixThrew) 'capture pattern (EAP=Continue around the call) is NOT terminating'
Assert-Equal 0 $fixCode 'capture pattern reads the real exit code (0) of the command'

# (b) Regression guard: open-pr.ps1's source must not fall back to the bare 'git push' + direct
# exit-code check under EAP=Stop; it should run the push with EAP=Continue and capture the output.
# (The live push against a real remote is deliberately NOT testable here -- an honest test gap.)
$openPrSrc = ($pairs | Where-Object { $_.Name -eq 'open-pr' }).SourcePath
$openPrText = [System.IO.File]::ReadAllText($openPrSrc)
Assert-True ($openPrText -match "git push -u origin \`$branch 2>&1") 'open-pr captures the push output (2>&1)'
Assert-True ($openPrText -match "ErrorActionPreference = 'Continue'") 'open-pr runs the push under EAP=Continue'
# open-pr's gh pr create must also fall under the guard (gh can write to stderr).
Assert-True ($openPrText -match "gh pr create.*2>&1") 'open-pr captures the gh-pr-create output (2>&1)'

# Sweep guard (after the v1.12.0 breakage): the other release scripts that mutate native git/gh must
# not carry the #107 pitfall -- the mutation/gh calls should run under EAP=Continue.
$cutSrc = Join-Path $RepoRoot 'scripts\release\cut-release.ps1'
$cutText = [System.IO.File]::ReadAllText($cutSrc)
Assert-True ($cutText -match "ErrorActionPreference = 'Continue'") 'cut-release runs the git mutation block under EAP=Continue'
Assert-True ($cutText -match "(?s)ErrorActionPreference = 'Continue'.*git add -A") 'cut-release: EAP=Continue comes before git add'

$foldSrc = ($pairs | Where-Object { $_.Name -eq 'fold-changelog-entry' }).SourcePath
$foldText = [System.IO.File]::ReadAllText($foldSrc)
Assert-True ($foldText -match "gh pr list.*2>\`$null") 'fold runs gh pr list with stderr discard'
# #103 (Victor #4): gh pr list supplies 'files' just as well as gh pr view -- the second gh
# roundtrip has been dropped. Regression guard: the --json list carries 'files' along, and a real
# 'gh pr view' call (as opposed to an explanatory code comment naming the old approach) has not
# returned.
Assert-True ($foldText -match "gh pr list.*--json number,url,files") 'fold already requests files in the gh pr list call'
Assert-True (-not ($foldText -match '(?m)^\s*\$\w+\s*=\s*gh pr view')) 'fold no longer runs a separate gh pr view call (merged, #103)'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
