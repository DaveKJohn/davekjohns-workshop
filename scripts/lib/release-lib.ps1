<#
.SYNOPSIS
    Pure release-helpers (versiebepaling + CHANGELOG-transformatie), los van git/filesystem-orkestratie.

.DESCRIPTION
    Dot-source dit bestand:

        . (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')

    Levert Get-NextVersion, Get-LockstepVersion en Convert-ChangelogForRelease. Deze functies zijn
    bewust puur (string/waarde in, string/waarde uit) zodat ze los te testen zijn zonder een release
    te draaien -- scripts/release/cut-release.ps1 gebruikt ze, en de tests dekken ze af.

    Geen Set-StrictMode hier: dot-sourcen zou de strict-mode van het aanroepende script veranderen.

    Let op: dit bestand is bewust puur ASCII (repo-conventie voor .ps1). Niet-ASCII output-tekens
    (middot, em-dash) worden via [char]0x.. gebouwd, niet als literal -- Windows PowerShell 5.1 leest
    een BOM-loos script als ANSI en zou een literal anders verhaspelen.
#>

function Get-NextVersion {
    <# Verhoogt een SemVer X.Y.Z volgens $BumpKind (major|minor|patch). #>
    param(
        [Parameter(Mandatory)][string]$Current,
        [Parameter(Mandatory)][ValidateSet('major', 'minor', 'patch')][string]$BumpKind
    )
    if ($Current -notmatch '^\d+\.\d+\.\d+$') { throw "Huidige versie '$Current' is geen geldige X.Y.Z." }
    $p = $Current -split '\.'
    [int]$maj = $p[0]; [int]$min = $p[1]; [int]$pat = $p[2]
    switch ($BumpKind) {
        'major' { $maj++; $min = 0; $pat = 0 }
        'minor' { $min++; $pat = 0 }
        'patch' { $pat++ }
    }
    return "$maj.$min.$pat"
}

function Get-LockstepVersion {
    <#
        Bepaalt de gedeelde (lockstep) versie uit een set plugin.json-inhouden. Input is een hashtable
        van naam/pad -> ruwe JSON-tekst. Gooit als een versie ontbreekt of als ze niet gelijk zijn.
    #>
    param([Parameter(Mandatory)][hashtable]$ManifestContents)
    if ($ManifestContents.Count -eq 0) { throw "Geen plugin-manifesten meegegeven." }
    $versions = @{}
    foreach ($key in $ManifestContents.Keys) {
        if ($ManifestContents[$key] -match '"version"\s*:\s*"(\d+\.\d+\.\d+)"') {
            $versions[$key] = $matches[1]
        } else {
            throw "Kon geen geldige 'version' (X.Y.Z) vinden in '$key'."
        }
    }
    $distinct = @($versions.Values | Sort-Object -Unique)
    if ($distinct.Count -ne 1) {
        $detail = ($versions.GetEnumerator() | ForEach-Object { "  $($_.Key): $($_.Value)" }) -join "`n"
        throw "Plugin-versies staan niet in lockstep (moeten gelijk zijn voor een repo-brede release):`n$detail"
    }
    return $distinct[0]
}

function Convert-ChangelogForRelease {
    <#
        Verplaatst de entries onder '## Pull Requests' naar een nieuw blok '### v<Version>' bovenaan
        '## Releases', en leegt de Pull-Requests-sectie tot zijn intro. Pure string-in/uit. Gooit als
        er niets te releasen valt of de secties ontbreken.
    #>
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date
    )

    # Niet-ASCII output-tekens via [char] (zie het bestandshoofd waarom).
    $midDot = [char]0x00B7   # middot-scheiding in de kop
    $emDash = [char]0x2014   # em-dash voor de PR-link achter een bullet

    $usesCRLF = $Content.Contains("`r`n")
    $nl = if ($usesCRLF) { "`r`n" } else { "`n" }
    $lines = $Content -split "`r?`n"

    $prIdx = -1; $relIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s+Pull Requests\s*$') { $prIdx = $i }
        elseif ($lines[$i] -match '^##\s+Releases\s*$') { $relIdx = $i }
    }
    if ($prIdx -lt 0) { throw "Kon '## Pull Requests' niet vinden in CHANGELOG.md." }
    if ($relIdx -lt 0) { throw "Kon '## Releases' niet vinden in CHANGELOG.md." }
    if ($relIdx -le $prIdx) { throw "'## Releases' staat niet na '## Pull Requests' -- onverwachte structuur." }

    # Kop van het bestand t/m de '## Pull Requests'-regel.
    $head = $lines[0..$prIdx]

    # Body van de Pull-Requests-sectie (tussen de twee kopjes).
    $prBody = @($lines[($prIdx + 1)..($relIdx - 1)])
    $prFirst = -1
    for ($i = 0; $i -lt $prBody.Count; $i++) { if ($prBody[$i] -match '^###\s') { $prFirst = $i; break } }
    if ($prFirst -lt 0) { throw "Geen changelog-entries onder '## Pull Requests' -- niets te releasen." }

    # Intro van de PR-sectie (blijft staan); entries (verhuizen).
    $prIntro = if ($prFirst -gt 0) { @($prBody[0..($prFirst - 1)]) } else { @() }
    $entryLines = @($prBody[$prFirst..($prBody.Count - 1)])

    # Entries -> bullets: elke '### '-kop wordt een bullet, met (indien aanwezig) zijn PR-link erachter.
    $bullets = @()
    $curHeading = $null; $curLink = $null
    foreach ($ln in $entryLines) {
        if ($ln -match '^###\s+(.*)$') {
            if ($null -ne $curHeading) {
                $bullets += $(if ($curLink) { "- $curHeading $emDash $curLink" } else { "- $curHeading" })
            }
            $curHeading = $matches[1].Trim()
            $curLink = $null
        } elseif ($ln -match '^\[PR #\d+\]\(.*\)\s*$') {
            $curLink = $ln.Trim()
        }
    }
    if ($null -ne $curHeading) {
        $bullets += $(if ($curLink) { "- $curHeading $emDash $curLink" } else { "- $curHeading" })
    }

    # Nieuw versieblok.
    $count = $bullets.Count
    $noun = if ($count -eq 1) { 'pull request' } else { 'pull requests' }
    $block = @("### v$Version $midDot $Date", "", "$count $noun in deze release:", "") + $bullets

    # Releases-sectie: kop + intro + bestaande releases.
    $relBody = @($lines[($relIdx + 1)..($lines.Count - 1)])
    $relFirst = -1
    for ($i = 0; $i -lt $relBody.Count; $i++) { if ($relBody[$i] -match '^###\s') { $relFirst = $i; break } }
    $relIntroLines = if ($relFirst -ge 0) { @($relBody[0..($relFirst - 1)]) } else { $relBody }
    $existingReleases = if ($relFirst -ge 0) { @($relBody[$relFirst..($relBody.Count - 1)]) } else { @() }

    # Vervang de "nog geen releases"-placeholder-intro op de eerste cut door een echte intro.
    $relIntroText = ($relIntroLines -join "`n")
    if ($relIntroText -match 'Nog geen releases') {
        $relIntro = @(
            "De vastgelegde versies van de marketplace $emDash nieuwste bovenaan. Elke release bumpt alle",
            'plugin-versies in lockstep, bundelt de sinds de vorige release gemergde pull requests en',
            'tagt de staat als `vX.Y.Z`.'
        )
    } else {
        # Behoud de bestaande intro, ontdaan van omringende lege regels.
        $relIntro = @($relIntroLines | Where-Object { $_ -ne '' })
    }

    # Assembleren met nette, enkele lege scheidingsregels.
    $out = @()
    $out += $head
    $out += ''
    $out += ($prIntro | Where-Object { $_ -ne '' })
    $out += ''
    $out += '## Releases'
    $out += ''
    $out += $relIntro
    $out += ''
    $out += $block
    if ($existingReleases.Count -gt 0) {
        $out += ''
        $out += '---'
        $out += ''
        $out += $existingReleases
    }

    return (($out -join $nl).TrimEnd() + $nl)
}
