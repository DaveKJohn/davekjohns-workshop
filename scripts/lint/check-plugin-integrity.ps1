<#
.SYNOPSIS
    Integriteitscheck voor de davekjohns-workshop-marketplace: valideert de manifesten, de
    agent-def-frontmatter en de interne links voordat een wijziging via een PR op main belandt.
.DESCRIPTION
    De lint-poort van dit repo (aangeroepen door scripts/release/open-pr.ps1). Read-only -- wijzigt
    niets. Controleert het volgende; elke bevinding is een error:

      1. .claude-plugin/marketplace.json: geldige JSON; elke plugins[].source verwijst naar een
         bestaande map met een .claude-plugin/plugin.json.
      2. elke <plugin>/.claude-plugin/plugin.json: geldige JSON met een niet-lege 'name'.
      3. elke <plugin>/agents/*.md: frontmatter bevat 'name:', 'id:' en 'group:'.
      3b. elke <plugin>/manuals/*-manual.md: frontmatter bevat 'id:' en 'group:', en de bestandsnaam
         <group>-<id>-manual.md komt overeen met die frontmatter (het draagbare vakboek dat de
         bijbehorende agent-def via ${CLAUDE_PLUGIN_ROOT}/manuals/ inleest).
      3c. elke <plugin>/personas/*-persona.md: frontmatter bevat 'id:' en 'group:', en de bestandsnaam
         <group>-<id>-persona.md komt overeen met die frontmatter. Persona's (orchestrator +
         hoofdloop-specialisten) hebben BEWUST geen agent-def -- ze draaien in de hoofdloop, niet als
         subagent -- en worden daarom door de agent-def<->manual-koppeling van check 6 met rust gelaten.
      4. dode relatieve links EN kapotte anchors in README.md, CHANGELOG.md, CLAUDE.md, elke
         .claude/extensions/*.md, elke <plugin>/skills/*/SKILL.md, elke <plugin>/manuals/*-manual.md,
         elke <plugin>/personas/*-persona.md, elke releases/**/*.md, elke <plugin>/RELEASE.md,
         claude-code-plugins/claude-specialists/README.md (de family-README) en QUICKSTART.md, en
         elke plugin-eigen claude-code-plugins/claude-specialists/<plugin>/CHANGELOG.md (#103).
         Gecontroleerd: (a) het gelinkte
         bestand bestaat, en (b) als de link
         een #anchor heeft, dat die anchor als kop bestaat in het doelbestand (GitHub-slugregels).
         Externe http(s)-/mailto-links worden overgeslagen.
      5. elke scripts/**/*.ps1 parseert foutloos (vangt syntaxfouten in de orkestratie zelf, die pas
         bij uitvoering zouden breken).
      6. specialisten-systeem-integriteit: per plugin is elk '<group>-<id>' uniek over de agent-defs,
         heeft elke agent-def een geldige 'name:' + een bijbehorende manuals/<g>-<id>-manual.md die
         hij ook noemt, en heeft elke manual omgekeerd een agent-def (geen wees-manual).
      7. gedeelde agent-def-blokken: elke <!-- BEGIN/END shared:NAME -->-regio in een agent-def is nog
         gelijk aan zijn canonieke bron in agent-shared/<naam>.md (zie scripts/agents/build-agent-defs.ps1)
         -- een hand-edit binnen de sentinels of een vergeten rebuild valt zo op de poort.
      8. gedeelde workflow-scripts: elke plugin-spiegel van een repo-agnostisch script (issue #81) is
         nog LF-identiek aan zijn root-bron -- een hand-edit in de spiegel of een vergeten
         scripts/sync/build-shared-scripts.ps1 valt zo op de poort.
      9. RELEASE.md per plugin (Model A, plugin-gedragen): elke plugin-map heeft een RELEASE.md, en de
         'vX.Y.Z' die daarin staat is gelijk aan de 'version' in die plugin's plugin.json. Alleen
         cut-release.ps1 wijzigt beide bestanden samen, dus een gewone feature-PR kan hier nooit op
         vallen -- een mismatch/ontbrekend bestand betekent dat het kaartje niet is (her)gegenereerd.

    Exit-code: 0 = geen errors. 1 = minstens een error (bruikbaar als poort in open-pr.ps1).
.EXAMPLE
    ./scripts/lint/check-plugin-integrity.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$errors = New-Object System.Collections.Generic.List[string]

function Add-Error([string]$Msg) { $script:errors.Add($Msg) }

function Test-JsonFile {
    param([string]$Path)
    try {
        $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        return ($raw | ConvertFrom-Json)
    } catch {
        Add-Error "[JSON] $($Path.Replace($RepoRoot, '.')) is geen geldige JSON: $($_.Exception.Message)"
        return $null
    }
}

Write-Host "== check-plugin-integrity -- $RepoRoot ==" -ForegroundColor Cyan

# --- 1. marketplace.json + de plugins waarnaar het verwijst -----------------------------------------
$marketplacePath = Join-Path $RepoRoot '.claude-plugin\marketplace.json'
if (-not (Test-Path -LiteralPath $marketplacePath)) {
    Add-Error "[marketplace] .claude-plugin/marketplace.json ontbreekt."
} else {
    $mp = Test-JsonFile -Path $marketplacePath
    if ($mp) {
        if (-not ($mp.PSObject.Properties.Name -contains 'plugins') -or -not $mp.plugins) {
            Add-Error "[marketplace] marketplace.json heeft geen 'plugins'-lijst."
        } else {
            # Containment (advies Sean): een source die via een absoluut of ..-pad buiten de
            # repo wijst, is altijd fout -- wat hier geregistreerd staat, wordt gepubliceerd.
            # Bewust gespiegeld aan Get-PluginManifestPaths in scripts/lib/release-lib.ps1 (die
            # gooit; deze lint verzamelt) -- wijzig je de containment-regel, wijzig dan beide.
            $rootPrefix = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') + '\'
            foreach ($p in $mp.plugins) {
                $src = $p.source
                if (-not $src) { Add-Error "[marketplace] plugin '$($p.name)' mist een 'source'."; continue }
                $pluginDir = (Join-Path $RepoRoot ($src -replace '/', '\')).TrimEnd('\')
                $resolvedDir = $null
                try { $resolvedDir = [System.IO.Path]::GetFullPath($pluginDir) } catch {}
                if (-not $resolvedDir -or -not ($resolvedDir + '\').StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    Add-Error "[marketplace] plugin '$($p.name)': source '$src' wijst buiten de repo."
                } elseif (-not (Test-Path -LiteralPath $pluginDir -PathType Container)) {
                    Add-Error "[marketplace] plugin '$($p.name)': source-map '$src' bestaat niet."
                } elseif (-not (Test-Path -LiteralPath (Join-Path $pluginDir '.claude-plugin\plugin.json'))) {
                    Add-Error "[marketplace] plugin '$($p.name)': '$src' bevat geen .claude-plugin/plugin.json."
                }
            }
        }
    }
}

# --- 2. elke plugin.json: geldige JSON met een name -------------------------------------------------
Get-ChildItem -Path $RepoRoot -Recurse -Filter 'plugin.json' -File |
    Where-Object { $_.FullName -match '\.claude-plugin\\plugin\.json$' } | ForEach-Object {
        $pj = Test-JsonFile -Path $_.FullName
        if ($pj -and (-not ($pj.PSObject.Properties.Name -contains 'name') -or -not $pj.name)) {
            Add-Error "[plugin] $($_.FullName.Replace($RepoRoot, '.')) mist een niet-lege 'name'."
        }
    }

# --- 3. agent-def-frontmatter: name/id/group --------------------------------------------------------
Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-agent.md' -File |
    Where-Object { $_.FullName -match '\\agents\\' } | ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        foreach ($key in 'name', 'id', 'group') {
            if (-not [regex]::IsMatch($text, "(?m)^$key`:\s*\S")) {
                Add-Error "[agent-def] $rel mist '$key`:' in de frontmatter."
            }
        }
    }

# --- 3b. manual-frontmatter: id/group + bestandsnaam <group>-<id>-manual.md -------------------------
Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-manual.md' -File |
    Where-Object { $_.FullName -match '\\manuals\\' } | ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        foreach ($key in 'id', 'group') {
            if (-not [regex]::IsMatch($text, "(?m)^$key`:\s*\S")) {
                Add-Error "[manual] $rel mist '$key`:' in de frontmatter."
            }
        }
        if ($_.BaseName -match '^(\d{2})-(\d{2})-manual$') {
            $fnG = $Matches[1]; $fnI = $Matches[2]
            $mI = [regex]::Match($text, '(?m)^id:\s*(\S+)\s*$')
            $mG = [regex]::Match($text, '(?m)^group:\s*(\S+)\s*$')
            if ($mI.Success -and $mI.Groups[1].Value.Trim() -ne $fnI) {
                Add-Error "[manual] $rel`: bestandsnaam-id '$fnI' != frontmatter 'id: $($mI.Groups[1].Value.Trim())'."
            }
            if ($mG.Success -and $mG.Groups[1].Value.Trim() -ne $fnG) {
                Add-Error "[manual] $rel`: bestandsnaam-group '$fnG' != frontmatter 'group: $($mG.Groups[1].Value.Trim())'."
            }
        } else {
            Add-Error "[manual] $rel`: bestandsnaam volgt niet het <group>-<id>-manual-patroon."
        }
    }

# --- 3c. persona-frontmatter: id/group + bestandsnaam <group>-<id>-persona.md -----------------------
# Persona's (Chris/Derek/Rendall e.d.) draaien in de HOOFDLOOP, niet als subagent, dus ze hebben
# bewust geen agent-def. Ze wonen in <plugin>/personas/ als draagbaar sjabloon dat de bootstrap-skill
# naar de repo-laag (.claude/extensions/<g>-<id>-extension.md) van een consument kopieert. Check 6
# (agent-def<->manual-koppeling) negeert ze daarom; hier valideren we hun frontmatter + bestandsnaam
# op zichzelf (spiegelt 3b).
Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-persona.md' -File |
    Where-Object { $_.FullName -match '\\personas\\' } | ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        foreach ($key in 'id', 'group') {
            if (-not [regex]::IsMatch($text, "(?m)^$key`:\s*\S")) {
                Add-Error "[persona] $rel mist '$key`:' in de frontmatter."
            }
        }
        if ($_.BaseName -match '^(\d{2})-(\d{2})-persona$') {
            $fnG = $Matches[1]; $fnI = $Matches[2]
            $mI = [regex]::Match($text, '(?m)^id:\s*(\S+)\s*$')
            $mG = [regex]::Match($text, '(?m)^group:\s*(\S+)\s*$')
            if ($mI.Success -and $mI.Groups[1].Value.Trim() -ne $fnI) {
                Add-Error "[persona] $rel`: bestandsnaam-id '$fnI' != frontmatter 'id: $($mI.Groups[1].Value.Trim())'."
            }
            if ($mG.Success -and $mG.Groups[1].Value.Trim() -ne $fnG) {
                Add-Error "[persona] $rel`: bestandsnaam-group '$fnG' != frontmatter 'group: $($mG.Groups[1].Value.Trim())'."
            }
        } else {
            Add-Error "[persona] $rel`: bestandsnaam volgt niet het <group>-<id>-persona-patroon."
        }
    }

# --- 4. dode relatieve links + kapotte anchors ------------------------------------------------------
# Gescande bestanden: README.md, CHANGELOG.md, CLAUDE.md, elke .claude/extensions/*.md, elke
# <plugin>/skills/*/SKILL.md, elke <plugin>/manuals/*-manual.md en elke releases/**/*.md. Voor elke
# relatieve link wordt gecontroleerd (a) dat het gelinkte bestand bestaat, en (b) als de link een
# #anchor heeft: dat die anchor als kop bestaat in het doelbestand (GitHub-slugregels). Externe
# http(s)-/mailto-links worden overgeslagen.

function ConvertTo-GhSlug {
    # Zet een kop-tekst om naar een GitHub-anchor-slug.
    param([string]$Text)
    $t = [regex]::Replace($Text, '\[([^\]]*)\]\([^)]*\)', '$1')  # [tekst](url) -> tekst
    $t = $t -replace '[`*_]', ''                                  # inline code/emphasis-markers weg
    $t = $t.ToLowerInvariant()
    $t = [regex]::Replace($t, '[^\p{L}\p{N} \-]', '')             # alleen letter/cijfer/spatie/hyphen
    $t = $t.Trim() -replace ' ', '-'
    return $t
}

function Get-HeadingSlugs {
    # Verzamelt de anchor-slugs van alle koppen in een markdown-bestand (met GitHub-duplicaatsuffixen).
    param([string]$Path)
    $slugs = New-Object System.Collections.Generic.HashSet[string]
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $slugs }
    $lines = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) -split "`r?`n"
    $counts = @{}
    $inFence = $false
    foreach ($line in $lines) {
        if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        if ($line -match '^#{1,6}\s+(.*)$') {
            $base = ConvertTo-GhSlug -Text $Matches[1]
            if (-not $base) { continue }
            if (-not $counts.ContainsKey($base)) { $counts[$base] = 0; $slug = $base }
            else { $counts[$base] = $counts[$base] + 1; $slug = "$base-$($counts[$base])" }
            [void]$slugs.Add($slug)
        }
    }
    return $slugs
}

