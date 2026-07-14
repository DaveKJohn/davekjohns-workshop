<#
.SYNOPSIS
    Integriteitscheck voor de claude-specialists-marketplace: valideert de manifesten, de
    agent-def-frontmatter en de interne links voordat een wijziging via een PR op master belandt.
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
      4. dode relatieve links in README.md, CHANGELOG.md, elke <plugin>/skills/*/SKILL.md, elke
         <plugin>/manuals/*-manual.md en elke releases/**/*.md (het gelinkte bestand/pad bestaat).
         Externe http(s)-/mailto-links en pure anchors worden overgeslagen.
      5. elke scripts/**/*.ps1 parseert foutloos (vangt syntaxfouten in de orkestratie zelf, die pas
         bij uitvoering zouden breken).

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

# --- 4. dode relatieve links in README.md + SKILL.md + manuals --------------------------------------
$linkFiles = @()
foreach ($root in 'README.md', 'CHANGELOG.md') {
    $p = Join-Path $RepoRoot $root
    if (Test-Path -LiteralPath $p) { $linkFiles += $p }
}
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter 'SKILL.md' -File |
    Where-Object { $_.FullName -match '\\skills\\' } | Select-Object -ExpandProperty FullName)
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-manual.md' -File |
    Where-Object { $_.FullName -match '\\manuals\\' } | Select-Object -ExpandProperty FullName)
$releasesDir = Join-Path $RepoRoot 'releases'
if (Test-Path -LiteralPath $releasesDir) {
    $linkFiles += (Get-ChildItem -Path $releasesDir -Recurse -Filter '*.md' -File | Select-Object -ExpandProperty FullName)
}

$linkRegex = [regex]'\[(?:[^\]]*)\]\(([^)]+)\)'
foreach ($lf in $linkFiles) {
    $content = [System.IO.File]::ReadAllText($lf, [System.Text.Encoding]::UTF8)
    $dir = Split-Path -Parent $lf
    $rel = $lf.Replace($RepoRoot, '.')
    foreach ($m in $linkRegex.Matches($content)) {
        $target = $m.Groups[1].Value.Trim()
        if ($target -match '^(https?:|mailto:|#)') { continue }
        $pathPart = ($target -split '#', 2)[0]
        if (-not $pathPart) { continue }   # pure anchor
        $resolved = Join-Path $dir ($pathPart -replace '/', '\')
        if (-not (Test-Path -LiteralPath $resolved)) {
            Add-Error "[link] $rel -> dode link '$target' (verwacht bestand bestaat niet)."
        }
    }
}

# --- 5. PowerShell-scripts moeten parsen ------------------------------------------------------------
# Vangt syntaxfouten in scripts/**/*.ps1 voor ze op master belanden. De pure logica van een script
# kun je los testen, maar een parse-fout in de orkestratie zelf breekt pas bij uitvoering -- deze
# check trekt dat naar voren, naar de PR-poort.
Get-ChildItem -Path (Join-Path $RepoRoot 'scripts') -Recurse -Filter '*.ps1' -File | ForEach-Object {
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$parseErrors) | Out-Null
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        $rel = $_.FullName.Replace($RepoRoot, '.')
        Add-Error "[parse] $rel`: $($parseErrors[0].Message)"
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
