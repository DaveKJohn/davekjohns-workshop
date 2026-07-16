<#
.SYNOPSIS
    Connectors-check: verifieert per plugin of alle aangesloten repo's (connectors) nog in sync
    zijn met deze repo -- de source of truth.

.DESCRIPTION
    Elke plugin draagt een connectors/-map met een manifest per aangesloten repo
    (claude-code-plugins/claude-specialists/<plugin>/connectors/<repo>.json). Het manifest bevat
    alleen METADATA (repo, plugin, versie, extension-inventaris, status) -- nooit lens-inhoud en
    nooit absolute machine-paden; localCheckout is relatief aan de root van deze repo.

    Per manifest checkt dit script:
      1. Checkout aanwezig op deze machine?          nee -> [SKIP] (geen fout)
      2. Plugin enabled in .claude/settings.json?    nee -> [FOUT]
      3. Alle geregistreerde extensions aanwezig?    mist er een -> [FOUT]
         Extensions van deze plugin die in de consument bestaan maar NIET geregistreerd
         zijn -> [INFO] (inbound-signaal: register bijwerken of wijziging terughalen).
      4. Manifest-versie vs. bron-plugin.json        ouder -> [INFO] (sync + manifest bijwerken)
      5. Machine-record (installed_plugins.json)     ouder dan bron -> [FOUT]; geen record/geen
         administratie -> [INFO] (machine-specifiek, geen poortbreuk)
    Daarna draait per unieke consument eenmalig scripts/lint/check-consumer-drift.ps1
    (agent-def-drift = fout; persona-drift = informatief, zoals in dat script zelf).

    Exit-code: 0 = geen fouten (SKIP/INFO tellen niet mee), 1 = minstens een fout.

.PARAMETER Manifest
    (Optioneel) Pad naar een enkel manifest i.p.v. alle connectors-manifesten.

.PARAMETER ConsumerPathOverride
    (Optioneel, voor tests) Overschrijft localCheckout uit het manifest.

.PARAMETER SkipDrift
    Sla de check-consumer-drift-stap over (sneller; alleen de registerchecks).

.PARAMETER SkipVersions
    Sla de machine-record-check over (bv. op CI, waar geen plugin-administratie bestaat).

.EXAMPLE
    .\scripts\sync\check-connectors.ps1
.EXAMPLE
    .\scripts\sync\check-connectors.ps1 -SkipDrift -SkipVersions
