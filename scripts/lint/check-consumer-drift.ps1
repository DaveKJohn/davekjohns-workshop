<#
.SYNOPSIS
    Drift-lint voor de gedeelde Claude-Specialists-plugin: vergelijkt eventuele lokale, mogelijk
    verouderde agent-def-kopieen in een consumerende repo (life-hub/smartwatchbanden) met de
    canonieke bron in dit plugin-repo, en signaleert drift voordat zo'n kopie wordt opgeruimd.
.DESCRIPTION
    Topologie: life-hub en swb wijzen via een remote `github`-marketplace-source
    (`DaveKJohn/davekjohns-workshop`) naar dit repo -- de Claude Code CLI clonet en cachet het zelf
    (zie README.md, sectie "Consumptie"). Er is dus GEEN fysieke kopie nodig zodra een consumerende
    repo is omgebouwd naar de gedeelde bron. Tijdens de overgang (Fase 3) kan een consumerende repo
    echter nog een eigen lokale kopie hebben van een
    agent-def die inmiddels ook hier gedeeld is (bv. life-hub .claude/agents/<group>-<id>-agent.md,
    of swb .claude-plugins/specialists/agents/<group>-<id>-agent.md). Dit script:

      1. Leest de ids + groups uit alle drie de plugins (specialists, specialists-lifehub,
         specialists-shopify) in dit repo (bron van waarheid) -- de gedeelde kern plus de twee
         domein-groepen.
      2. Zoekt in de opgegeven consumerende repo op de bekende legacy-paden naar een lokaal bestand
         met datzelfde id.
      3. Meldt per gevonden id een van drie uitkomsten:
           - MISSING   geen lokale kopie gevonden -- al gemigreerd, geen actie nodig.
           - IDENTICAL de lokale kopie is (na normalisatie van regeleindes/trailing whitespace)
                       gelijk aan de canonieke versie -- een dode kopie, veilig te verwijderen.
           - DRIFTED   de inhoud wijkt af -- eerst bekijken voor het verwijderen; kan een
                       nog-niet-teruggelegde wijziging zijn die eerst hierheen moet.

    Naast de agent-def-kopieen vergelijkt dit script ook de PERSONA'S (de orchestrator +
    hoofdloop-specialisten zoals Chris/Derek/Rendall). Die hebben bewust geen agent-def; hun
    draagbare bron woont in <plugin>/personas/<g>-<id>-persona.md en wordt bij het bootstrappen naar
    de repo-laag van een consument gekopieerd: .claude/plugins/claude-specialists/<plugin>/
    <g>-<id>-extension.md (sinds de life-hub-pariteit) of het legacy-pad
    .claude/extensions/<g>-<id>-extension.md. Voor elke
    plugin-persona vergelijkt dit script de DRAAGBARE BODY (alles boven de '## Eigen aan deze
    repo'-marker; de repo-lens eronder is per repo verschillend en wordt niet vergeleken) met de
    body van de consument-kopie. Een consument die het lens-only-model draait (de extension opent met
    een '> Repo-lens (lens-only persona)'-blockquote en draagt bewust geen body-kopie) wordt als
    LENS-ONLY gerapporteerd -- de body komt rechtstreeks uit de plugin, dus er valt niets te
    vergelijken. Deze persona-bevindingen zijn INFORMATIEF: ze tellen niet mee in de
    exit-code, want een bestaande consument met een handgeschreven persona is per definitie DRIFTED
    tot hij gecoordineerd is gereconcilieerd -- dat is het signaal, geen poortbreuk.

    Dit script wijzigt NIETS in de consumerende repo -- puur read-only signalering. Opruimen of
    het instellen van de marketplace-source zelf is Fase-3-werk in de consumerende repo (Sylvester
    daar), niet iets wat dit plugin-repo cross-repo doet.

    Exit-code: 0 = geen DRIFTED agent-def-bevindingen. 1 = minstens een DRIFTED agent-def-bevinding
    (bruikbaar als lokale poort in de consumerende repo, naast diens eigen lint-brain.ps1).
    Persona-drift beinvloedt de exit-code NIET.
.PARAMETER ConsumerPath
    Pad naar de root van de consumerende repo (life-hub of smartwatchbanden). Verplicht.
.PARAMETER Quiet
    Toon alleen ids met een bevinding (DRIFTED/IDENTICAL); onderdruk MISSING-regels.
.EXAMPLE
    ./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\pad\naar\life-hub
.EXAMPLE
    ./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\pad\naar\smartwatchbanden -Quiet
#>
param(
    [Parameter(Mandatory = $true)][string]$ConsumerPath,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PluginRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')
# Alle drie de plugins dragen canonieke agent-defs: de gedeelde kern (specialists) plus de twee
# domein-groepen (specialists-lifehub, specialists-shopify). We scannen ze alle drie, zodat de
# drift-check ook de domein-specialisten van een consumerende repo dekt.
$SourceDirs = @(
    (Join-Path $PluginRoot 'claude-code-plugins\claude-specialists\specialists\agents')
    (Join-Path $PluginRoot 'claude-code-plugins\claude-specialists\specialists-lifehub\agents')
    (Join-Path $PluginRoot 'claude-code-plugins\claude-specialists\specialists-shopify\agents')
) | Where-Object { Test-Path -LiteralPath $_ }
if ($SourceDirs.Count -eq 0) {
    Write-Host "Kan geen canonieke agent-defs vinden onder $PluginRoot -- stop." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -LiteralPath $ConsumerPath)) {
    Write-Host "ConsumerPath '$ConsumerPath' bestaat niet -- stop." -ForegroundColor Red
    exit 1
}
$ConsumerRoot = (Resolve-Path -LiteralPath $ConsumerPath).Path

function Read-NormalizedText {
    param([string]$Path)
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    # Regeleindes en trailing whitespace per regel normaliseren -- puur een tekstuele vergelijking,
    # geen semantische diff. Zie categorie B/C in lint-brain.ps1 (life-hub) voor dezelfde heuristiek-aanpak.
    $lines = $raw -split "`r?`n" | ForEach-Object { $_.TrimEnd() }
    return ($lines -join "`n").Trim()
}

function Get-PortableBody {
    # Haalt de DRAAGBARE body uit een persona-sjabloon of een extensions-kopie: alles vanaf de eerste
    # markdown-H1-kop (^# ) tot NET VOOR de '## Eigen aan deze repo'-marker. Frontmatter en leidende
    # HTML-commentaren vallen er vanzelf buiten (ze staan voor de eerste #-kop). Zelfde normalisatie
    # als Read-NormalizedText, zodat een puur tekstuele vergelijking mogelijk is.
    param([string]$Path)
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    $lines = $raw -split "`r?`n"
    $body = New-Object System.Collections.Generic.List[string]
    $started = $false
    foreach ($line in $lines) {
        if (-not $started) {
            if ($line -match '^#\s') { $started = $true } else { continue }
        }
        if ($line -match '^##\s+Eigen aan deze repo') { break }
        # De indexregel onder de titel is sinds inbound #64 locatie-onafhankelijk (platte tekst, geen
        # pad-diepte-afhankelijke CLAUDE.md-link meer). Een consument kan de body daardoor op elk pad
        # byte-identiek overnemen -- een zuiver tekstuele vergelijking volstaat, geen link-normalisatie.
        $body.Add($line.TrimEnd())
    }
    return (($body -join "`n").Trim())
}

# --- Bron van waarheid inlezen: id, group en inhoud per gedeelde specialist ------------------------
$sourceById = @{}
Get-ChildItem -Path $SourceDirs -Filter '*-agent.md' -File | ForEach-Object {
    $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    $idMatch = [regex]::Match($text, '(?m)^id:\s*(\d+)\s*$')
    $groupMatch = [regex]::Match($text, '(?m)^group:\s*(\d+)\s*$')
    if (-not $idMatch.Success -or -not $groupMatch.Success) {
        Write-Host "Waarschuwing: $($_.Name) mist 'id:' of 'group:' in de frontmatter -- overgeslagen." -ForegroundColor Yellow
        return
    }
    $id = $idMatch.Groups[1].Value
    $group = $groupMatch.Groups[1].Value
    $sourceById[$id] = [pscustomobject]@{
        Id            = $id
        Group         = $group
        File          = $_.FullName
        Normalized    = Read-NormalizedText $_.FullName
    }
}

if ($sourceById.Count -eq 0) {
    Write-Host "Geen agent-defs gevonden onder $PluginRoot -- niets te vergelijken." -ForegroundColor Yellow
    exit 0
}

# --- Bekende legacy-locaties in een consumerende repo, in volgorde van waarschijnlijkheid ----------
function Get-LegacyCandidates {
    param([string]$Root, [string]$Id, [string]$Group)
    @(
        (Join-Path $Root ".claude\agents\$Group-$Id-agent.md")
        (Join-Path $Root ".claude\agents\$Id-agent.md")
        (Join-Path $Root ".claude-plugins\specialists\agents\$Group-$Id-agent.md")
        (Join-Path $Root ".claude-plugin\specialists\agents\$Group-$Id-agent.md")
    )
}

$results = New-Object System.Collections.Generic.List[object]
foreach ($id in ($sourceById.Keys | Sort-Object)) {
    $src = $sourceById[$id]
    $found = $null
    foreach ($candidate in (Get-LegacyCandidates -Root $ConsumerRoot -Id $src.Id -Group $src.Group)) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $found = $candidate; break }
    }
    if (-not $found) {
        $results.Add([pscustomobject]@{ Id = $id; Status = 'MISSING'; Path = $null })
        continue
    }
    $localNormalized = Read-NormalizedText $found
    $status = if ($localNormalized -eq $src.Normalized) { 'IDENTICAL' } else { 'DRIFTED' }
    $results.Add([pscustomobject]@{ Id = $id; Status = $status; Path = $found })
}