$linkFiles = @()
foreach ($root in 'README.md', 'CHANGELOG.md', 'CLAUDE.md') {
    $p = Join-Path $RepoRoot $root
    if (Test-Path -LiteralPath $p) { $linkFiles += $p }
}
# Het specialisten-handboek woont naast de lenzen (op familie-niveau) -- ook zijn links valideren.
$handbook = Join-Path $RepoRoot '.claude\plugins\claude-specialists\README.md'
if (Test-Path -LiteralPath $handbook) { $linkFiles += $handbook }
# De family-README + QUICKSTART.md van de specialists-familie (claude-code-plugins/claude-specialists/)
# en elke plugin-eigen CHANGELOG.md (het consument-gerichte kaartje dat cut-release.ps1 bijschrijft)
# hoorden nog niet in de scanset thuis -- toegevoegd (#103).
foreach ($familyDoc in 'README.md', 'QUICKSTART.md') {
    $p = Join-Path $RepoRoot "claude-code-plugins\claude-specialists\$familyDoc"
    if (Test-Path -LiteralPath $p) { $linkFiles += $p }
}
$linkFiles += (Get-ChildItem -Path (Join-Path $RepoRoot 'claude-code-plugins\claude-specialists') -Recurse -Filter 'CHANGELOG.md' -File |
    Where-Object { $_.FullName -notmatch '\\connectors\\' } |
    Select-Object -ExpandProperty FullName)
