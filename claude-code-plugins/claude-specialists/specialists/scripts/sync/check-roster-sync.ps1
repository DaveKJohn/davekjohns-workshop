<#
.SYNOPSIS
    Roster-sync check: detects when a consumer's repo roster and repo lenses lag behind the agents
    that the ENABLED plugins actually ship (LAYER 1 -- detection only, no fixes).

.DESCRIPTION
    When a plugin release adds a new specialist (e.g. Ravi 06-24), a consumer that updates the plugin
    gets no signal that its roster (a table/list in CLAUDE.md) and its repo lenses now lag behind.
    This script surfaces that drift by comparing three sources:

      (a) Agents of the ENABLED plugins. Enabled plugins are read from .claude/settings.json
          (enabledPlugins: a plugin id like 'specialists@davekjohns-workshop' counts as enabled when
          its value is $true -- mirrors bootstrap.ps1). For each enabled plugin the versioned dir is
          resolved in the local plugin cache (semantically highest version, [version]-sort -- the same
          approach bootstrap.ps1 uses so 1.10.0 beats 1.9.0), and the agent ids ('<group>-<id>', e.g.
          06-24) are taken from <plugin-dir>/agents/<g>-<id>-agent.md.
      (b) The consumer's roster. Its path comes from Get-RosterPath in scripts/repo-config.ps1
          (default 'CLAUDE.md', repo-root-relative). "Present in the roster" is decided by scanning the
          roster text for each '<group>-<id>' token (format-agnostic -- works for a table OR a list;
          deliberately NOT a brittle table parser).
      (c) The lens files: .claude/plugins/claude-specialists/<plugin>/<g>-<id>-extension.md and the
          legacy .claude/extensions/<g>-<id>-extension.md.

    Findings + severity (same [OK]/[INFO]/[ERROR] convention as check-connectors.ps1):
      - agent WITHOUT a roster row  -> [ERROR]  (the core case this feature exists for: a new
                                                 specialist that is invisible in the governance doc).
      - agent WITHOUT a lens file   -> [ERROR]  (actionable drift for a real agent: no landing spot
                                                 for its repo-specific context).
      - orphan (a roster token OR a lens file whose '<group>-<id>' has NO matching agent AND no
        matching persona in any enabled plugin) -> [INFO] (could be a just-removed specialist; also
        soft because personas are counted as backing, see below).

    Personas as orphan-backing: main-loop specialists (Chris 01-01, Derek 05-05, Rendall 05-06, ...)
    ship as <plugin>/personas/<g>-<id>-persona.md, NOT as agents, yet legitimately have a roster row
    and a lens. Counting personas as "backing" keeps them from being flagged as orphans on every real
    repo. Personas are NEVER treated as missing-roster/missing-lens drift -- only agents are (source a).

    Exit-code: 0 = no errors (INFO does not count), 1 = at least one error.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Use this path as the consumer repo root instead of the dual-context default.

.PARAMETER CacheRootOverride
    (Optional, for tests) Use this dir as the plugin cache root instead of
    $env:USERPROFILE/.claude/plugins/cache -- lets a fixture supply a controlled agent set / versions.

.EXAMPLE
    .\scripts\sync\check-roster-sync.ps1
#>
param(
    [string]$ConsumerPathOverride = '',
    [string]$CacheRootOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Repo-root -- dual-context: a consumer running the shared plugin mirror gets its repo-root from
# CLAUDE_PROJECT_DIR; in the workshop-root (or outside a session) it falls back to the git-root. This
# keeps the root-copy and the plugin-mirror byte-identical (guarded by the shared-scripts drift-lint).
# -ConsumerPathOverride wins so a fixture can point the check at a throwaway consumer.
$repoRoot = if ($ConsumerPathOverride) { $ConsumerPathOverride }
            elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR }
            else { (git rev-parse --show-toplevel).Trim() }
$repoRoot = (Resolve-Path -LiteralPath $repoRoot).Path

# Plugin cache root (overridable for tests).
$cacheRoot = if ($CacheRootOverride) { $CacheRootOverride } else { Join-Path $env:USERPROFILE '.claude\plugins\cache' }

$script:errors = 0
$script:infos  = 0

# Write-Ok/Write-Info/Write-Failure + Test-PluginNameSlug/Test-PluginMarketplaceSlug + Resolve-PluginDir:
# shared with check-connectors.ps1 and skills/sync-roster/sync-roster.ps1 (single source, issue
# #114). This script is a whole-file mirror (scripts/lib/shared-scripts-lib.ps1); check-report-lib.ps1
# is registered in that same pair set and therefore travels along, so a $PSScriptRoot-relative
# dot-source (not $repoRoot -- this lib is not repo-owned, unlike repo-config.ps1/branch-info.ps1)
# resolves correctly whether this file runs from the workshop root or the plugin mirror.
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')

