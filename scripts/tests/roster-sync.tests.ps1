<#
.SYNOPSIS
    Regression tests for the roster-sync check (scripts/sync/check-roster-sync.ps1).

.DESCRIPTION
    Dependency-free: no Pester, plain PowerShell. Integration-style -- runs the real script in a CHILD
    PROCESS against throwaway fixtures in the temp dir and asserts on exit-code + output. The agent set
    is made deterministic with a fixture plugin cache passed via -CacheRootOverride, and the consumer
    repo-root via -ConsumerPathOverride.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/roster-sync.tests.ps1

    Pure ASCII (repo convention for .ps1).

    Test-gaps (honest):
      - The dual-context repo-root fallback (git rev-parse when neither -ConsumerPathOverride nor
        CLAUDE_PROJECT_DIR is set) is not exercised here -- the tests always pin the root explicitly.
        The CLAUDE_PROJECT_DIR branch itself is covered structurally by shared-scripts.tests.ps1's
        dual-context invariant.
      - The $env:CLAUDE_PLUGIN_ROOT hook-context branch of Resolve-PluginDir is not covered; in
        practice this script is not a hook, so that env var is normally unset. The cache-resolution
        branch (incl. semantically-highest-version) IS covered.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\sync\check-roster-sync.ps1'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) 'roster-sync-test-fixture'

$Marketplace = 'davekjohns-workshop'
$PluginName  = 'specialists'
$PluginId    = "$PluginName@$Marketplace"

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

function Assert-Match {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern not found: '$Pattern'" -ForegroundColor Red
    }
}

function Assert-NotMatch {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -notmatch $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern present but should not be: '$Pattern'" -ForegroundColor Red
    }
}