# De repo-lenzen wonen op het plugin-pad (.claude/plugins/claude-specialists/specialists/, de
# standaard) of op het legacy-pad (.claude/extensions/) -- scan beide, waar ze ook staan.
foreach ($extDir in @(
    (Join-Path $RepoRoot '.claude\plugins\claude-specialists\specialists'),
    (Join-Path $RepoRoot '.claude\extensions'))) {
    if (Test-Path -LiteralPath $extDir) {
        $linkFiles += (Get-ChildItem -Path $extDir -Filter '*.md' -File | Select-Object -ExpandProperty FullName)
    }
}
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter 'SKILL.md' -File |
    Where-Object { $_.FullName -match '\\skills\\' } | Select-Object -ExpandProperty FullName)
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-manual.md' -File |
    Where-Object { $_.FullName -match '\\manuals\\' } | Select-Object -ExpandProperty FullName)
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-persona.md' -File |
    Where-Object { $_.FullName -match '\\personas\\' } | Select-Object -ExpandProperty FullName)
$releasesDir = Join-Path $RepoRoot 'releases'
if (Test-Path -LiteralPath $releasesDir) {
    $linkFiles += (Get-ChildItem -Path $releasesDir -Recurse -Filter '*.md' -File | Select-Object -ExpandProperty FullName)
}
# Elk plugin-gedragen RELEASE.md-kaartje (check 9) linkt naar de volledige notes en de eigen
# CHANGELOG.md -- ook die links horen gevalideerd te worden.
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter 'RELEASE.md' -File |
    Select-Object -ExpandProperty FullName)

