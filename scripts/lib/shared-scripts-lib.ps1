<#
.SYNOPSIS
    Registry + helpers voor de gedeelde workflow-scripts (root-kopie <-> plugin-spiegel).

.DESCRIPTION
    Dot-source dit bestand:

        . (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')

    Sommige workflow-scripts zijn repo-agnostisch en worden als gedeelde bron in de plugin gespiegeld,
    zodat consumenten ze niet dupliceren (issue #81). Het model: de **workshop-root-kopie is de
    canonieke, geteste bron**; de **plugin-spiegel** is wat een consument via een skill draait. Beide
    zijn LF-genormaliseerd identiek -- mogelijk doordat de scripts hun repo-root dual-context oplossen
    (CLAUDE_PROJECT_DIR bij een consument, anders de git-root).

    Levert Get-SharedScriptPairs (het register) en Get-NormalizedScriptContent (LF-genormaliseerd
    lezen). De generator (scripts/sync/build-shared-scripts.ps1), de lint-poort
    (check-plugin-integrity.ps1) en de test (scripts/tests/shared-scripts.tests.ps1) delen deze ene bron.

    Geen Set-StrictMode hier: dot-sourcen zou de strict-mode van het aanroepende script veranderen.
    Puur ASCII (repo-conventie voor .ps1).
#>

function Get-SharedScriptPairs {
    <#
        Het register van gedeelde scripts. Elk paar: de canonieke root-bron (Source) en de
        plugin-spiegel (Mirror), beide repo-root-relatief. Uitgebreid per gecentraliseerd script.
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
    <# Leest een script LF-genormaliseerd (CRLF -> LF); $null als het bestand ontbreekt. #>
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    return ($raw -replace "`r`n", "`n")
}
