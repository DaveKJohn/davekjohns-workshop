<#
.SYNOPSIS
    Regressietests voor scripts/repo-config.ps1 (de lokale repo-data-SSOT).

.DESCRIPTION
    Dependency-vrij: geen Pester nodig, alleen PowerShell. Bewaakt dat de repo-naam op een plek
    staat en dat de blob-URL daarvan wordt afgeleid (issue #81 -- de repo-naam stond eerder
    hardcoded in open-pr.ps1, fold-changelog-entry.ps1 en release-lib.ps1).

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/repo-config.tests.ps1

    Puur ASCII (repo-conventie voor .ps1).
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\repo-config.ps1')

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

function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name (patroon '$Pattern' niet gevonden)" -ForegroundColor Red
    }
}

Write-Host "repo-config" -ForegroundColor Cyan
$name = Get-RepoName
Assert-Match $name '^[\w.-]+/[\w.-]+$' 'Get-RepoName heeft de vorm owner/naam'

# De blob-URL wordt afgeleid van de repo-naam (enige bron) -- niet los gehardcodeerd.
$blob = Get-RepoBlobUrl
Assert-Equal "https://github.com/$name/blob/main/" $blob 'Get-RepoBlobUrl is afgeleid van Get-RepoName'

# De lint-poort die open-pr.ps1 draait (repo-specifiek, geinjecteerd i.p.v. hardcoded in open-pr).
$lint = Get-LintScript
Assert-Match $lint '\.ps1$' 'Get-LintScript wijst naar een .ps1'
Assert-Match $lint '^scripts[\\/]' 'Get-LintScript is repo-root-relatief onder scripts/'

# Roster-config voor check-roster-sync.ps1 (het roster-bestand + de bewust-genegeerde agent-ids).
$roster = Get-RosterPath
Assert-Match $roster '\.md$' 'Get-RosterPath wijst naar een .md'
$ignored = @(Get-RosterIgnoredIds)
foreach ($id in $ignored) { Assert-Match $id '^\d{2}-\d{2}$' "Get-RosterIgnoredIds: '$id' is een geldig <group>-<id>" }

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAALT: $($script:fail) fout, $($script:pass) goed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: alle $($script:pass) asserts geslaagd." -ForegroundColor Green
exit 0