$linkRegex = [regex]'\[(?:[^\]]*)\]\(([^)]+)\)'
$slugCache = @{}
foreach ($lf in $linkFiles) {
    $content = [System.IO.File]::ReadAllText($lf, [System.Text.Encoding]::UTF8)
    # Code uitsluiten: fenced (```...```) en inline (`...`). Link-achtige tekst binnen code is
    # illustratie, geen echte link -- anders wordt bv. een `[..](#anchor)`-voorbeeld gevalideerd.
    $scan = [regex]::Replace($content, '(?s)```.*?```', '')
    $scan = [regex]::Replace($scan, '`[^`]*`', '')
    # Persona-sjablonen zijn bestemd voor .claude/extensions/ van een consumerende repo; hun
    # relatieve links horen dáár te kloppen, niet op de bronlocatie in de plugin. Valideer ze daarom
    # alsof het bestand al op die bestemming staat (deze repo spiegelt de consumer-lay-out).
    if ($lf -match '\\personas\\.*-persona\.md$') {
        $dir = Join-Path $RepoRoot '.claude\extensions'
    } else {
        $dir = Split-Path -Parent $lf
    }
    $rel = $lf.Replace($RepoRoot, '.')
    foreach ($m in $linkRegex.Matches($scan)) {
        $target = $m.Groups[1].Value.Trim()
        if ($target -match '^(https?:|mailto:)') { continue }

        $parts = $target -split '#', 2
        $pathPart = $parts[0]
        $anchor = if ($parts.Count -gt 1) { $parts[1] } else { $null }

        # Doelbestand bepalen: leeg pathPart = ditzelfde bestand (pure #anchor).
        if (-not $pathPart) {
            $targetFile = $lf
        } else {
            $resolved = Join-Path $dir ($pathPart -replace '/', '\')
            if (-not (Test-Path -LiteralPath $resolved)) {
                Add-Error "[link] $rel -> dode link '$target' (verwacht bestand bestaat niet)."
                continue
            }
            $targetFile = $resolved
        }

        # Anchor-validatie: alleen zinvol voor een bestaand .md-doelbestand.
        if ($anchor -and $targetFile -match '\.md$' -and (Test-Path -LiteralPath $targetFile -PathType Leaf)) {
            $full = (Resolve-Path -LiteralPath $targetFile).Path
            if (-not $slugCache.ContainsKey($full)) { $slugCache[$full] = Get-HeadingSlugs -Path $full }
            if (-not $slugCache[$full].Contains($anchor)) {
                Add-Error "[anchor] $rel -> '$target' (anchor '#$anchor' bestaat niet als kop in het doelbestand)."
            }
        }
    }
}

# --- 5. PowerShell-scripts moeten parsen ------------------------------------------------------------
# Vangt syntaxfouten voor ze op main belanden. De pure logica van een script kun je los testen,
# maar een parse-fout in de orkestratie zelf breekt pas bij uitvoering -- deze check trekt dat naar
# voren, naar de PR-poort. Gescand: scripts/**/*.ps1 EN de scripts die een plugin meedraagt --
# <plugin>/skills/**/*.ps1 (bv. de bootstrap van specialists-init) en <plugin>/scripts/**/*.ps1
# (het gedeelde SSOT-thuis, issue #81). Uniek gemaakt zodat een pad dat beide filters raakt niet
# dubbel geparsed wordt.
$psScripts = @()
$psScripts += (Get-ChildItem -Path (Join-Path $RepoRoot 'scripts') -Recurse -Filter '*.ps1' -File)
$psScripts += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*.ps1' -File |
    Where-Object { $_.FullName -match '\\skills\\' -or $_.FullName -match '\\claude-code-plugins\\.+\\scripts\\' })