function Invoke-Ps {
    param([string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

# Builds a fixture plugin cache. -VersionAgents: @{ '1.11.0' = @('06-16','06-24') }.
# -VersionPersonas: @{ '1.11.0' = @('01-01') }. Returns the cache root.
function New-FixtureCache {
    param([hashtable]$VersionAgents, [hashtable]$VersionPersonas = @{})
    $cache = Join-Path $Fixture 'cache'
    if (Test-Path -LiteralPath $cache) { Remove-Item -Recurse -Force -LiteralPath $cache }
    foreach ($ver in $VersionAgents.Keys) {
        $adir = Join-Path $cache "$Marketplace\$PluginName\$ver\agents"
        New-Item -ItemType Directory -Path $adir -Force | Out-Null
        foreach ($id in $VersionAgents[$ver]) {
            $g = $id.Split('-')[0]; $i = $id.Split('-')[1]
            [System.IO.File]::WriteAllText((Join-Path $adir "$id-agent.md"), "---`nname: x`nid: $i`ngroup: $g`n---`nfixture")
        }
    }
    foreach ($ver in $VersionPersonas.Keys) {
        $pdir = Join-Path $cache "$Marketplace\$PluginName\$ver\personas"
        New-Item -ItemType Directory -Path $pdir -Force | Out-Null
        foreach ($id in $VersionPersonas[$ver]) {
            $g = $id.Split('-')[0]; $i = $id.Split('-')[1]
            [System.IO.File]::WriteAllText((Join-Path $pdir "$id-persona.md"), "---`nid: $i`ngroup: $g`n---`nfixture")
        }
    }
    return $cache
}

# Builds a fixture consumer repo-root. RosterIds -> written into the roster file; LensIds -> lens files
# on the plugin-path; LegacyLensIds -> lens files on the legacy path.
function New-FixtureConsumer {
    param(
        [string[]]$RosterIds = @(),
        [string[]]$LensIds = @(),
        [string[]]$LegacyLensIds = @(),
        [bool]$Enabled = $true,
        [bool]$WriteSettings = $true,
        [string]$RosterFile = 'CLAUDE.md',
        [string]$RepoConfig = ''
    )
    $root = Join-Path $Fixture 'consumer'
    if (Test-Path -LiteralPath $root) { Remove-Item -Recurse -Force -LiteralPath $root }
    New-Item -ItemType Directory -Path (Join-Path $root '.claude') -Force | Out-Null

    if ($WriteSettings) {
        $val = if ($Enabled) { 'true' } else { 'false' }
        $settings = '{ "enabledPlugins": { "' + $PluginId + '": ' + $val + ' } }'
        [System.IO.File]::WriteAllText((Join-Path $root '.claude\settings.json'), $settings)
    }

    $lines = @('# Roster', '')
    foreach ($id in $RosterIds) { $lines += "| $id | [$id-extension.md](x) |" }
    [System.IO.File]::WriteAllText((Join-Path $root $RosterFile), ($lines -join "`n"))

    if ($LensIds.Count -gt 0) {
        $pdir = Join-Path $root ".claude\plugins\claude-specialists\$PluginName"
        New-Item -ItemType Directory -Path $pdir -Force | Out-Null
        foreach ($id in $LensIds) { [System.IO.File]::WriteAllText((Join-Path $pdir "$id-extension.md"), "lens") }
    }
    if ($LegacyLensIds.Count -gt 0) {
        $ldir = Join-Path $root '.claude\extensions'
        New-Item -ItemType Directory -Path $ldir -Force | Out-Null
        foreach ($id in $LegacyLensIds) { [System.IO.File]::WriteAllText((Join-Path $ldir "$id-extension.md"), "lens") }
    }
    if ($RepoConfig) {
        New-Item -ItemType Directory -Path (Join-Path $root 'scripts') -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $root 'scripts\repo-config.ps1'), $RepoConfig)
    }
    return $root
}

try {
    Write-Host "== roster-sync.tests ==" -ForegroundColor Cyan

    # --- 1. Happy path: agents present in roster + lens -> exit 0 --------------------------------
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16', '06-17') }
    $c = New-FixtureConsumer -RosterIds @('06-16', '06-17') -LensIds @('06-16', '06-17')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'happy path: exit-code 0'
    Assert-Match "\[OK\]\s+agent '06-16' present in roster \+ lens" $r.Out 'happy path: 06-16 OK'
    Assert-NotMatch '\[ERROR\]' $r.Out 'happy path: no errors'

    # --- 2. New agent missing from the roster -> [ERROR] + exit 1 naming the id ------------------
    #     06-24 is an agent, but the roster only lists 06-16. Lens for 06-24 IS present, so the only
    #     finding is the missing roster row.
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16', '06-24') }
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @('06-16', '06-24')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 1 $r.Code 'new agent: exit-code 1'
    Assert-Match "\[ERROR\].*'06-24'.*no roster row" $r.Out 'new agent: ERROR names the id + reason'

    # --- 3. Agent missing a lens -> reported (ERROR) ---------------------------------------------
    #     06-16 is in the roster but has no lens anywhere.
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @()
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 1 $r.Code 'missing lens: exit-code 1'
    Assert-Match "\[ERROR\].*'06-16'.*no repo-lens" $r.Out 'missing lens: reported'

    # --- 4. Orphan roster/lens id -> [INFO], exit 0 ----------------------------------------------
    #     06-16 fully satisfied; 09-99 is a roster token + lens file with no backing agent/persona.
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $c = New-FixtureConsumer -RosterIds @('06-16', '09-99') -LensIds @('06-16', '09-99')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'orphan: exit-code 0 (INFO, not blocking)'
    Assert-Match "\[INFO\].*orphan '09-99'" $r.Out 'orphan: INFO names the id'
    Assert-Match '1 info signal' $r.Out 'orphan: counted as info signal'

    # --- 5. Plugin not enabled -> handled, exit 0 ------------------------------------------------
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $c = New-FixtureConsumer -RosterIds @() -Enabled $false
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'plugin disabled: exit-code 0'
    Assert-Match 'no enabled plugins' $r.Out 'plugin disabled: reported'
    Assert-NotMatch '\[ERROR\]' $r.Out 'plugin disabled: no errors'

    # --- 5b. Enabled but not in cache -> INFO, exit 0 (install may be on another machine) --------
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $emptyCache = Join-Path $Fixture 'empty-cache'
    New-Item -ItemType Directory -Path $emptyCache -Force | Out-Null
    $c = New-FixtureConsumer -RosterIds @() -Enabled $true
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $emptyCache)
    Assert-Equal 0 $r.Code 'not in cache: exit-code 0'
    Assert-Match 'not found in the cache' $r.Out 'not in cache: INFO'

    # --- 6. Highest-version cache resolution -----------------------------------------------------
    #     1.9.0 ships only 06-16; 1.10.0 adds 06-24. A string-sort would wrongly pick 1.9.0 (misses
    #     06-24). With [version]-sort the script picks 1.10.0, so 06-24 (absent from roster/lens) is
    #     flagged -> exit 1. That exit 1 + the 06-24 ERROR proves 1.10.0 was chosen.
    $cache = New-FixtureCache -VersionAgents @{ '1.9.0' = @('06-16'); '1.10.0' = @('06-16', '06-24') }
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @('06-16')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 1 $r.Code 'highest version: exit-code 1 (1.10.0 chosen, 06-24 seen)'
    Assert-Match "\[ERROR\].*'06-24'" $r.Out 'highest version: 06-24 (only in 1.10.0) flagged'
    Assert-Match 'cache 1\.10\.0' $r.Out 'highest version: header shows 1.10.0'

    # --- 7. Persona backing: a persona-only id is NOT drift and NOT an orphan --------------------
    #     01-01 ships as a persona (no agent). It has a roster row + lens. It must produce no ERROR
    #     (personas are not agents) and no orphan INFO (personas count as backing).
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') } -VersionPersonas @{ '1.11.0' = @('01-01') }
    $c = New-FixtureConsumer -RosterIds @('06-16', '01-01') -LensIds @('06-16', '01-01')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'persona backing: exit-code 0'
    Assert-NotMatch "orphan '01-01'" $r.Out 'persona backing: 01-01 not an orphan'
    Assert-NotMatch "'01-01'.*no roster row" $r.Out 'persona backing: 01-01 not flagged as missing agent'

    # --- 8. Get-RosterPath override: roster lives in ROSTER.md -----------------------------------
    #     repo-config returns 'ROSTER.md'; the roster is written there, CLAUDE.md is empty. If the
    #     default were used, 06-16 would be "missing from roster" (exit 1). Exit 0 proves ROSTER.md
    #     was read via Get-RosterPath.
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $repoConfig = "function Get-RosterPath { return 'ROSTER.md' }"
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @('06-16') -RosterFile 'ROSTER.md' -RepoConfig $repoConfig
    # Also drop an empty CLAUDE.md to prove the default path is NOT the one being consulted.
    [System.IO.File]::WriteAllText((Join-Path $c 'CLAUDE.md'), "# empty`n")
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'roster override: exit-code 0 (ROSTER.md consulted)'
    Assert-Match "\[OK\]\s+agent '06-16' present in roster" $r.Out 'roster override: 06-16 found in ROSTER.md'

    # --- 9. Legacy lens path (.claude/extensions) is honored -------------------------------------
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @() -LegacyLensIds @('06-16')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'legacy lens: exit-code 0 (lens found on legacy path)'
    Assert-NotMatch '\[ERROR\]' $r.Out 'legacy lens: no errors'

    # --- 10. Ignore-list: an enabled agent deliberately kept out of the roster/lenses is skipped ---
    #     04-11 is an agent with no roster row and no lens, but repo-config's Get-RosterIgnoredIds
    #     lists it -> no ERROR (exit 0), reported as a deliberate skip. Without the ignore-list this
    #     would be a double ERROR (missing roster + missing lens).
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16', '04-11') }
    $repoConfig = "function Get-RosterIgnoredIds { return @('04-11') }"
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @('06-16') -RepoConfig $repoConfig
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'ignore-list: exit-code 0 (ignored agent not flagged)'
    Assert-Match "\[INFO\].*'04-11'.*deliberately kept out" $r.Out 'ignore-list: 04-11 reported as skipped'
    Assert-NotMatch "'04-11'.*no roster row" $r.Out 'ignore-list: 04-11 not an ERROR'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
}

Write-Host "`nResult: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
