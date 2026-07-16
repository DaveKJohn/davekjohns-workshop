<#
.SYNOPSIS
    Pure release-helpers (versiebepaling + CHANGELOG-transformatie + release-notes-opbouw), los van
    git/filesystem-orkestratie.

.DESCRIPTION
    Dot-source dit bestand:

        . (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')

    Levert Get-NextVersion, Get-BumpType, Get-LockstepVersion, Get-PluginManifestPaths,
    Get-PullRequestEntries, Convert-ChangelogForRelease, Build-ReleaseNotes, en voor de
    per-plugin CHANGELOGs: Get-EntryPlugins, Convert-EntryLinksForPluginChangelog,
    Build-PluginChangelogSection en Add-PluginChangelogSection. Deze functies zijn bewust puur
    (string/waarde in, string/waarde uit) zodat ze los te testen zijn zonder een release te draaien --
    scripts/release/cut-release.ps1 gebruikt ze, en de tests dekken ze af.

    Model: de release-inhoud verhuist naar releases/development/<X.Y>/<X.Y.Z>.md; het ## Releases-blok
    in CHANGELOG.md wordt een korte VERWIJZING naar dat bestand (net als life-hub, maar zonder
    GitHub Releases). De ## Pull Requests-sectie wordt daarbij geleegd tot zijn intro.

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

function Get-BumpType {
    <# Bepaalt het bump-type (major/minor/patch) uit een oude en nieuwe SemVer. #>
    param(
        [Parameter(Mandatory)][string]$From,
        [Parameter(Mandatory)][string]$To
    )
    if ($From -notmatch '^\d+\.\d+\.\d+$' -or $To -notmatch '^\d+\.\d+\.\d+$') { throw "From/To moeten X.Y.Z zijn." }
    $f = $From -split '\.'; $t = $To -split '\.'
    if ([int]$t[0] -ne [int]$f[0]) { return 'major' }
    if ([int]$t[1] -ne [int]$f[1]) { return 'minor' }
    return 'patch'
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

function Get-PluginManifestPaths {
    <#
        Leidt de plugin-manifest-paden af uit plugins[].source in de marketplace-JSON -- de
        marketplace is de bron van waarheid over wat een plugin is. Puur (raakt de schijf niet):
        input is de ruwe JSON-tekst + de repo-root, output is een array van volledige manifest-paden.
        Gooit bij een ontbrekende plugins-lijst, een ontbrekend source-veld, en (containment,
        advies Sean) bij een source die via een absoluut of ..-pad buiten de repo-root wijst --
        de versie-bump mag nooit buiten de repo schrijven.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$MarketplaceJson
    )
    $marketplace = $MarketplaceJson | ConvertFrom-Json
    if (-not ($marketplace.PSObject.Properties.Name -contains 'plugins') -or -not $marketplace.plugins) {
        throw "marketplace.json heeft geen 'plugins'-lijst."
    }
    $rootPrefix = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') + '\'
    foreach ($p in $marketplace.plugins) {
        if (-not $p.source) { throw "plugin '$($p.name)' mist een 'source'." }
        # Een absolute source is per definitie buiten de repo-conventie -- expliciet melden i.p.v.
        # de verwarrende Join-Path/GetFullPath-fout die er anders uit zou rollen.
        if ([System.IO.Path]::IsPathRooted($p.source)) {
            throw "plugin '$($p.name)': source '$($p.source)' wijst buiten de repo (absoluut pad)."
        }
        $manifest = $null
        try {
            $manifest = [System.IO.Path]::GetFullPath(
                (Join-Path $RepoRoot (Join-Path $p.source '.claude-plugin\plugin.json')))
        } catch {
            throw "plugin '$($p.name)': source '$($p.source)' is geen geldig pad."
        }
        if (-not $manifest.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "plugin '$($p.name)': source '$($p.source)' wijst buiten de repo ($manifest)."
        }
        $manifest
    }
}

function Split-Changelog {
    <#
        Prive-helper: ontleedt CHANGELOG.md in zijn onderdelen. Retourneert een object met Nl, Head
        (t/m de '## Pull Requests'-regel), PrIntro, Entries (array van entry-blokken), RelIntro en
        ExistingReleases. Gooit als de secties ontbreken of er geen entries te releasen zijn.
    #>
    param([Parameter(Mandatory)][string]$Content)

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

    $head = $lines[0..$prIdx]

    $prBody = @($lines[($prIdx + 1)..($relIdx - 1)])
    $prFirst = -1
    for ($i = 0; $i -lt $prBody.Count; $i++) { if ($prBody[$i] -match '^###\s') { $prFirst = $i; break } }
    if ($prFirst -lt 0) { throw "Geen changelog-entries onder '## Pull Requests' -- niets te releasen." }

    $prIntro = if ($prFirst -gt 0) { @($prBody[0..($prFirst - 1)]) } else { @() }
    $entryLines = @($prBody[$prFirst..($prBody.Count - 1)])

    # Entryregels opdelen in blokken: een nieuw blok begint bij elke '### '-kop. '---'-scheiders
    # tussen entries worden overgeslagen.
    $entries = @()
    $cur = $null
    foreach ($ln in $entryLines) {
        if ($ln -match '^###\s') {
            if ($null -ne $cur) { $entries += (($cur -join $nl).Trim()) }
            $cur = @($ln)
        } elseif ($null -ne $cur) {
            if ($ln -match '^---\s*$') { continue }
            $cur += $ln
        }
    }
    if ($null -ne $cur) { $entries += (($cur -join $nl).Trim()) }

    $relBody = @($lines[($relIdx + 1)..($lines.Count - 1)])
    $relFirst = -1
    for ($i = 0; $i -lt $relBody.Count; $i++) { if ($relBody[$i] -match '^###\s') { $relFirst = $i; break } }
    $relIntroLines = if ($relFirst -ge 0) { @($relBody[0..($relFirst - 1)]) } else { $relBody }
    $existingReleases = if ($relFirst -ge 0) { @($relBody[$relFirst..($relBody.Count - 1)]) } else { @() }

    return [pscustomobject]@{
        Nl               = $nl
        Head             = $head
        PrIntro          = $prIntro
        Entries          = $entries
        RelIntroLines    = $relIntroLines
        ExistingReleases = $existingReleases
    }
}

function Get-PullRequestEntries {
    <# Retourneert de te-releasen entry-blokken (### ... + body + PR-link) uit de Pull-Requests-sectie. #>
    param([Parameter(Mandatory)][string]$Content)
    return @((Split-Changelog -Content $Content).Entries)
}

function Convert-ChangelogForRelease {
    <#
        Leegt de '## Pull Requests'-sectie tot zijn intro en zet bovenaan '## Releases' een korte
        VERWIJZING '### [v<Version>] - <Date> - <Type>' naar het release-notes-bestand ($NotesRelPath).
        Pure string-in/uit.
    #>
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date,
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)][string]$NotesRelPath
    )
    $emDash = [char]0x2014
    $s = Split-Changelog -Content $Content
    $nl = $s.Nl

    $block = @(
        "### [v$Version] - $Date $emDash $Type",
        '',
        "Zie [$NotesRelPath]($NotesRelPath) voor de volledige release-notes."
    )

    $relIntroText = ($s.RelIntroLines -join "`n")
    if ($relIntroText -match 'Nog geen releases') {
        $relIntro = @(
            "De vastgelegde versies van de marketplace $emDash nieuwste bovenaan. Elke release bumpt alle",
            'plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.'
        )
    } else {
        $relIntro = @($s.RelIntroLines | Where-Object { $_ -ne '' })
    }

    $out = @()
    $out += $s.Head
    $out += ''
    $out += ($s.PrIntro | Where-Object { $_ -ne '' })
    $out += ''
    $out += '## Releases'
    $out += ''
    $out += $relIntro
    $out += ''
    $out += $block
    if ($s.ExistingReleases.Count -gt 0) {
        $out += ''
        $out += '---'
        $out += ''
        $out += $s.ExistingReleases
    }

    return (($out -join $nl).TrimEnd() + $nl)
}