$psScripts = @($psScripts | Sort-Object -Property FullName -Unique)
$psScripts | ForEach-Object {
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$parseErrors) | Out-Null
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        $rel = $_.FullName.Replace($RepoRoot, '.')
        Add-Error "[parse] $rel`: $($parseErrors[0].Message)"
    }
}

# --- 6. specialisten-systeem-integriteit ------------------------------------------------------------
# Deze repo is de bron van het specialisten-systeem, dus de agent-def<->manual-koppeling moet hier
# minstens zo streng zijn als bij een consument. Per plugin (map met agents/ en manuals/):
#   6a. elk '<group>-<id>' is uniek over alle agent-defs; elke agent-def heeft een geldige 'name:'
#       (Claude Code-aanroepnaam), een bijbehorende manuals/<g>-<id>-manual.md in dezelfde plugin, en
#       noemt die manual in zijn tekst.
#   6b. geen wees-manual: elke manuals/<g>-<id>-manual.md heeft een agents/<g>-<id>-agent.md.
# (De roster->lens-koppeling wordt al door de dode-link-scan hierboven gedekt, want die scant CLAUDE.md.)

$idOwner = @{}
Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-agent.md' -File |
    Where-Object { $_.FullName -match '\\agents\\' } | ForEach-Object {
        $rel = $_.FullName.Replace($RepoRoot, '.')
        if ($_.BaseName -notmatch '^(\d{2})-(\d{2})-agent$') {
            Add-Error "[specialist] $rel volgt niet het <group>-<id>-agent.md-patroon."
            return
        }
        $g = $Matches[1]; $id = $Matches[2]; $key = "$g-$id"
        if ($idOwner.ContainsKey($key)) {
            Add-Error "[specialist] ${rel}: dubbel id '$key' (al geclaimd door $($idOwner[$key]))."
        } else {
            $idOwner[$key] = $rel
        }

        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $nm = [regex]::Match($text, '(?m)^name:\s*(\S+)\s*$')
        if ($nm.Success -and ($nm.Groups[1].Value.Trim() -notmatch '^[a-z0-9-]+$')) {
            Add-Error "[specialist] ${rel}: 'name: $($nm.Groups[1].Value.Trim())' moet uit kleine letters/cijfers/koppeltekens bestaan (Claude Code-aanroepnaam)."
        }

        $pluginRoot = Split-Path (Split-Path $_.FullName -Parent) -Parent
        $manualBase = "$g-$id-manual"
        $manualPath = Join-Path $pluginRoot ("manuals\$manualBase.md")
        if (-not (Test-Path -LiteralPath $manualPath -PathType Leaf)) {
            Add-Error "[specialist] ${rel}: bijbehorende manual 'manuals/$manualBase.md' ontbreekt in dezelfde plugin."
        } elseif ($text -notmatch [regex]::Escape("manuals/$manualBase.md")) {
            Add-Error "[specialist] ${rel}: agent-def noemt zijn manual 'manuals/$manualBase.md' niet."
        }
    }

Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-manual.md' -File |
    Where-Object { $_.FullName -match '\\manuals\\' } | ForEach-Object {
        if ($_.BaseName -match '^(\d{2})-(\d{2})-manual$') {
            $g = $Matches[1]; $id = $Matches[2]
            $pluginRoot = Split-Path (Split-Path $_.FullName -Parent) -Parent
            $agentPath = Join-Path $pluginRoot ("agents\$g-$id-agent.md")
            if (-not (Test-Path -LiteralPath $agentPath -PathType Leaf)) {
                $rel = $_.FullName.Replace($RepoRoot, '.')
                Add-Error "[specialist] ${rel}: wees-manual -- geen bijbehorende agents/$g-$id-agent.md in dezelfde plugin."
            }
        }
    }