# --- Rapport -----------------------------------------------------------------------------------------
Write-Host "== check-consumer-drift -- $ConsumerRoot ==" -ForegroundColor Cyan
$driftCount = 0
$identicalCount = 0
$missingCount = 0
foreach ($r in ($results | Sort-Object Id)) {
    $name = $sourceById[$r.Id].File | Split-Path -Leaf
    switch ($r.Status) {
        'MISSING' {
            $missingCount++
            if (-not $Quiet) { Write-Host "  [MISSING]   id $($r.Id) ($name) -- geen lokale kopie, al gemigreerd." -ForegroundColor DarkGray }
        }
        'IDENTICAL' {
            $identicalCount++
            Write-Host "  [IDENTICAL] id $($r.Id) ($name) -- dode kopie op $($r.Path), veilig te verwijderen." -ForegroundColor Green
        }
        'DRIFTED' {
            $driftCount++
            Write-Host "  [DRIFTED]   id $($r.Id) ($name) -- wijkt af van de canonieke versie: $($r.Path)" -ForegroundColor Red
        }
    }
}
Write-Host ""
Write-Host "Samenvatting agent-defs: $missingCount missing, $identicalCount identical (dode kopieen), $driftCount drifted." -ForegroundColor Cyan

# --- Persona-drift (informatief): draagbare body van de plugin-persona's vs. de consument-kopie -----
$personaDirs = @(@(
    (Join-Path $PluginRoot 'claude-code-plugins\claude-specialists\specialists\personas')
    (Join-Path $PluginRoot 'claude-code-plugins\claude-specialists\specialists-lifehub\personas')
    (Join-Path $PluginRoot 'claude-code-plugins\claude-specialists\specialists-shopify\personas')
) | Where-Object { Test-Path -LiteralPath $_ })