function Get-EntryPlugins {
    <#
        Leest de optionele 'Plugins: a, b'-regel uit een entry-blok (door fold-changelog-entry.ps1
        afgeleid uit de PR-bestanden). Retourneert een array van plugin-namen; leeg = de entry raakt
        geen plugin-content (werkplaats-intern).
    #>
    param([Parameter(Mandatory)][string]$EntryText)
    $m = [regex]::Match($EntryText, '(?m)^Plugins:\s*(.+?)\s*$')
    if (-not $m.Success) { return @() }
    return @($m.Groups[1].Value -split '\s*,\s*' | Where-Object { $_ })
}

function Convert-EntryLinksForPluginChangelog {
    <#
        Herschrijft repo-root-relatieve markdown-links naar absolute GitHub-blob-URLs, zodat een
        entry ook leesbaar is in de plugin-cache van een consument (waar de repo-bestanden niet
        bestaan). Externe (http/mailto), anker- (#), absolute (/) en ../-links blijven ongemoeid.
    #>
    param(
        [Parameter(Mandatory)][string]$EntryText,
        [string]$RepoBlobUrl = 'https://github.com/DaveKJohn/davekjohns-workshop/blob/main/'
    )
    return [regex]::Replace($EntryText, '\]\((?!https?:|mailto:|#|/|\.\./)([^)]+)\)', "](${RepoBlobUrl}`$1)")
}

function Build-PluginChangelogSection {
    <#
        Bouwt het '## v<Version> <emDash> <Date>'-blok voor een plugin-CHANGELOG uit de entries die
        die plugin raken. Pure string-uit (LF-newlines).
    #>
    param(
        [Parameter(Mandatory)][string[]]$Entries,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date
    )
    $emDash = [char]0x2014
    $body = (@($Entries | ForEach-Object { $_.Trim() }) -join "`n`n---`n`n")
    return "## v$Version $emDash $Date`n`n$body`n"
}

function Add-PluginChangelogSection {
    <#
        Voegt een release-sectie bovenaan een plugin-CHANGELOG toe (na de intro, voor de eerste
        '## '-kop, nieuwste eerst); bestaat er nog geen inhoud, dan wordt de volledige CHANGELOG
        inclusief intro-header opgebouwd. Pure string-in/uit.
    #>
    param(
        [string]$Existing = '',
        [Parameter(Mandatory)][string]$Section,
        [Parameter(Mandatory)][string]$PluginName
    )
    $emDash = [char]0x2014
    if (-not $Existing) {
        $intro = "# Changelog $emDash $PluginName`n`n" +
            "Consument-gerichte geschiedenis van deze plugin: per release de wijzigingen die deze plugin`n" +
            "raakten. Automatisch bijgeschreven door ``cut-release.ps1`` van de marketplace-repo`n" +
            "(davekjohns-workshop); de volledige werkplaats-geschiedenis staat daar in ``CHANGELOG.md`` en`n" +
            "``releases/``.`n`n"
        return ($intro + $Section.TrimEnd() + "`n")
    }
    $m = [regex]::Match($Existing, '(?m)^## ')
    if ($m.Success) {
        return $Existing.Substring(0, $m.Index) + $Section.TrimEnd() + "`n`n---`n`n" + $Existing.Substring($m.Index)
    }
    return ($Existing.TrimEnd() + "`n`n" + $Section.TrimEnd() + "`n")
}

function Build-ReleaseNotes {
    <#
        Bouwt de volledige release-notes (het releases/development/<X.Y>/<X.Y.Z>.md-bestand) uit de
        entry-blokken, gegroepeerd per branch-type. Pure string-uit (LF-newlines).
    #>
    param(
        [Parameter(Mandatory)][string[]]$Entries,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date,
        [Parameter(Mandatory)][string]$Type,
        [string]$Title = '',
        # Prefix om repo-root-relatieve links in entry-bodies te laten resolveren vanuit de diepere
        # locatie van het notes-bestand (releases/development/<X.Y>/ = 3 mappen diep -> '../../../').
        [string]$LinkPrefix = '../../../'
    )
    $md = [char]0x00B7

    # Entries zijn geschreven met repo-root-relatieve links; herschrijf ze zodat ze vanuit het
    # notes-bestand kloppen. Externe (http/mailto), anker- (#) en absolute (/) links blijven ongemoeid,
    # net als links die al met ../ beginnen.
    $Entries = @($Entries | ForEach-Object {
        [regex]::Replace($_, '\]\((?!https?:|mailto:|#|/|\.\./)([^)]+)\)', "](${LinkPrefix}`$1)")
    })
    $catOrder = @('Feat', 'Fix', 'Docs', 'Chore', 'Overig')
    $catTitle = @{
        Feat   = 'Nieuwe features & verbeteringen'
        Fix    = 'Fixes'
        Docs   = 'Documentatie'
        Chore  = 'Onderhoud (scripts, tooling, config)'
        Overig = 'Overig'
    }

    $grouped = @{}
    foreach ($e in $Entries) {
        $heading = ($e -split "`r?`n")[0]
        $t = 'Overig'
        # Kop: "### #NN <md> titel <md> type <md> datum" -- type = op een na laatste veld.
        $parts = @(($heading -replace '^###\s+', '') -split "\s*$md\s*")
        if ($parts.Count -ge 2) {
            $cand = $parts[$parts.Count - 2].Trim()
            if ($catOrder -contains $cand) { $t = $cand }
        }
        if (-not $grouped.ContainsKey($t)) { $grouped[$t] = New-Object System.Collections.Generic.List[string] }
        $grouped[$t].Add(($e.Trim()))
    }

    $sections = @()
    foreach ($cat in $catOrder) {
        if ($grouped.ContainsKey($cat)) {
            $body = ($grouped[$cat].ToArray() -join "`n`n---`n`n")
            $sections += "## $($catTitle[$cat])`n`n$body"
        }
    }

    $titleLine = if ($Title) { "$Title`n`n" } else { '' }
    $header = "# Release notes v$Version`n`n**Datum:** $Date  `n**Type:** $Type`n`n$titleLine"
    return ($header + ($sections -join "`n`n") + "`n")
}