# --- 7. gedeelde agent-def-blokken in sync met hun bron ---------------------------------------------
# Verbatim-gedeelde bullets (bv. de inbound-regel, 19/19) worden op EEN plek onderhouden in
# agent-shared/<naam>.md en in de agent-defs ingevuld tussen <!-- BEGIN/END shared:NAME -->-sentinels
# (build via scripts/agents/build-agent-defs.ps1). Hier bewaken we dat elke gemarkeerde regio nog
# gelijk is aan zijn bron -- zo valt een hand-edit binnen de sentinels of een vergeten rebuild op.
. (Join-Path $PSScriptRoot '..\lib\agent-shared-lib.ps1')
$agentSharedDir = Get-AgentSharedDir -RepoRoot $RepoRoot
Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-agent.md' -File |
    Where-Object { $_.FullName -match '\\agents\\' } | ForEach-Object {
        $raw = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        $sharedProblems = New-Object System.Collections.Generic.List[string]
        $expanded = Expand-AgentDefShared -Content $raw -SharedDir $agentSharedDir -Problems $sharedProblems
        foreach ($p in $sharedProblems) { Add-Error "[shared] ${rel}: $p" }
        if ($expanded -ne ($raw -replace "`r`n", "`n")) {
            Add-Error "[shared] ${rel}: gedeeld blok wijkt af van de bron -- draai scripts/agents/build-agent-defs.ps1."
        }
    }

