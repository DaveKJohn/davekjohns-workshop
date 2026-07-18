<#
.SYNOPSIS
    Spiegelt de gedeelde workflow-scripts vanuit hun canonieke root-kopie naar de plugin-spiegel.

.DESCRIPTION
    De root-kopie is de geteste bron; de plugin-spiegel is wat een consument via een skill draait
    (issue #81). Dit script houdt de spiegel in sync met de bron -- exact het patroon van
    scripts/agents/build-agent-defs.ps1, maar dan voor hele scripts i.p.v. gedeelde blokken.

    Het register staat in scripts/lib/shared-scripts-lib.ps1 (enige bron). Schrijft BOM-loos, LF,
    alleen als er iets verandert.

    -Check: schrijft niets; meldt drift (een spiegel die afwijkt van zijn bron) en eindigt met
    exit-code 1. Dit is de modus die check-plugin-integrity.ps1 en CI gebruiken als poort.

    Puur ASCII (repo-conventie voor .ps1).
.EXAMPLE
    ./scripts/sync/build-shared-scripts.ps1
.EXAMPLE
    ./scripts/sync/build-shared-scripts.ps1 -Check
#>
param([switch]$Check)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Write-Host "== build-shared-scripts$(if ($Check) {' -Check'}) -- $RepoRoot ==" -ForegroundColor Cyan

$pairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot)
$changed = 0
$problemCount = 0
foreach ($pair in $pairs) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    if ($null -eq $src) {
        Write-Host "  [probleem]   bron ontbreekt: $($pair.SourceRel)" -ForegroundColor Red
        $problemCount++
        continue
    }
    $mirror = Get-NormalizedScriptContent -Path $pair.MirrorPath
    if ($src -ne $mirror) {
        $changed++
        if ($Check) {
            Write-Host "  [drift]      $($pair.MirrorRel) -- wijkt af van $($pair.SourceRel) (draai build-shared-scripts.ps1)" -ForegroundColor Red
        } else {
            $dir = Split-Path -Path $pair.MirrorPath -Parent
            if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
            [System.IO.File]::WriteAllText($pair.MirrorPath, $src, $Utf8NoBom)
            Write-Host "  [bijgewerkt] $($pair.MirrorRel)" -ForegroundColor Green
        }
    }
}

Write-Host ""
if ($Check) {
    if ($changed -gt 0 -or $problemCount -gt 0) {
        Write-Host "Samenvatting: $changed drift, $problemCount probleem -- NIET in sync." -ForegroundColor Red
        exit 1
    }
    Write-Host "Samenvatting: alle gedeelde scripts in sync met hun bron." -ForegroundColor Green
    exit 0
}
if ($problemCount -gt 0) {
    Write-Host "Samenvatting: $changed bijgewerkt, $problemCount probleem (los die eerst op)." -ForegroundColor Yellow
    exit 1
}
Write-Host "Samenvatting: $changed spiegel(s) bijgewerkt, rest al in sync." -ForegroundColor Cyan
exit 0
