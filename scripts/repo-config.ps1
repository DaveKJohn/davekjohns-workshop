<#
.SYNOPSIS
    Repo-eigen configuratie voor de workflow-scripts (single source of truth voor repo-data).

.DESCRIPTION
    Dot-source dit bestand vanuit een script:

        . (Join-Path $PSScriptRoot '..\repo-config.ps1')   # vanuit scripts/<map>/
        . (Join-Path $PSScriptRoot 'repo-config.ps1')       # vanuit scripts/ zelf

    Dit is het kleine, lokale blokje repo-data dat de (steeds generiekere) workflow-scripts inlezen.
    De scripts zelf zijn repo-agnostisch; alles wat per repo verschilt woont hier. Zo hoeft een
    wijziging aan de gedeelde flow niet in elke consument te worden nagelopen -- alleen dit bestand
    verschilt tussen life-hub, smartwatchbanden en de workshop.

    Levert Get-RepoName en Get-RepoBlobUrl. Vervangt de repo-naam die eerder hardcoded stond in
    open-pr.ps1, fold-changelog-entry.ps1 (2x) en cut-release.ps1 (via release-lib).

    Geen Set-StrictMode hier: dot-sourcen zou de strict-mode van het aanroepende script veranderen
    en daar losse code kunnen breken (zelfde reden als branch-info.ps1 / release-lib.ps1).

    Bewust puur ASCII (repo-conventie voor .ps1): Windows PowerShell 5.1 leest een BOM-loos script
    als ANSI en zou een accent-literal verhaspelen.
#>

# De GitHub-repo waar deze werkplaats woont (owner/naam). Enige plek waar dit staat.
$script:RepoName = 'DaveKJohn/davekjohns-workshop'

function Get-RepoName {
    <# owner/naam van deze repo, bv. voor `gh ... --repo`. #>
    return $script:RepoName
}

function Get-RepoBlobUrl {
    <# Basis-URL voor blob-links naar main, bv. om root-relatieve links absoluut te maken. #>
    return "https://github.com/$($script:RepoName)/blob/main/"
}

# De lint-poort van deze repo, repo-root-relatief. open-pr.ps1 draait dit voor de PR. Dit is het
# enige repo-specifieke deel van open-pr: elke consument heeft zijn eigen lint (de workshop
# check-plugin-integrity, een Brains-repo bv. lint-brain). De test-poort is puur conventie
# (scripts/tests/*.tests.ps1) en heeft geen config nodig.
$script:LintScript = 'scripts\lint\check-plugin-integrity.ps1'

function Get-LintScript {
    <# Repo-root-relatief pad naar de lint-poort die open-pr.ps1 voor de PR draait. #>
    return $script:LintScript
}

# The file that holds the roster (the specialists table/list). check-roster-sync.ps1 reads this to
# decide which agent ids are "present in the roster". Repo-root-relative; 'CLAUDE.md' by default.
# There is deliberately NO Get-RosterFormat: the check is format-agnostic (it scans the text for each
# <group>-<id> token), so it works whether the roster is a table or a list.
$script:RosterPath = 'CLAUDE.md'

function Get-RosterPath {
    <# Repo-root-relative path to the file that holds the roster (specialists table/list). #>
    return $script:RosterPath
}

# Agent ids ('<group>-<id>') that are ENABLED but deliberately have no roster row and no lens, so
# check-roster-sync.ps1 must not flag them as drift. In this workshop, Paula (02-09), Vera (04-11),
# Gwen (04-12) and Cody (04-13) are enabled from the `specialists` plugin but have (as yet) no
# repo work here, hence no lens and no roster row -- a documented choice in CLAUDE.md, not drift.
# A fresh consumer leaves this empty (every enabled agent belongs in its roster).
$script:RosterIgnoredIds = @('02-09', '04-11', '04-12', '04-13')

function Get-RosterIgnoredIds {
    <# Ids of enabled agents intentionally kept out of the roster/lenses (skipped by the check). #>
    return $script:RosterIgnoredIds
}