# --- 8. gedeelde workflow-scripts in sync met hun bron ---------------------------------------------
# Repo-agnostische scripts worden als plugin-spiegel gedeeld met consumenten (issue #81): de
# root-kopie is de geteste bron, de plugin-spiegel is wat een consument draait. Hier bewaken we dat
# elke spiegel nog LF-identiek is aan zijn bron -- zo valt een hand-edit in de spiegel of een vergeten
# rebuild (scripts/sync/build-shared-scripts.ps1) op voor het via een PR op main belandt.
. (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')
foreach ($pair in @(Get-SharedScriptPairs -RepoRoot $RepoRoot)) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    if ($null -eq $src) {
        Add-Error "[shared-script] bron ontbreekt: $($pair.SourceRel)."
        continue
    }
    $mirror = Get-NormalizedScriptContent -Path $pair.MirrorPath
    if ($null -eq $mirror) {
        Add-Error "[shared-script] spiegel ontbreekt: $($pair.MirrorRel) -- draai scripts/sync/build-shared-scripts.ps1."
    } elseif ($src -ne $mirror) {
        Add-Error "[shared-script] $($pair.MirrorRel) wijkt af van $($pair.SourceRel) -- draai scripts/sync/build-shared-scripts.ps1."
    }
}

# --- 9. RELEASE.md per plugin aanwezig + versie-match -------------------------------------------------
# Model A (plugin-gedragen, zie CHANGELOG/#115-achtige inbound-issue): cut-release.ps1 schrijft dit
# kaartje bij ELKE release voor ELKE plugin (lockstep-versie), ook een plugin die deze keer niet
# geraakt is. Omdat RELEASE.md en plugin.json alleen samen wijzigen -- via cut-release.ps1 -- kan een
# gewone feature-PR hier nooit op stuklopen; alleen een vergeten regeneratie of hand-edit valt op.
Get-ChildItem -Path $RepoRoot -Recurse -Filter 'plugin.json' -File |
    Where-Object { $_.FullName -match '\.claude-plugin\\plugin\.json$' } | ForEach-Object {
        $pluginDir = Split-Path (Split-Path $_.FullName -Parent) -Parent
        $pluginName = Split-Path $pluginDir -Leaf
        $pj = Test-JsonFile -Path $_.FullName
        if (-not $pj) { return }
        if (-not ($pj.PSObject.Properties.Name -contains 'version') -or -not $pj.version) {
            Add-Error "[release-card] $pluginName/.claude-plugin/plugin.json mist een niet-lege 'version' -- vereist voor het lockstep-RELEASE.md-kaartje."
            return
        }
        $pjVersion = $pj.version
        $releasePath = Join-Path $pluginDir 'RELEASE.md'
        if (-not (Test-Path -LiteralPath $releasePath -PathType Leaf)) {
            Add-Error "[release-card] $pluginName mist RELEASE.md -- run scripts/release/cut-release.ps1 (dat regenereert het kaartje voor elke plugin)."
            return
        }
        $releaseText = [System.IO.File]::ReadAllText($releasePath, [System.Text.Encoding]::UTF8)
        $vm = [regex]::Match($releaseText, '(?m)^#\s+Release\s+v(\d+\.\d+\.\d+)\s*$')
        if (-not $vm.Success) {
            Add-Error "[release-card] $pluginName/RELEASE.md: geen '# Release vX.Y.Z'-kop gevonden -- regenereer via cut-release.ps1."
        } elseif ($vm.Groups[1].Value -ne $pjVersion) {
            Add-Error "[release-card] $pluginName/RELEASE.md draagt v$($vm.Groups[1].Value), maar plugin.json zegt v$pjVersion -- run cut-release.ps1 opnieuw."
        }
    }

# --- Rapport ----------------------------------------------------------------------------------------
if ($errors.Count -eq 0) {
    Write-Host "  Geen bevindingen." -ForegroundColor Green
    Write-Host ""
    Write-Host "Samenvatting: 0 error(s)." -ForegroundColor Cyan
    exit 0
}
foreach ($e in $errors) { Write-Host "  $e" -ForegroundColor Red }
Write-Host ""
Write-Host "Samenvatting: $($errors.Count) error(s)." -ForegroundColor Cyan
exit 1