# Agent ids ('<group>-<id>') a plugin ships (source a).
function Get-AgentIds {
    param([string]$PluginDir)
    $dir = Join-Path $PluginDir 'agents'
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $dir -Filter '*-agent.md' -File |
        ForEach-Object { if ($_.BaseName -match '^(\d{2})-(\d{2})-agent$') { "$($Matches[1])-$($Matches[2])" } } |
        Sort-Object -Unique)
}

# Ids that BACK a roster token / lens: agents + personas. Personas run in the main loop (not as
# subagents) but are real specialists with roster rows + lenses, so counting them prevents false orphans.
function Get-BackingIds {
    param([string]$PluginDir)
    $ids = @(Get-AgentIds -PluginDir $PluginDir)
    $pdir = Join-Path $PluginDir 'personas'
    if (Test-Path -LiteralPath $pdir -PathType Container) {
        $ids += @(Get-ChildItem -LiteralPath $pdir -Filter '*-persona.md' -File |
            ForEach-Object { if ($_.BaseName -match '^(\d{2})-(\d{2})-persona$') { "$($Matches[1])-$($Matches[2])" } })
    }
    return @($ids | Sort-Object -Unique)
}

# "Present in the roster": scan the roster text for the literal '<group>-<id>' token, bounded by
# non-digits so '06-24' still matches inside '06-24-extension.md' but NOT inside '106-240'.
# Format-agnostic on purpose (table or list) -- see the Get-RosterPath note in repo-config.ps1.
function Test-InRoster {
    param([string]$RosterText, [string]$Id)
    return ($RosterText -match ('(?<!\d)' + [regex]::Escape($Id) + '(?!\d)'))
}

# A lens for '<group>-<id>' exists at the plugin-path (the standard) or the legacy extensions-path.
function Test-LensExists {
    param([string]$RepoRoot, [string]$PluginName, [string]$Id)
    $candidates = @(
        (Join-Path $RepoRoot (".claude\plugins\claude-specialists\$PluginName\$Id-extension.md")),
        (Join-Path $RepoRoot (".claude\extensions\$Id-extension.md"))
    )
    foreach ($c in $candidates) { if (Test-Path -LiteralPath $c -PathType Leaf) { return $true } }
    return $false
}

# All lens ids present in the consumer (plugin-path for each enabled plugin + the legacy path), mapped
# to a display path -- used to surface lens files that back no agent (orphans).
function Get-LensIds {
    param([string]$RepoRoot, [string[]]$PluginNames)
    $dirs = @()
    foreach ($pn in $PluginNames) { $dirs += (Join-Path $RepoRoot ".claude\plugins\claude-specialists\$pn") }
    $dirs += (Join-Path $RepoRoot '.claude\extensions')
    $result = @{}
    foreach ($d in $dirs) {
        if (-not (Test-Path -LiteralPath $d -PathType Container)) { continue }
        Get-ChildItem -LiteralPath $d -Filter '*-extension.md' -File | ForEach-Object {
            if ($_.BaseName -match '^(\d{2})-(\d{2})-extension$') {
                $id = "$($Matches[1])-$($Matches[2])"
                if (-not $result.ContainsKey($id)) { $result[$id] = $_.FullName }
            }
        }
    }
    return $result
}

Write-Host "== check-roster-sync -- $repoRoot ==" -ForegroundColor Cyan

# Roster path from repo-config's Get-RosterPath (default 'CLAUDE.md'). repo-config is repo-specific and
# lives in the consumer repo-root; if it is absent we fall back to the default (this check has a sane
# default and does not hard-require repo-config, unlike open-pr/fold).
$rosterRel = 'CLAUDE.md'
$ignoredIds = @()
$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    . $configPath
    if (Get-Command Get-RosterPath -ErrorAction SilentlyContinue) { $rosterRel = Get-RosterPath }
    # Ids that are enabled but deliberately kept out of the roster/lenses (a documented repo choice);
    # they are skipped rather than flagged as drift. Empty on a fresh consumer.
    if (Get-Command Get-RosterIgnoredIds -ErrorAction SilentlyContinue) { $ignoredIds = @(Get-RosterIgnoredIds) }
}
$rosterPath = Join-Path $repoRoot $rosterRel
if (Test-Path -LiteralPath $rosterPath -PathType Leaf) {
    $rosterText = [System.IO.File]::ReadAllText($rosterPath, [System.Text.Encoding]::UTF8)
} else {
    $rosterText = ''
    Write-Info "roster file '$rosterRel' not found in the repo-root -- treated as empty."
}

