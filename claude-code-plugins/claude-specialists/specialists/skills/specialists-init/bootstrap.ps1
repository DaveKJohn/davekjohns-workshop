<#
.SYNOPSIS
    Bootstrap-script van de specialists-init-skill: zet in een CONSUMERENDE repo de niet-plugin-laag
    van het Claude-Specialists-systeem op -- de orchestrator + hoofdloop-persona's (Chris/Derek/
    Rendall) via de @-import in CLAUDE.md, plus een gedocumenteerd settings-/hooks-voorstel.
.DESCRIPTION
    Een Claude Code-plugin kan subagents leveren, maar GEEN altijd-aan-hoofdloop-context injecteren
    en niet de CLAUDE.md van een consument bewerken. Chris (de orchestrator) is precies zulke
    hoofdloop-context: hij wordt geladen via een @-import onderaan de CLAUDE.md van de consument.
    Dit script vult dat gat. Het wordt door de skill aangeroepen NADAT de consument de
    marketplace-source + enabledPlugins al heeft ingesteld en de sessie is herstart (anders is de
    skill zelf nog niet beschikbaar -- de kip-en-ei die de skill in stap 0 documenteert).

    Het doet alleen VEILIGE, additieve handelingen -- het overschrijft nooit bestaande inhoud:
      1. Kopieert <plugin>/personas/<g>-<id>-persona.md naar
         <ConsumerRoot>/.claude/extensions/<g>-<id>-extension.md -- alleen als die nog niet bestaat.
      1b. Zet voor elke subagent van de INGESCHAKELDE plugin(s) (enabledPlugins in de settings van
          de consument; zonder settings alleen de eigen plugin) een lege lens-scaffold neer in
          .claude/extensions/<g>-<id>-extension.md, duidelijk gemarkeerd als VUL-IN -- zo is
          zichtbaar waar repo-specifieke taken per specialist worden aangevuld.
      2. Zorgt dat <ConsumerRoot>/CLAUDE.md onderaan de @-import van de orchestrator draagt
         (@.claude/extensions/01-01-extension.md). Ontbreekt CLAUDE.md, dan schrijft het een minimale
         scaffold; bestaat de import al, dan doet het niets.
      3. Schrijft een voorstel-snippet (.claude/settings.suggested.jsonc) met de aanbevolen
         permissions.deny + een hooks-stub. Het RAAKT settings.json NIET aan -- een JSON-merge is
         repo-specifiek en risicovol, dus die beoordeling laat het aan de gebruiker/Claude.

    Exit-code: 0 = klaar (ook als alles al aanwezig was). 1 = de plugin-persona-bron of de
    ConsumerRoot is niet gevonden.
.PARAMETER ConsumerRoot
    Root van de consumerende repo. Default: de huidige werkmap.
.EXAMPLE
    powershell -File bootstrap.ps1
.EXAMPLE
    powershell -File bootstrap.ps1 -ConsumerRoot C:\pad\naar\mijn-repo