#>
param(
    [string]$Manifest = '',
    [string]$ConsumerPathOverride = '',
    [switch]$SkipDrift,
    [switch]$SkipVersions
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$FamilyRoot = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists'
$DriftLint  = Join-Path $RepoRoot 'scripts\lint\check-consumer-drift.ps1'

$script:errors = 0
$script:infos  = 0

function Write-Ok   ([string]$Msg) { Write-Host "  [OK]    $Msg" -ForegroundColor Green }
function Write-Skip ([string]$Msg) { Write-Host "  [SKIP]  $Msg" -ForegroundColor DarkGray }
function Write-Info ([string]$Msg) { $script:infos++;  Write-Host "  [INFO]  $Msg" -ForegroundColor Yellow }
function Write-Fout ([string]$Msg) { $script:errors++; Write-Host "  [FOUT]  $Msg" -ForegroundColor Red }

# Plugin-naam (voor de '@') -> plugin-map onder de familie-root.
function Get-PluginDir([string]$PluginId) {
    $name = $PluginId.Split('@')[0]
    return Join-Path $FamilyRoot $name
}

# Ids (<group>-<id>) die een plugin bezit: agents/ + personas/.
function Get-PluginIds([string]$PluginDir) {
    $ids = @()
    foreach ($sub in @('agents', 'personas')) {
        $dir = Join-Path $PluginDir $sub
        if (Test-Path -LiteralPath $dir) {
            $ids += Get-ChildItem -LiteralPath $dir -Filter '*.md' -File |
                ForEach-Object { $_.BaseName -replace '-(agent|persona)$', '' }
        }
    }
    return $ids | Sort-Object -Unique
}

# Verzamel manifesten.
if ($Manifest) {
    $manifestFiles = @(Get-Item -LiteralPath $Manifest)
} else {
    $manifestFiles = Get-ChildItem -LiteralPath $FamilyRoot -Recurse -Filter '*.json' -File |
        Where-Object { $_.DirectoryName -match '\\connectors$' }
}

if ($manifestFiles.Count -eq 0) {
    Write-Host 'Geen connectors-manifesten gevonden.' -ForegroundColor Yellow
    exit 0
}

Write-Host "== check-connectors -- $($manifestFiles.Count) manifest(en) ==" -ForegroundColor Cyan

$checkedConsumers = @{}

foreach ($mf in $manifestFiles) {
    $m = Get-Content -LiteralPath $mf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "`n-- $($m.plugin) -> $($m.repo)" -ForegroundColor Cyan

    # 1. Checkout aanwezig?
    if ($ConsumerPathOverride) {
        $checkout = $ConsumerPathOverride
    } else {
        $checkout = Join-Path $RepoRoot $m.localCheckout
    }
    if (-not (Test-Path -LiteralPath $checkout)) {
        Write-Skip "checkout '$($m.localCheckout)' niet aanwezig op deze machine -- niet gecheckt."
        continue
    }
    $checkout = (Resolve-Path -LiteralPath $checkout).Path

    # 2. Plugin enabled in de consument?
    $settingsPath = Join-Path $checkout '.claude\settings.json'
    if (Test-Path -LiteralPath $settingsPath) {
        $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $enabled = $false
        if ($settings.PSObject.Properties.Name -contains 'enabledPlugins') {
            $prop = $settings.enabledPlugins.PSObject.Properties | Where-Object { $_.Name -eq $m.plugin }
            if ($prop -and $prop.Value -eq $true) { $enabled = $true }
        }
        if ($enabled) { Write-Ok "plugin staat aan in .claude/settings.json" }
        else          { Write-Fout "plugin '$($m.plugin)' staat NIET (meer) aan in $settingsPath" }
    } else {
        Write-Fout ".claude/settings.json niet gevonden in '$checkout'"
    }

    # 3. Geregistreerde extensions aanwezig? + niet-geregistreerde extensions van deze plugin.
    $extDir = Join-Path $checkout '.claude\extensions'
    $missing = @()
    foreach ($id in $m.extensions) {
        if (-not (Test-Path -LiteralPath (Join-Path $extDir "$id-extension.md"))) { $missing += $id }
    }
    if ($missing.Count -gt 0) { Write-Fout ("geregistreerde extension(s) ontbreken: " + ($missing -join ', ')) }
    else                      { Write-Ok  "alle $($m.extensions.Count) geregistreerde extensions aanwezig" }

    $pluginDir = Get-PluginDir $m.plugin
    $ownedIds  = Get-PluginIds $pluginDir
    if (Test-Path -LiteralPath $extDir) {
        $present = Get-ChildItem -LiteralPath $extDir -Filter '*-extension.md' -File |
            ForEach-Object { $_.BaseName -replace '-extension$', '' }
        $unregistered = $present | Where-Object { ($ownedIds -contains $_) -and ($m.extensions -notcontains $_) }
        foreach ($id in @($unregistered)) {
            Write-Info "extension '$id' bestaat in de consument maar staat niet in het register -- register bijwerken of wijziging beoordelen."
        }
    }

    # 4. Manifest-versie vs. bron.
    $pluginJsonPath = Join-Path $pluginDir '.claude-plugin\plugin.json'
    $sourceVersion = (Get-Content -LiteralPath $pluginJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json).version
    if ($m.syncedVersion -ne $sourceVersion) {
        Write-Info "manifest is gesynct op v$($m.syncedVersion), bron staat op v$sourceVersion -- sync en manifest bijwerken."
    } else {
        Write-Ok "manifest gesynct op de actuele bronversie (v$sourceVersion)"
    }

    # 5. Machine-record vs. bron.
    if (-not $SkipVersions) {
        $adminPath = Join-Path $env:USERPROFILE '.claude\plugins\installed_plugins.json'
        if (Test-Path -LiteralPath $adminPath) {
            $admin = Get-Content -LiteralPath $adminPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $prop = $admin.plugins.PSObject.Properties | Where-Object { $_.Name -eq $m.plugin }
            $record = $null
            if ($prop) {
                $record = @($prop.Value) | Where-Object {
                    $_.projectPath -and ((Resolve-Path -LiteralPath $_.projectPath -ErrorAction SilentlyContinue).Path -eq $checkout)
                } | Select-Object -First 1
            }
            if ($null -eq $record) {
                Write-Info "geen machine-record voor deze consument (installatie loopt mogelijk via een andere machine)."
            } elseif ($record.version -eq $sourceVersion) {
                Write-Ok "machine-record staat op de bronversie (v$sourceVersion)"
            } else {
                Write-Fout "machine-record staat op v$($record.version), bron op v$sourceVersion -- update de plugin vanuit de consument (scope-les)."
            }
        } else {
            Write-Info "geen plugin-administratie op deze machine gevonden -- versiecheck overgeslagen."
        }
    }

    if (-not $checkedConsumers.ContainsKey($checkout)) { $checkedConsumers[$checkout] = $m.repo }
}

# Content-drift per unieke consument (agent-defs = fout, persona's = informatief).
if (-not $SkipDrift) {
    foreach ($checkout in $checkedConsumers.Keys) {
        if ($checkout -eq $RepoRoot) { continue }
        Write-Host "`n-- drift-check: $($checkedConsumers[$checkout])" -ForegroundColor Cyan
        & powershell -NoProfile -ExecutionPolicy Bypass -File $DriftLint -ConsumerPath $checkout -Quiet |
            Where-Object { $_ -match 'DRIFTED|IDENTICAL|Samenvatting|drift' } |
            ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -ne 0) { Write-Fout "agent-def-drift gevonden in $($checkedConsumers[$checkout]) -- zie check-consumer-drift." }
    }
}

Write-Host "`nSamenvatting: $($script:errors) fout(en), $($script:infos) info-signa(a)l(en)." -ForegroundColor $(if ($script:errors -gt 0) { 'Red' } else { 'Green' })
if ($script:errors -gt 0) { exit 1 }
exit 0
