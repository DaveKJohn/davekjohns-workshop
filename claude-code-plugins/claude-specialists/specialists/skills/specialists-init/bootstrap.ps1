<#
.SYNOPSIS
    Bootstrap-script van de specialists-init-skill: zet in een CONSUMERENDE repo de niet-plugin-laag
    van het Claude-Specialists-systeem op -- de orchestrator + hoofdloop-persona's (Chris/Derek/
    Rendall) via @-imports in CLAUDE.md, plus een gedocumenteerd settings-/hooks-voorstel.
.DESCRIPTION
    Een Claude Code-plugin kan subagents leveren, maar GEEN altijd-aan-hoofdloop-context injecteren
    en niet de CLAUDE.md van een consument bewerken. Chris (de orchestrator) is precies zulke
    hoofdloop-context: hij wordt geladen via een @-import onderaan de CLAUDE.md van de consument.
    Dit script vult dat gat. Het wordt door de skill aangeroepen NADAT de consument de
    marketplace-source + enabledPlugins al heeft ingesteld en de sessie is herstart (anders is de
    skill zelf nog niet beschikbaar -- de kip-en-ei die de skill in stap 0 documenteert).

    De repo-lenzen wonen op het PLUGIN-PAD (.claude/plugins/<familie>/<plugin>/, de standaard) en de
    persona-lenzen zijn LENS-ONLY: geen body-kopie, alleen het repo-eigen '## Eigen aan deze repo'-slot.
    De draagbare body komt via een @-import rechtstreeks uit de plugin-install (het ~/.claude/plugins/
    marketplaces/...-pad). Zo woont elke gedragsregel op een plek (de plugin), niet gedupliceerd.

    Het doet alleen VEILIGE, additieve handelingen -- het overschrijft nooit bestaande inhoud:
      1. Zet per persona (<plugin>/personas/<g>-<id>-persona.md) een LENS-ONLY extension neer in
         <ConsumerRoot>/.claude/plugins/<familie>/<plugin>/<g>-<id>-extension.md -- alleen als die nog
         niet bestaat. De body komt uit de plugin-install; de extension draagt enkel het repo-lens-slot.
      1b. Zet voor elke subagent van de INGESCHAKELDE plugin(s) (enabledPlugins in de settings van
          de consument; zonder settings alleen de eigen plugin) een lege lens-scaffold neer op het
          plugin-pad, duidelijk gemarkeerd als VUL-IN.
      1c. Zet de repo-eigen script-config-scaffolds neer die de gedeelde workflow-skills (open-pr /
          fold-changelog) nodig hebben: scripts/repo-config.ps1 (Get-RepoName / Get-RepoBlobUrl /
          Get-LintScript) en scripts/lib/branch-info.ps1 (de prefix-tabel). Beide als VUL-IN-scaffold
          met een LEGE branch-tabel -- de taxonomie is per repo anders. Zonder deze bestanden loopt
          een schone consument op een rauwe dot-source-fout (#86). Nooit overschrijven.
      2. Zorgt dat <ConsumerRoot>/CLAUDE.md onderaan de TWEE @-imports van de orchestrator draagt: de
         body uit de plugin-install (~/.claude/plugins/marketplaces/.../01-01-persona.md) en de
         repo-lens (.claude/plugins/<familie>/<plugin>/01-01-extension.md). Ontbreekt CLAUDE.md, dan
         schrijft het een minimale scaffold; bestaan de imports al, dan doet het niets.
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
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

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

# --- Familie/plugin + het ~-pad naar de plugin-install afleiden -------------------------------------
# personaDir = <...>/claude-code-plugins/<familie>/<plugin>/personas. Daaruit halen we de plugin die de
# persona's draagt en de familie-map -- die bepalen het plugin-pad in de consument
# (.claude/plugins/<familie>/<plugin>/). De draagbare body komt uit de plugin-install; als personaDir
# onder de gebruikers-home (~) valt (de normale marketplace-cache), drukken we dat pad als ~-pad uit
# voor de @-import in CLAUDE.md.
# github-source-cache: <...>/claude-code-plugins/<familie>/<plugin>/personas -> familie = segment na
# 'claude-code-plugins', plugin = het segment daarna. Fallback (versie-cache <...>/<plugin>/<versie>/
# personas): plugin = map boven personas (of boven de versie-map), familie = de map daarboven.
$segs = ($personaDir -replace '/', '\') -split '\\' | Where-Object { $_ }
$ccpIdx = [array]::IndexOf([string[]]$segs, 'claude-code-plugins')
if ($ccpIdx -ge 0 -and ($ccpIdx + 2) -lt $segs.Count) {
    $family        = $segs[$ccpIdx + 1]
    $personaPlugin = $segs[$ccpIdx + 2]
} else {
    $pdParent = Split-Path $personaDir -Parent
    if ((Split-Path $pdParent -Leaf) -match '^\d+\.\d+\.\d+') {
        $personaPlugin = Split-Path (Split-Path $pdParent -Parent) -Leaf
        $family        = Split-Path (Split-Path (Split-Path $pdParent -Parent) -Parent) -Leaf
    } else {
        $personaPlugin = Split-Path $pdParent -Leaf
        $family        = Split-Path (Split-Path $pdParent -Parent) -Leaf
    }
}
# Durabel body-pad: de geschreven @-import mag NOOIT naar de versie-gepinde cache wijzen. De cache
# (~/.claude/plugins/cache/<marketplace>/<plugin>/<versie>/) is ephemeer -- na een plugin-update wordt
# de oude versie-map opgeruimd (~7 dagen) en breekt een import die erheen wees; de body van de
# orchestrator laadt dan niet meer. De marketplaces-clone (~/.claude/plugins/marketplaces/<marketplace>/)
# is versie-loos en wordt bij update gepulld: dat is het durabele anker. @-imports kennen GEEN
# variabele-expansie (${CLAUDE_PLUGIN_ROOT} e.d. werken daar niet), dus we schrijven een vast,
# versie-loos pad. Draait de bootstrap al vanuit de marketplaces-clone of een niet-cache-locatie
# (bv. de bron-repo die zichzelf consumeert), dan is $personaDir al durabel en verandert er niets.
function Get-DurablePersonaDir([string]$PersonaDir, [string]$Plugin) {
    $parts = ($PersonaDir -replace '/', '\') -split '\\' | Where-Object { $_ }
    $cacheIdx = [array]::IndexOf([string[]]$parts, 'cache')
    # Alleen ingrijpen op de echte cache-layout .../plugins/cache/<mp>/<plugin>/<versie>/personas.
    if ($cacheIdx -lt 1 -or ($cacheIdx + 1) -ge $parts.Count) { return $PersonaDir }
    if ($parts[$cacheIdx - 1] -ne 'plugins') { return $PersonaDir }
    $marketplace = $parts[$cacheIdx + 1]
    if ($marketplace -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { return $PersonaDir }
    $clone = Join-Path (($parts[0..($cacheIdx - 1)] -join '\')) (Join-Path 'marketplaces' $marketplace)
    if (-not (Test-Path -LiteralPath $clone -PathType Container)) { return $PersonaDir }
    # Zoek in de clone de personas-map onder een map die exact zo heet als de plugin en die de
    # orchestrator-body draagt (01-01-persona.md is de import-target -- die moet er echt zijn).
    $hit = Get-ChildItem -LiteralPath $clone -Recurse -Directory -Filter 'personas' -ErrorAction SilentlyContinue |
        Where-Object {
            (Split-Path $_.Parent.FullName -Leaf) -eq $Plugin -and
            (Test-Path -LiteralPath (Join-Path $_.FullName '01-01-persona.md'))
        } | Select-Object -First 1
    if ($hit) { return $hit.FullName }
    return $PersonaDir
}
$durablePersonaDir = Get-DurablePersonaDir -PersonaDir $personaDir -Plugin $personaPlugin

$homeDir = $HOME
if ($durablePersonaDir.StartsWith($homeDir, [System.StringComparison]::OrdinalIgnoreCase)) {
    $personaTilde = '~' + $durablePersonaDir.Substring($homeDir.Length)
} else {
    $personaTilde = $durablePersonaDir
}
$personaTilde = $personaTilde -replace '\\', '/'

# Plugin-pad in de consument (de standaard-locatie voor de lenzen).
$padRel = ".claude/plugins/$family"
$padDirRoot = Join-Path $ConsumerRoot (".claude\plugins\$family")

Write-Host "== specialists-init bootstrap -- $ConsumerRoot ==" -ForegroundColor Cyan

# --- 1. Persona-lenzen (LENS-ONLY) naar het plugin-pad (nooit overschrijven) ------------------------
$personaDest = Join-Path $padDirRoot $personaPlugin
if (-not (Test-Path -LiteralPath $personaDest)) { New-Item -ItemType Directory -Path $personaDest -Force | Out-Null }

$copied = 0; $kept = 0
Get-ChildItem -Path $personaDir -Filter '*-persona.md' -File | Sort-Object Name | ForEach-Object {
    if ($_.BaseName -notmatch '^(\d{2})-(\d{2})-persona$') { return }
    $g = $Matches[1]; $id = $Matches[2]
    $dest = Join-Path $personaDest "$g-$id-extension.md"
    if (Test-Path -LiteralPath $dest -PathType Leaf) {
        Write-Host "  [houd]  $(Split-Path $dest -Leaf) bestaat al -- niet overschreven." -ForegroundColor DarkGray
        $script:kept++
        return
    }
    # Titel (de eerste #-kop) uit het sjabloon halen; de body zelf kopieren we NIET (lens-only).
    # Als UTF8 lezen -- de titel bevat een emoji en em-dash die anders mojibake worden.
    $title = ''
    foreach ($line in (([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)) -split "`r?`n")) {
        if ($line -match '^#\s') { $title = $line.TrimEnd(); break }
    }
    if (-not $title) { $title = "# $g-$id" }
    $bodyPath = "$personaTilde/$($_.Name)"
    if ($g -eq '01' -and $id -eq '01') {
        $loadNote = 'Chris laadt zijn body automatisch via de `@`-import onderaan `CLAUDE.md`; de andere persona''s worden on-demand van dit pad gelezen.'
    } else {
        $loadNote = 'De body wordt on-demand uit dit pad gelezen wanneer Chris deze persona erbij haalt (geen vaste `@`-import).'
    }
    $content = @"
---
id: $id
group: $g
---

$title

> Repo-lens (lens-only persona) -- de draagbare body woont in de plugin-bron:
> ``$bodyPath``.
> $loadNote

## Eigen aan deze repo (VUL-IN)

<!-- TODO (in te vullen na bootstrap): vervang deze placeholder door de repo-lens van deze
     specialist -- wie hij of zij in DEZE repo aanstuurt of bedient en langs welke afspraken:
     het team en de routing, de ketens en de poortwachters (de safety-rules, de branch-discipline
     en de PR-regel; verwijs naar de repo-CLAUDE.md#safety-rules). Het draagbare vak blijft in de
     plugin-persona; alleen repo-eigen zaken horen hier. -->
"@
    [System.IO.File]::WriteAllText($dest, ($content.TrimEnd() + "`n"), $Utf8NoBom)
    Write-Host "  [maak]  lens-only $padRel/$personaPlugin/$(Split-Path $dest -Leaf)" -ForegroundColor Green
    $script:copied++
}

# --- 1b. Lege lens-scaffolds voor de subagent-specialisten (nooit overschrijven) --------------------
# De agent-defs komen uit de plugin(s); de repo-lens per specialist woont op het plugin-pad van de
# consument. Voor elke agent van de ingeschakelde plugin(s) zetten we een lege, gemarkeerde scaffold neer.

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
    $pluginPad = Join-Path $padDirRoot $pluginName
    if (-not (Test-Path -LiteralPath $pluginPad)) { New-Item -ItemType Directory -Path $pluginPad -Force | Out-Null }
    Get-ChildItem -Path $agentsDir -Filter '*-agent.md' -File | Sort-Object Name | ForEach-Object {
        if ($_.BaseName -notmatch '^(\d{2})-(\d{2})-agent$') { return }
        $group = $Matches[1]; $id = $Matches[2]
        $dest = Join-Path $pluginPad "$group-$id-extension.md"
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
        [System.IO.File]::WriteAllText($dest, $template, $Utf8NoBom)
        Write-Host "  [maak]  lens-scaffold $padRel/$pluginName/$group-$id-extension.md ($displayName)" -ForegroundColor Green
        $script:scaffolded++
    }
}

# --- 1c. Repo-eigen script-config scaffolds (nooit overschrijven) -----------------------------------
# De gedeelde skills open-pr/fold-changelog leunen op twee repo-eigen bestanden in de repo-root van de
# consument (scripts/repo-config.ps1 + scripts/lib/branch-info.ps1). Zonder die loopt een schone
# consument op een rauwe dot-source-fout (#86). specialists-init zet ze hier als VUL-IN-scaffold neer:
# repo-agnostische structuur met lege plekken om zelf in te vullen. De branch-taxonomie is per repo
# anders en blijft dus bewust een LEGE tabel -- nooit de taxonomie van een andere repo.
$repoConfigScaffold = @'
<#
.SYNOPSIS
    Repo-eigen configuratie voor de gedeelde workflow-scripts (open-pr / fold-changelog).
.DESCRIPTION
    Door specialists-init als VUL-IN-scaffold neergezet. De gedeelde skills lezen dit kleine blokje
    repo-data uit de repo-root; de scripts zelf zijn repo-agnostisch. Vul de resterende VUL-IN-waarden
    hieronder in en verwijder hun VUL-IN-markeringen. RepoName wordt door de bootstrap automatisch
    uit de git-remote (origin) afgeleid als die een github.com-adres heeft; anders blijft hij VUL-IN.

    Geen Set-StrictMode hier: dot-sourcen zou de strict-mode van het aanroepende script veranderen.
    Puur ASCII (repo-conventie voor .ps1): Windows PowerShell 5.1 leest een BOM-loos script als ANSI.
#>

# VUL-IN: de GitHub-repo waar deze repo woont (owner/naam), bv. 'DaveKJohn/mijn-repo'.
$script:RepoName = 'VUL-IN/repo'

function Get-RepoName {
    return $script:RepoName
}

function Get-RepoBlobUrl {
    return "https://github.com/$($script:RepoName)/blob/main/"
}

# VUL-IN: repo-root-relatief pad naar de lint-poort die open-pr voor de PR draait,
# bv. 'scripts\lint\check-plugin-integrity.ps1' of 'scripts\maintenance\lint-brain.ps1'.
$script:LintScript = 'VUL-IN'

function Get-LintScript {
    return $script:LintScript
}
'@

$branchInfoScaffold = @'
<#
.SYNOPSIS
    Gedeelde branch-conventies voor de workflow-scripts (repo-eigen prefix-tabel).
.DESCRIPTION
    Door specialists-init als VUL-IN-scaffold neergezet. Levert Get-BranchTypes, Get-BranchPrefix en
    Get-BranchInfo. De prefix-tabel bepaalt het GitHub-label van de PR en het changelog-entry-type en
    is PER REPO anders -- vul hieronder je eigen branch-taxonomie in (de tabel is bewust leeg).

    Geen Set-StrictMode hier: dot-sourcen zou de strict-mode van het aanroepende script veranderen.
    Puur ASCII (repo-conventie voor .ps1).
#>

# VUL-IN: de canonieke branch-typen in release-notes-volgorde, bv. @('Feat', 'Fix', 'Docs', 'Chore').
$script:BranchTypeOrder = @()

# VUL-IN: prefix -> GitHub-label (PR) + branch-type (changelog-entry). Voorbeeld:
#   feat  = @{ Label = 'enhancement';   Type = 'Feat' }
#   fix   = @{ Label = 'bug';           Type = 'Fix' }
#   docs  = @{ Label = 'documentation'; Type = 'Docs' }
#   chore = @{ Label = 'documentation'; Type = 'Chore' }
$script:BranchPrefixTable = @{
}

function Get-BranchTypes {
    return $script:BranchTypeOrder
}

function Get-BranchPrefix {
    param([Parameter(Mandatory = $true)][string]$Branch)
    if ($Branch -match '/') { return ($Branch -split '/')[0] }
    return ($Branch -split '-')[0]
}

function Get-BranchInfo {
    param([Parameter(Mandatory = $true)][string]$Branch)
    $prefix = Get-BranchPrefix -Branch $Branch
    $known  = $script:BranchPrefixTable.ContainsKey($prefix)
    [pscustomobject]@{
        Branch   = $Branch
        Prefix   = $prefix
        IsKnown  = $known
        Label    = $(if ($known) { $script:BranchPrefixTable[$prefix].Label } else { $null })
        Type     = $(if ($known) { $script:BranchPrefixTable[$prefix].Type } else { $null })
        SafeName = $Branch -replace '/', '-'
    }
}
'@

# Repo-naam afleiden uit de git-remote van de consument (ergonomie): zo hoeft niemand RepoName nog
# met de hand in te vullen. De remote-URL is externe input die in een geschreven .ps1 belandt en later
# in `gh --repo` wordt gebruikt -- dus streng valideren (advies Sean) en bij elke twijfel terugvallen op
# de VUL-IN-placeholder. De git-aanroep mag de bootstrap nooit laten crashen (geen git/geen origin ->
# gewoon terugval), dus de hele afleiding zit in een try/catch.
# Bewust `git config --get remote.origin.url` en NIET `git remote get-url`: dat laatste past
# `insteadOf`-herschrijvingen toe (CI-runners en sommige dev-machines zetten die globaal, bv.
# git@github.com: -> https), waardoor de teruggegeven vorm onvoorspelbaar wordt. `config --get` geeft
# de RAUWE opgeslagen origin -- exact wat de consument configureerde, immuun voor insteadOf.
function Get-DerivedRepoName([string]$Root) {
    try {
        $url = (& git -C $Root config --get remote.origin.url 2>$null | Select-Object -First 1)
    } catch {
        return $null
    }
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($url)) { return $null }
    # Alleen github.com; alle gangbare vormen (https/ssh/git-scheme + de scp-achtige git@github.com:).
    # owner/repo als strikte slug; .git-suffix en trailing slash eraf. De scheme-vormen mogen optionele
    # userinfo dragen (bv. 'x-access-token:TOKEN@' -- zo herschrijft een git insteadOf-regel een remote,
    # en zo ziet een consument met credentials in de origin-URL eruit); die userinfo wordt bewust NIET
    # gevangen -- alleen owner/repo. Userinfo kan geen '/' bevatten, dus een 'evil.com/x@github.com'-
    # spoof matcht niet.
    $m = [regex]::Match($url.Trim(), '^(?:(?:https|ssh|git)://(?:[^/@]+@)?github\.com/|git@github\.com:)(?<owner>[A-Za-z0-9][A-Za-z0-9._-]*)/(?<repo>[A-Za-z0-9][A-Za-z0-9._-]*?)(?:\.git)?/?$')
    if (-not $m.Success) { return $null }
    return "$($m.Groups['owner'].Value)/$($m.Groups['repo'].Value)"
}

# Afgeleide naam in de repo-config-scaffold zetten (voor $scriptScaffolds wordt opgebouwd, zodat de
# nieuwe inhoud meegaat). Lukt de afleiding niet, dan blijft de VUL-IN-placeholder staan.
$derivedRepo = Get-DerivedRepoName $ConsumerRoot
if ($derivedRepo) {
    $repoConfigScaffold = $repoConfigScaffold.Replace(
        "# VUL-IN: de GitHub-repo waar deze repo woont (owner/naam), bv. 'DaveKJohn/mijn-repo'.",
        "# Door specialists-init afgeleid uit de git-remote (origin) van deze repo. Klopt dit niet, pas hem dan aan.")
    $repoConfigScaffold = $repoConfigScaffold.Replace(
        "`$script:RepoName = 'VUL-IN/repo'",
        "`$script:RepoName = '$derivedRepo'")
}

$scriptScaffolds = @(
    @{ Rel = 'scripts\repo-config.ps1';     Content = $repoConfigScaffold }
    @{ Rel = 'scripts\lib\branch-info.ps1'; Content = $branchInfoScaffold }
)
$scriptScaffolded = 0; $scriptKept = 0
$repoConfigDerived = $false
foreach ($s in $scriptScaffolds) {
    $dest = Join-Path $ConsumerRoot $s.Rel
    $relDisplay = $s.Rel -replace '\\', '/'
    if (Test-Path -LiteralPath $dest -PathType Leaf) {
        Write-Host "  [houd]  $relDisplay bestaat al -- niet overschreven." -ForegroundColor DarkGray
        $scriptKept++
        continue
    }
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    [System.IO.File]::WriteAllText($dest, ($s.Content.TrimEnd() + "`n"), $Utf8NoBom)
    $note = ''
    if ($s.Rel -eq 'scripts\repo-config.ps1' -and $derivedRepo) {
        $note = " (RepoName afgeleid: $derivedRepo)"
        $repoConfigDerived = $true
    }
    Write-Host "  [maak]  script-scaffold $relDisplay$note" -ForegroundColor Green
    $scriptScaffolded++
}

# --- 2. De twee @-imports onderaan CLAUDE.md (body uit de plugin + de repo-lens) --------------------
$bodyImport = "@$personaTilde/01-01-persona.md"
$lensImport = "@$padRel/$personaPlugin/01-01-extension.md"
$claudeMd = Join-Path $ConsumerRoot 'CLAUDE.md'
$importBlock = @"

De orchestrator (Chris) wordt altijd meegeladen -- zijn draagbare body uit de plugin-install en zijn
repo-lens uit het plugin-pad; hij verwijst on-demand door naar de specialisten in ``$padRel/``.

$bodyImport

$lensImport
"@

if (-not (Test-Path -LiteralPath $claudeMd -PathType Leaf)) {
    $scaffold = @"
# CLAUDE.md

Deze repo wordt bestuurd door de **Claude Specialists** -- een team gespecialiseerde Claudes onder
een Chief of Staff. Deze scaffold is door de ``specialists-init``-skill neergezet; vul hem aan met de
governance en safety-rules van deze repo.
$importBlock
"@
    [System.IO.File]::WriteAllText($claudeMd, $scaffold, $Utf8NoBom)
    Write-Host "  [maak]  CLAUDE.md-scaffold aangemaakt met de orchestrator-imports." -ForegroundColor Green
} else {
    $md = [System.IO.File]::ReadAllText($claudeMd, [System.Text.Encoding]::UTF8)
    if ($md -match [regex]::Escape($lensImport)) {
        Write-Host "  [houd]  CLAUDE.md heeft de orchestrator-imports al." -ForegroundColor DarkGray
    } else {
        $md = $md.TrimEnd() + "`n" + $importBlock + "`n"
        [System.IO.File]::WriteAllText($claudeMd, $md, $Utf8NoBom)
        Write-Host "  [voeg]  orchestrator-imports toegevoegd onderaan CLAUDE.md." -ForegroundColor Green
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
[System.IO.File]::WriteAllText($suggestPath, $suggestion, $Utf8NoBom)
Write-Host "  [maak]  .claude/settings.suggested.jsonc neergezet (voorstel -- niet actief)." -ForegroundColor Green

# --- Rapport ----------------------------------------------------------------------------------------
Write-Host ""
Write-Host "Klaar: $copied persona-lens(en) neergezet, $kept al aanwezig; $scaffolded lens-scaffold(s) neergezet, $lensKept al aanwezig; $scriptScaffolded script-scaffold(s) neergezet, $scriptKept al aanwezig." -ForegroundColor Cyan
Write-Host "Volgende stappen (handmatig -- dit script raakt settings.json/hooks bewust niet aan):" -ForegroundColor Cyan
Write-Host "  1. Vul in elk $padRel/*/*-extension.md het '## Eigen aan deze repo'-slot met de repo-lens (de VUL-IN-scaffolds mogen leeg blijven tot een specialist hier echt werk krijgt)." -ForegroundColor Gray
if ($repoConfigDerived) {
    Write-Host "  2. Wil je de gedeelde workflow-skills (open-pr / fold-changelog) gebruiken? RepoName is al uit de git-remote afgeleid ($derivedRepo) -- vul in scripts/repo-config.ps1 nog Get-LintScript in en in scripts/lib/branch-info.ps1 je branch-prefix-tabel." -ForegroundColor Gray
} else {
    Write-Host "  2. Wil je de gedeelde workflow-skills (open-pr / fold-changelog) gebruiken? Vul dan scripts/repo-config.ps1 (RepoName + LintScript) en scripts/lib/branch-info.ps1 (je branch-prefix-tabel) in -- de VUL-IN-scaffolds staan klaar." -ForegroundColor Gray
}
Write-Host "  3. Neem uit .claude/settings.suggested.jsonc over wat je wilt in settings.json en verwijder het voorstel." -ForegroundColor Gray
Write-Host "  4. Herstart de Claude Code-sessie zodat de nieuwe @-imports + config actief worden." -ForegroundColor Gray
exit 0