#>
param(
    [string]$ConsumerRoot = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# De persona-bron zit twee niveaus boven dit script: <plugin>/skills/specialists-init/ -> <plugin>/personas/
$personaDir = Join-Path $PSScriptRoot '..\..\personas'
if (-not (Test-Path -LiteralPath $personaDir -PathType Container)) {
    Write-Host "Kan de persona-bron niet vinden ($personaDir) -- stop." -ForegroundColor Red
    exit 1
}
$personaDir = (Resolve-Path -LiteralPath $personaDir).Path
if (-not (Test-Path -LiteralPath $ConsumerRoot -PathType Container)) {
    Write-Host "ConsumerRoot '$ConsumerRoot' bestaat niet -- stop." -ForegroundColor Red
    exit 1
}
$ConsumerRoot = (Resolve-Path -LiteralPath $ConsumerRoot).Path

Write-Host "== specialists-init bootstrap -- $ConsumerRoot ==" -ForegroundColor Cyan

# --- 1. Persona-sjablonen naar .claude/extensions/ (nooit overschrijven) ----------------------------
$extDir = Join-Path $ConsumerRoot '.claude\extensions'
if (-not (Test-Path -LiteralPath $extDir)) {
    New-Item -ItemType Directory -Path $extDir -Force | Out-Null
    Write-Host "  [maak]  .claude/extensions/ aangemaakt." -ForegroundColor Green
}

$copied = 0; $kept = 0
Get-ChildItem -Path $personaDir -Filter '*-persona.md' -File | Sort-Object Name | ForEach-Object {
    if ($_.BaseName -notmatch '^(\d{2})-(\d{2})-persona$') { return }
    $dest = Join-Path $extDir ($_.BaseName -replace '-persona$', '-extension')
    $dest = "$dest.md"
    if (Test-Path -LiteralPath $dest -PathType Leaf) {
        Write-Host "  [houd]  $(Split-Path $dest -Leaf) bestaat al -- niet overschreven." -ForegroundColor DarkGray
        $script:kept++
    } else {
        Copy-Item -LiteralPath $_.FullName -Destination $dest
        Write-Host "  [kopie] $($_.Name) -> .claude/extensions/$(Split-Path $dest -Leaf)" -ForegroundColor Green
        $script:copied++
    }
}

# --- 1b. Lege lens-scaffolds voor de subagent-specialisten (nooit overschrijven) --------------------
# De agent-defs komen uit de plugin(s); de repo-lens per specialist woont in de consument. Voor elke
# agent van de ingeschakelde plugin(s) zetten we een lege, duidelijk gemarkeerde scaffold neer.

# Eigen plugin-naam: in de bron-layout is de mapnaam de plugin-naam; in de plugin-cache is dat de
# map boven de versie-map (...\<plugin>\<x.y.z>\).
function Get-OwnPluginName([string]$PluginRoot) {
    $leaf = Split-Path $PluginRoot -Leaf
    if ($leaf -match '^\d+\.\d+\.\d+') { return (Split-Path (Split-Path $PluginRoot -Parent) -Leaf) }
    return $leaf
}

# agents/-map van een plugin, in beide layouts (bron: sibling-map; cache: <naam>\<versie>\agents).
# Let op de dubbele rol van $parent (vondst Victor): in de bron-layout is dat de familie-map, in de
# cache-layout de plugin-naam-map (boven de versie-mappen) -- $market komt in beide gevallen op de
# juiste bovenliggende root uit.
function Get-PluginAgentsDir([string]$PluginName, [string]$OwnPluginRoot) {
    $parent = Split-Path $OwnPluginRoot -Parent
    $src = Join-Path $parent (Join-Path $PluginName 'agents')
    if (Test-Path -LiteralPath $src -PathType Container) { return (Resolve-Path -LiteralPath $src).Path }
    $market = Split-Path $parent -Parent
    $nameDir = Join-Path $market $PluginName
    if (Test-Path -LiteralPath $nameDir -PathType Container) {
        # Semantisch sorteren via [version] (vondst Victor): een kale string-sort zet 1.9.0 boven
        # 1.10.0 zodra een versie-segment twee cijfers krijgt.
        $versions = Get-ChildItem -LiteralPath $nameDir -Directory |
            Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
            Sort-Object { [version]$_.Name } -Descending
        foreach ($v in $versions) {
            $a = Join-Path $v.FullName 'agents'
            if (Test-Path -LiteralPath $a -PathType Container) { return (Resolve-Path -LiteralPath $a).Path }
        }
    }
    return $null
}

$ownPluginRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$ownPluginName = Get-OwnPluginName $ownPluginRoot

# Ingeschakelde plugins uit de settings van de consument; zonder (leesbare) settings alleen de
# eigen plugin. Plugin-namen worden als slug gevalideerd voor ze een pad worden.
$pluginNames = @($ownPluginName)
$consumerSettings = Join-Path $ConsumerRoot '.claude\settings.json'
if (Test-Path -LiteralPath $consumerSettings -PathType Leaf) {
    try {
        $cs = Get-Content -LiteralPath $consumerSettings -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cs.PSObject.Properties.Name -contains 'enabledPlugins') {
            $enabledNames = @($cs.enabledPlugins.PSObject.Properties |
                Where-Object { $_.Value -eq $true } |
                ForEach-Object { $_.Name.Split('@')[0] })
            if ($enabledNames.Count -gt 0) { $pluginNames = $enabledNames }
        }
    } catch {
        Write-Host "  [let op] .claude/settings.json onleesbaar -- lens-scaffolds alleen voor '$ownPluginName'." -ForegroundColor Yellow
    }
}

