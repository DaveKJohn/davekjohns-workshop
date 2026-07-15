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
         elke <plugin>/personas/*-persona.md en elke releases/**/*.md. Gecontroleerd: (a) het gelinkte
         bestand bestaat, en (b) als de link
         een #anchor heeft, dat die anchor als kop bestaat in het doelbestand (GitHub-slugregels).
         Externe http(s)-/mailto-links worden overgeslagen.
      5. elke scripts/**/*.ps1 parseert foutloos (vangt syntaxfouten in de orkestratie zelf, die pas
         bij uitvoering zouden breken).
      6. specialisten-systeem-integriteit: per plugin is elk '<group>-<id>' uniek over de agent-defs,
         heeft elke agent-def een geldige 'name:' + een bijbehorende manuals/<g>-<id>-manual.md die
         hij ook noemt, en heeft elke manual omgekeerd een agent-def (geen wees-manual).

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
            foreach ($p in $mp.plugins) {
                $src = $p.source
                if (-not $src) { Add-Error "[marketplace] plugin '$($p.name)' mist een 'source'."; continue }
                $pluginDir = (Join-Path $RepoRoot ($src -replace '/', '\')).TrimEnd('\')
                if (-not (Test-Path -LiteralPath $pluginDir -PathType Container)) {
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
$extDir = Join-Path $RepoRoot '.claude\extensions'
if (Test-Path -LiteralPath $extDir) {
    $linkFiles += (Get-ChildItem -Path $extDir -Filter '*.md' -File | Select-Object -ExpandProperty FullName)
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
# voren, naar de PR-poort. Gescand: scripts/**/*.ps1 EN de scripts die een plugin-skill meedraagt
# (<plugin>/skills/**/*.ps1, bv. de bootstrap van specialists-init).
$psScripts = @()
$psScripts += (Get-ChildItem -Path (Join-Path $RepoRoot 'scripts') -Recurse -Filter '*.ps1' -File)
$psScripts += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*.ps1' -File |
    Where-Object { $_.FullName -match '\\skills\\' })
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