$personaResults = New-Object System.Collections.Generic.List[object]
if ($personaDirs.Count -gt 0) {
    Get-ChildItem -Path $personaDirs -Filter '*-persona.md' -File | Sort-Object Name | ForEach-Object {
        if ($_.BaseName -notmatch '^(\d{2})-(\d{2})-persona$') { return }
        $g = $Matches[1]; $id = $Matches[2]
        $srcBody = Get-PortableBody $_.FullName
        # De consument-kopie kan op het plugin-pad wonen (.claude/plugins/claude-specialists/
        # <plugin>/, sinds de life-hub-pariteit) of op het legacy-pad (.claude/extensions/).
        $pluginName = Split-Path (Split-Path $_.DirectoryName -Parent) -Leaf
        $consumerExt = $null
        foreach ($candidate in @(
            (Join-Path $ConsumerRoot ".claude\plugins\claude-specialists\$pluginName\$g-$id-extension.md")
            (Join-Path $ConsumerRoot ".claude\extensions\$g-$id-extension.md")
        )) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { $consumerExt = $candidate; break }
        }
        if ($null -eq $consumerExt) {
            $personaResults.Add([pscustomobject]@{ Name = $_.Name; Status = 'MISSING'; Path = $null })
        } else {
            $extRaw = [System.IO.File]::ReadAllText($consumerExt, [System.Text.Encoding]::UTF8)
            if ($extRaw -match '(?m)^>\s*Repo-lens \(lens-only persona\)') {
                # Lens-only-model: de extension is puur de repo-lens en draagt geen body-kopie -- de
                # draagbare body komt rechtstreeks uit de plugin, dus er valt niets te vergelijken.
                # Zonder deze herkenning vergelijkt Get-PortableBody de lens-tekst met de
                # sjabloon-body en meldt de persona eeuwig als DRIFTED (inbound life-hub #69).
                $personaResults.Add([pscustomobject]@{ Name = $_.Name; Status = 'LENS-ONLY'; Path = $consumerExt })
            } else {
                $localBody = Get-PortableBody $consumerExt
                $status = if ($localBody -eq $srcBody) { 'IDENTICAL' } else { 'DRIFTED' }
                $personaResults.Add([pscustomobject]@{ Name = $_.Name; Status = $status; Path = $consumerExt })
            }
        }
    }
}

