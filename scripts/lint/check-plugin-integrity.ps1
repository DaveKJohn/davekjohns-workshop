<#
.SYNOPSIS
    Integriteitscheck voor de claude-specialists-marketplace: valideert de manifesten, de
    agent-def-frontmatter en de interne links voordat een wijziging via een PR op master belandt.
.DESCRIPTION
    De lint-poort van dit repo (aangeroepen door scripts/release/open-pr.ps1). Read-only -- wijzigt
    niets. Controleert vier dingen; elke bevinding is een error:

      1. .claude-plugin/marketplace.json: geldige JSON; elke plugins[].source verwijst naar een
         bestaande map met een .claude-plugin/plugin.json.
      2. elke <plugin>/.claude-plugin/plugin.json: geldige JSON met een niet-lege 'name'.
      3. elke <plugin>/agents/*.md: frontmatter bevat 'name:', 'id:' en 'group:'.
      4. dode relatieve links in README.md en in elke <plugin>/skills/*/SKILL.md (het gelinkte
         bestand/pad bestaat). Externe http(s)-/mailto-links en pure anchors worden overgeslagen.

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

# --- 4. dode relatieve links in README.md + SKILL.md ------------------------------------------------
$linkFiles = @()
$readme = Join-Path $RepoRoot 'README.md'
if (Test-Path -LiteralPath $readme) { $linkFiles += $readme }
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter 'SKILL.md' -File |
    Where-Object { $_.FullName -match '\\skills\\' } | Select-Object -ExpandProperty FullName)

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
