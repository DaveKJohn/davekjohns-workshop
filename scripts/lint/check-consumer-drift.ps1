<#
.SYNOPSIS
    Drift-lint voor de gedeelde Claude-Specialists-plugin: vergelijkt eventuele lokale, mogelijk
    verouderde agent-def-kopieen in een consumerende repo (life-hub/smartwatchbanden) met de
    canonieke bron in dit plugin-repo, en signaleert drift voordat zo'n kopie wordt opgeruimd.
.DESCRIPTION
    Topologie (vastgesteld door Dave): life-hub en swb wijzen via een lokale directory-marketplace-
    source rechtstreeks naar deze checkout (zie README.md, sectie "Consumptie") -- er is dus GEEN
    fysieke kopie nodig zodra een consumerende repo is omgebouwd naar de gedeelde bron. Tijdens de
    overgang (Fase 3) kan een consumerende repo echter nog een eigen lokale kopie hebben van een
    agent-def die inmiddels ook hier gedeeld is (bv. life-hub .claude/agents/<group>-<id>-agent.md,
    of swb .claude-plugins/specialists/agents/<group>-<id>-agent.md). Dit script:

      1. Leest de gedeelde ids + groups uit specialists/agents/*.md in dit repo (bron van waarheid).
      2. Zoekt in de opgegeven consumerende repo op de bekende legacy-paden naar een lokaal bestand
         met datzelfde id.
      3. Meldt per gevonden id een van drie uitkomsten:
           - MISSING   geen lokale kopie gevonden -- al gemigreerd, geen actie nodig.
           - IDENTICAL de lokale kopie is (na normalisatie van regeleindes/trailing whitespace)
                       gelijk aan de canonieke versie -- een dode kopie, veilig te verwijderen.
           - DRIFTED   de inhoud wijkt af -- eerst bekijken voor het verwijderen; kan een
                       nog-niet-teruggelegde wijziging zijn die eerst hierheen moet.

    Dit script wijzigt NIETS in de consumerende repo -- puur read-only signalering. Opruimen of
    het instellen van de marketplace-source zelf is Fase-3-werk in de consumerende repo (Sylvester
    daar), niet iets wat dit plugin-repo cross-repo doet.

    Exit-code: 0 = geen DRIFTED-bevindingen. 1 = minstens een DRIFTED-bevinding (bruikbaar als
    lokale poort in de consumerende repo, naast diens eigen lint-brain.ps1).
.PARAMETER ConsumerPath
    Pad naar de root van de consumerende repo (life-hub of smartwatchbanden). Verplicht.
.PARAMETER Quiet
    Toon alleen ids met een bevinding (DRIFTED/IDENTICAL); onderdruk MISSING-regels.
.EXAMPLE
    ./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\Users\davek\Documents\GitHub\DaveKJohn\life-hub
.EXAMPLE
    ./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\Users\davek\Documents\GitHub\davekokbwj\smartwatchbanden -Quiet
#>
param(
    [Parameter(Mandatory = $true)][string]$ConsumerPath,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PluginRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')
$SourceDir = Join-Path $PluginRoot 'specialists\agents'
if (-not (Test-Path -LiteralPath $SourceDir)) {
    Write-Host "Kan de canonieke agent-defs niet vinden op $SourceDir -- stop." -ForegroundColor Red
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

# --- Bron van waarheid inlezen: id, group en inhoud per gedeelde specialist ------------------------
$sourceById = @{}
Get-ChildItem -Path $SourceDir -Filter '*-agent.md' -File | ForEach-Object {
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
    Write-Host "Geen gedeelde agent-defs gevonden in $SourceDir -- niets te vergelijken." -ForegroundColor Yellow
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
Write-Host "Samenvatting: $missingCount missing, $identicalCount identical (dode kopieen), $driftCount drifted." -ForegroundColor Cyan
if ($driftCount -gt 0) {
    Write-Host "Bekijk de DRIFTED-bestanden voor het verwijderen -- kan een wijziging bevatten die eerst hierheen (canoniek) terug moet." -ForegroundColor Yellow
    exit 1
}
exit 0
