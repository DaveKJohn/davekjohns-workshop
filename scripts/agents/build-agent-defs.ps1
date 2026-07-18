<#
.SYNOPSIS
    Bouwt de agent-defs: vult elke gedeelde-blok-regio (<!-- BEGIN/END shared:NAME -->) met de
    canonieke bron uit claude-code-plugins/claude-specialists/agent-shared/<naam>.md.
.DESCRIPTION
    Verbatim-gedeelde bullets onder **Grenzen** (bv. de inbound-regel, 19/19) worden op EEN plek
    onderhouden (agent-shared/) en hier in alle agent-defs ingevuld. Wijzig je een gedeeld blok,
    draai dan dit script: alle agent-defs die het blok dragen worden bijgewerkt. De inhoud blijft
    letterlijk in de agent-def staan (altijd-geladen, self-contained); dit script houdt hem in sync.

    Draait over alle <plugin>/agents/*-agent.md in de drie plugins. Schrijft BOM-loos, LF, alleen als
    er iets verandert.

    -Check: schrijft niets; meldt drift (een blok dat afwijkt van zijn bron) of een structureel
    probleem (BEGIN zonder END, onbekend blok) en eindigt met exit-code 1. Dit is de modus die
    check-plugin-integrity.ps1 en CI gebruiken als poort.

    Puur ASCII (repo-conventie voor .ps1).
.EXAMPLE
    ./scripts/agents/build-agent-defs.ps1
.EXAMPLE
    ./scripts/agents/build-agent-defs.ps1 -Check
#>
param([switch]$Check)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot '..\lib\agent-shared-lib.ps1')
$SharedDir = Get-AgentSharedDir -RepoRoot $RepoRoot
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path -LiteralPath $SharedDir -PathType Container)) {
    Write-Host "Bron-map agent-shared/ ontbreekt ($SharedDir) -- stop." -ForegroundColor Red
    exit 1
}

Write-Host "== build-agent-defs$(if ($Check) {' -Check'}) -- $RepoRoot ==" -ForegroundColor Cyan

$agentFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-agent.md' -File |
    Where-Object { $_.FullName -match '\\agents\\' } | Sort-Object FullName

$changed = 0
$problemCount = 0
foreach ($f in $agentFiles) {
    $raw = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $rel = $f.FullName.Replace($RepoRoot, '.')
    $problems = New-Object System.Collections.Generic.List[string]
    $expanded = Expand-AgentDefShared -Content $raw -SharedDir $SharedDir -Problems $problems
    foreach ($p in $problems) {
        Write-Host "  [probleem]   ${rel}: $p" -ForegroundColor Red
        $problemCount++
    }
    $current = ($raw -replace "`r`n", "`n")
    if ($expanded -ne $current) {
        $changed++
        if ($Check) {
            Write-Host "  [drift]      $rel -- gedeeld blok wijkt af van de bron (draai build-agent-defs.ps1)" -ForegroundColor Red
        } else {
            [System.IO.File]::WriteAllText($f.FullName, $expanded, $Utf8NoBom)
            Write-Host "  [bijgewerkt] $rel" -ForegroundColor Green
        }
    }
}

Write-Host ""
if ($Check) {
    if ($changed -gt 0 -or $problemCount -gt 0) {
        Write-Host "Samenvatting: $changed drift, $problemCount probleem -- NIET in sync." -ForegroundColor Red
        exit 1
    }
    Write-Host "Samenvatting: alle gedeelde blokken in sync met de bron." -ForegroundColor Green
    exit 0
}
if ($problemCount -gt 0) {
    Write-Host "Samenvatting: $changed bijgewerkt, $problemCount probleem (los die eerst op)." -ForegroundColor Yellow
    exit 1
}
Write-Host "Samenvatting: $changed agent-def(s) bijgewerkt, rest al in sync." -ForegroundColor Cyan
exit 0