if ($personaResults.Count -gt 0) {
    Write-Host ""
    Write-Host "-- Persona's (draagbare body vs. de <g>-<id>-extension.md-kopie in de consument) --" -ForegroundColor Cyan
    $pDrift = 0
    foreach ($r in $personaResults) {
        switch ($r.Status) {
            'MISSING'   { if (-not $Quiet) { Write-Host "  [MISSING]   $($r.Name) -- geen extensions-kopie in de consument (nog niet gebootstrapt)." -ForegroundColor DarkGray } }
            'IDENTICAL' { Write-Host "  [IDENTICAL] $($r.Name) -- body gelijk aan de canonieke bron." -ForegroundColor Green }
            'LENS-ONLY' { Write-Host "  [LENS-ONLY] $($r.Name) -- lens-only-model: body komt uit de plugin, niets te vergelijken." -ForegroundColor Green }
            'DRIFTED'   { $pDrift++; Write-Host "  [DRIFTED]   $($r.Name) -- body wijkt af van de canonieke bron: $($r.Path)" -ForegroundColor Yellow }
        }
    }
    Write-Host "  Persona-drift is INFORMATIEF (telt niet mee in de exit-code): $pDrift drifted." -ForegroundColor DarkGray
}

if ($driftCount -gt 0) {
    Write-Host ""
    Write-Host "Bekijk de DRIFTED agent-def-bestanden voor het verwijderen -- kan een wijziging bevatten die eerst hierheen (canoniek) terug moet." -ForegroundColor Yellow
    exit 1
}
exit 0
