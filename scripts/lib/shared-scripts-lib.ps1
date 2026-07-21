<#
.SYNOPSIS
    Registry + helpers for the shared workflow scripts (root copy <-> plugin mirror).

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')

    Some workflow scripts are repo-agnostic and are mirrored into the plugin as a shared source, so
    consumers do not duplicate them (issue #81). The model: the **workshop root copy is the
    canonical, tested source**; the **plugin mirror** is what a consumer runs via a skill. Both are
    LF-normalized identical -- made possible because the scripts resolve their repo root
    dual-context (CLAUDE_PROJECT_DIR for a consumer, otherwise the git root).

    Supplies Get-SharedScriptPairs (the registry) and Get-NormalizedScriptContent (LF-normalized
    read). The generator (scripts/sync/build-shared-scripts.ps1), the lint gate
    (check-plugin-integrity.ps1), and the test (scripts/tests/shared-scripts.tests.ps1) share this
    one source.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function Get-SharedScriptPairs {
    <#
        The registry of shared scripts. Each pair: the canonical root source (Source) and the
        plugin mirror (Mirror), both repo-root-relative. Extend per centralized script.
    #>
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $pairs = @(
        @{
            Name   = 'fold-changelog-entry'
            Source = 'scripts\release\fold-changelog-entry.ps1'
            Mirror = 'claude-code-plugins\claude-specialists\specialists\scripts\release\fold-changelog-entry.ps1'
        },
        @{
            Name   = 'open-pr'
            Source = 'scripts\release\open-pr.ps1'
            Mirror = 'claude-code-plugins\claude-specialists\specialists\scripts\release\open-pr.ps1'
        },
        @{
            Name   = 'check-roster-sync'
            Source = 'scripts\sync\check-roster-sync.ps1'
            Mirror = 'claude-code-plugins\claude-specialists\specialists\scripts\sync\check-roster-sync.ps1'
        },
        @{
            Name   = 'new-changelog-entry'
            Source = 'scripts\release\new-changelog-entry.ps1'
            Mirror = 'claude-code-plugins\claude-specialists\specialists\scripts\release\new-changelog-entry.ps1'
        },
        @{
            Name   = 'new-branch'
            Source = 'scripts\task\new-branch.ps1'
            Mirror = 'claude-code-plugins\claude-specialists\specialists\scripts\task\new-branch.ps1'
        },
        @{
            Name   = 'check-report-lib'
            Source = 'scripts\lib\check-report-lib.ps1'
            Mirror = 'claude-code-plugins\claude-specialists\specialists\scripts\lib\check-report-lib.ps1'
        }
    )

    foreach ($p in $pairs) {
        [pscustomobject]@{
            Name       = $p.Name
            SourceRel  = $p.Source
            MirrorRel  = $p.Mirror
            SourcePath = Join-Path $RepoRoot $p.Source
            MirrorPath = Join-Path $RepoRoot $p.Mirror
        }
    }
}

function Get-NormalizedScriptContent {
    <# Reads a script LF-normalized (CRLF -> LF); $null if the file is missing. #>
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    return ($raw -replace "`r`n", "`n")
}