$scaffolded = 0; $lensKept = 0
foreach ($pluginName in ($pluginNames | Sort-Object -Unique)) {
    if ($pluginName -notmatch '^[a-z0-9][a-z0-9-]*$') {
        Write-Host "  [let op] plugin-naam '$pluginName' is geen geldige slug -- overgeslagen." -ForegroundColor Yellow
        continue
    }
    $agentsDir = Get-PluginAgentsDir -PluginName $pluginName -OwnPluginRoot $ownPluginRoot
    if ($null -eq $agentsDir) {
        Write-Host "  [let op] agents-map van plugin '$pluginName' niet gevonden -- overgeslagen." -ForegroundColor Yellow
        continue
    }
    Get-ChildItem -Path $agentsDir -Filter '*-agent.md' -File | Sort-Object Name | ForEach-Object {
        if ($_.BaseName -notmatch '^(\d{2})-(\d{2})-agent$') { return }
        $group = $Matches[1]; $id = $Matches[2]
        $dest = Join-Path $extDir "$group-$id-extension.md"
        if (Test-Path -LiteralPath $dest -PathType Leaf) { $script:lensKept++; return }
        $agentName = ''
        foreach ($line in (Get-Content -LiteralPath $_.FullName -TotalCount 10)) {
            if ($line -match '^name:\s*(\S+)') { $agentName = $Matches[1]; break }
        }
        $midDot = [char]0x00B7
        # Defense-in-depth (advies Sean): de naam belandt in het geschreven sjabloon -- beperk hem
        # tot een veilige tekenset, ook al is de bron een plugin uit dezelfde vertrouwensgrens.
        $agentName = $agentName -replace '[^A-Za-z0-9_-]', ''
        if ($agentName) { $displayName = $agentName.Substring(0,1).ToUpper() + $agentName.Substring(1) } else { $displayName = "$group-$id" }
        $template = @"
---
id: $id
group: $group
---

# $displayName $midDot repo-lens (VUL-IN)

> Repo-lens bij het draagbare vakboek van $displayName in de ``$pluginName``-plugin. Dit bestand is
> door ``specialists-init`` als leeg sjabloon neergezet; de agent-def leest het automatisch mee.
> Vul hieronder de repo-specifieke taken en context aan die $displayName in deze repo nodig heeft.

## Eigen aan deze repo (VUL-IN)

<!-- TODO: beschrijf hier wat deze specialist in DEZE repo doet:
     - welke bestanden/mappen zijn of haar domein zijn;
     - de repo-specifieke taken, conventies en afspraken;
     - verwijzingen naar de safety-rules/poortwachters van deze repo.
     Het draagbare vak blijft in de plugin-manual; alleen repo-eigen zaken horen hier. -->
"@
        [System.IO.File]::WriteAllText($dest, $template, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "  [maak]  lens-scaffold .claude/extensions/$group-$id-extension.md ($displayName, $pluginName)" -ForegroundColor Green
        $script:scaffolded++
    }
}

# --- 2. De @-import onderaan CLAUDE.md --------------------------------------------------------------
$importLine = '@.claude/extensions/01-01-extension.md'
$claudeMd = Join-Path $ConsumerRoot 'CLAUDE.md'
$importBlock = @"

De orchestrator (Chris) wordt altijd meegeladen; hij verwijst on-demand door naar de specialisten
in [``.claude/extensions/``](.claude/extensions/).

$importLine
"@

if (-not (Test-Path -LiteralPath $claudeMd -PathType Leaf)) {
    $scaffold = @"
# CLAUDE.md

Deze repo wordt bestuurd door de **Claude Specialists** -- een team gespecialiseerde Claudes onder
een Chief of Staff. Deze scaffold is door de ``specialists-init``-skill neergezet; vul hem aan met de
governance en safety-rules van deze repo.
$importBlock
"@
    [System.IO.File]::WriteAllText($claudeMd, $scaffold, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  [maak]  CLAUDE.md-scaffold aangemaakt met de orchestrator-import." -ForegroundColor Green
} else {
    $md = [System.IO.File]::ReadAllText($claudeMd, [System.Text.Encoding]::UTF8)
    if ($md -match [regex]::Escape($importLine)) {
        Write-Host "  [houd]  CLAUDE.md heeft de orchestrator-import al." -ForegroundColor DarkGray
    } else {
        $md = $md.TrimEnd() + "`n" + $importBlock + "`n"
        [System.IO.File]::WriteAllText($claudeMd, $md, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "  [voeg]  orchestrator-import toegevoegd onderaan CLAUDE.md." -ForegroundColor Green
    }
}

# --- 3. Settings-/hooks-voorstel (raakt settings.json NIET aan) -------------------------------------
$claudeDir = Join-Path $ConsumerRoot '.claude'
if (-not (Test-Path -LiteralPath $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }
$suggestPath = Join-Path $claudeDir 'settings.suggested.jsonc'
$suggestion = @'
// VOORSTEL -- door specialists-init neergezet. Dit is GEEN actieve config.
// Neem de blokken die je wilt over in .claude/settings.json (of settings.local.json) en verwijder
// daarna dit bestand. De hooks zijn een STUB: hun scripts zijn repo-specifiek en bestaan hier nog
// niet -- vervang ze door de guards/lints die bij deze repo passen (of laat ze weg).
{
  // Governance: blokkeer de destructieve git-acties die de safety-rules verbieden.
  "permissions": {
    "deny": [
      "Bash(git push --force:*)",
      "Bash(git push -f:*)",
      "Bash(git reset --hard:*)",
      "Bash(git rebase:*)",
      "Bash(rm -rf:*)"
    ]
  },
  // Safety-hooks: STUB. Wijs naar echte scripts in deze repo (bv. scripts/maintenance/*.ps1) of
  // verwijder wat je niet gebruikt. Voorbeeld: een Stop-hook die op wijzigingen een lint draait.
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command",
          "command": "powershell -NoProfile -File scripts/maintenance/lint-changed-hook.ps1",
          "timeout": 30 } ] }
    ]
  }
}
'@
[System.IO.File]::WriteAllText($suggestPath, $suggestion, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "  [maak]  .claude/settings.suggested.jsonc neergezet (voorstel -- niet actief)." -ForegroundColor Green

# --- Rapport ----------------------------------------------------------------------------------------
Write-Host ""
Write-Host "Klaar: $copied persona('s) gekopieerd, $kept al aanwezig; $scaffolded lens-scaffold(s) neergezet, $lensKept al aanwezig." -ForegroundColor Cyan
Write-Host "Volgende stappen (handmatig -- dit script raakt settings.json/hooks bewust niet aan):" -ForegroundColor Cyan
Write-Host "  1. Vul in elk .claude/extensions/*-extension.md het '## Eigen aan deze repo'-slot met de repo-lens (de VUL-IN-scaffolds mogen leeg blijven tot een specialist hier echt werk krijgt)." -ForegroundColor Gray
Write-Host "  2. Neem uit .claude/settings.suggested.jsonc over wat je wilt in settings.json en verwijder het voorstel." -ForegroundColor Gray
Write-Host "  3. Herstart de Claude Code-sessie zodat de nieuwe @-import + config actief worden." -ForegroundColor Gray
exit 0