# Enabled plugins from .claude/settings.json (mirrors bootstrap.ps1).
$settingsPath = Join-Path $repoRoot '.claude\settings.json'
$enabledIds = @()
if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
    $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($settings.PSObject.Properties.Name -contains 'enabledPlugins') {
        $enabledIds = @($settings.enabledPlugins.PSObject.Properties |
            Where-Object { $_.Value -eq $true } | ForEach-Object { $_.Name })
    }
} else {
    Write-Info "no .claude/settings.json in the repo-root -- nothing enabled to check."
}

if ($enabledIds.Count -eq 0 -and (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
    Write-Info "no enabled plugins in .claude/settings.json -- nothing to check."
}

$allBackingIds = @{}
$pluginNames = @()

foreach ($plugId in ($enabledIds | Sort-Object -Unique)) {
    $parts = $plugId.Split('@')
    $name = $parts[0]
    $marketplace = if ($parts.Count -gt 1) { $parts[1] } else { '' }

    # Guardrail: plugin-name/marketplace come from settings and become path segments -- validate as
    # slugs before touching the filesystem (mirrors check-connectors' Get-PluginDir).
    if (-not (Test-PluginNameSlug -Name $name)) {
        Write-Failure "invalid plugin id '$plugId' in .claude/settings.json -- skipped."
        continue
    }
    if (-not $marketplace) {
        Write-Info "plugin '$plugId' has no '@marketplace' suffix -- cannot resolve its cache dir, skipped."
        continue
    }
    if (-not (Test-PluginMarketplaceSlug -Marketplace $marketplace)) {
        Write-Failure "invalid marketplace in plugin id '$plugId' -- skipped."
        continue
    }

    $pluginDir = Resolve-PluginDir -Name $name -Marketplace $marketplace -CacheRoot $cacheRoot
    if ($null -eq $pluginDir) {
        Write-Info "plugin '$plugId' is enabled but not found in the cache ($cacheRoot) -- skipped (the install may run on another machine)."
        continue
    }

    $pluginNames += $name
    foreach ($bid in (Get-BackingIds -PluginDir $pluginDir)) { $allBackingIds[$bid] = $true }
    $agentIds = @(Get-AgentIds -PluginDir $pluginDir)

    Write-Host "`n-- plugin: $plugId (cache $(Split-Path $pluginDir -Leaf))" -ForegroundColor Cyan
    if ($agentIds.Count -eq 0) { Write-Info "no agents found for '$plugId'."; continue }

    foreach ($id in $agentIds) {
        if ($ignoredIds -contains $id) {
            Write-Info "agent '$id' ($plugId) deliberately kept out of the roster/lenses (repo-config ignore-list) -- skipped."
            continue
        }
        $inRoster = Test-InRoster -RosterText $rosterText -Id $id
        $hasLens  = Test-LensExists -RepoRoot $repoRoot -PluginName $name -Id $id
        if (-not $inRoster) {
            Write-Failure "agent '$id' ($plugId) has no roster row in $rosterRel -- add it to the roster."
        }
        if (-not $hasLens) {
            Write-Failure "agent '$id' ($plugId) has no repo-lens (.claude/plugins/claude-specialists/$name/$id-extension.md or the legacy .claude/extensions/ path)."
        }
        if ($inRoster -and $hasLens) { Write-Ok "agent '$id' present in roster + lens" }
    }
}

# Orphans (INFO): roster tokens / lens files whose id has no backing agent or persona among the
# resolved enabled plugins. Only run when at least one plugin resolved -- otherwise we have no basis to
# call anything an orphan (e.g. the only enabled plugin is not on this machine).
if ($pluginNames.Count -gt 0) {
    Write-Host "`n-- orphans" -ForegroundColor Cyan
    $lensIds = Get-LensIds -RepoRoot $repoRoot -PluginNames ($pluginNames | Sort-Object -Unique)
    $rosterTokenIds = @([regex]::Matches($rosterText, '(?<!\d)\d{2}-\d{2}(?!\d)') |
        ForEach-Object { $_.Value } | Sort-Object -Unique)

    $orphanFound = $false
    foreach ($id in (@($lensIds.Keys) + $rosterTokenIds | Sort-Object -Unique)) {
        if ($allBackingIds.ContainsKey($id)) { continue }
        $where = @()
        if ($lensIds.ContainsKey($id)) { $where += 'lens' }
        if ($rosterTokenIds -contains $id) { $where += 'roster' }
        Write-Info "orphan '$id' ($($where -join ' + ')) -- no matching agent/persona in any enabled plugin."
        $orphanFound = $true
    }
    if (-not $orphanFound) { Write-Ok "no orphan roster tokens / lens files" }
}

Write-CheckSummary
