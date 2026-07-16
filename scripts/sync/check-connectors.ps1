<#
.SYNOPSIS
    Connectors-check: verifieert of alle aangesloten repo's (connectors) nog in sync zijn met
    deze repo -- de source of truth.

.DESCRIPTION
    Het register woont op familie-niveau, naast de plugin-mappen (bewust NIET erin, zodat het
    niet meereist met de plugin-cache van consumenten): EEN manifest per aangesloten repo
    (claude-code-plugins/claude-specialists/connectors/<repo>.json), met daarin per plugin de
    gesyncte versie en de extension-inventaris. Manifesten bevatten alleen METADATA -- nooit
    lens-inhoud en nooit absolute machine-paden; localCheckout is relatief aan de root van deze
    repo.

    Per connector checkt dit script:
      1. Checkout aanwezig op deze machine?          nee -> [SKIP] (geen fout)
      2. Per plugin: enabled in .claude/settings.json?  nee -> [FOUT]
      3. Per plugin: alle geregistreerde extensions aanwezig?  mist er een -> [FOUT]
         Extensions van die plugin die in de consument bestaan maar NIET geregistreerd
         zijn -> [INFO] (inbound-signaal: register bijwerken of wijziging terughalen).
      4. Per plugin: manifest-versie vs. bron-plugin.json  ouder -> [INFO]
      5. Per plugin: machine-record (installed_plugins.json)  ouder dan bron -> [FOUT];
         geen record/geen administratie -> [INFO] (machine-specifiek, geen poortbreuk)
    Daarna draait per unieke consument eenmalig scripts/lint/check-consumer-drift.ps1
    (agent-def-drift = fout; persona-drift = informatief, zoals in dat script zelf).

    Guardrail (advies Sean): manifestvelden zijn data uit een publieke repo en worden nooit
    blind vertrouwd -- absolute of buiten-scope localCheckout-paden en ongeldige plugin-ids
    worden geweigerd.

    Exit-code: 0 = geen fouten (SKIP/INFO tellen niet mee), 1 = minstens een fout.

.PARAMETER Manifest
    (Optioneel) Pad naar een enkel manifest i.p.v. alle connectors-manifesten.

.PARAMETER ConsumerPathOverride
    (Optioneel, voor tests) Overschrijft localCheckout uit het manifest.

.PARAMETER OnlyConsumer
    (Optioneel) Beperk de check tot het manifest waarvan de checkout op dit pad uitkomt
    (scoping voor de SessionStart-hook: een sessie ziet alleen zijn eigen registerdata).

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
    [string]$OnlyConsumer = '',
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

# Plugin-id (voor de '@') -> plugin-map onder de familie-root, alleen als de naam een simpele
# slug is EN de map echt onder de familie-root bestaat; anders $null.
function Get-PluginDir([string]$PluginId) {
    $name = $PluginId.Split('@')[0]
    if ($name -notmatch '^[a-z0-9][a-z0-9-]*$') { return $null }
    $dir = Join-Path $FamilyRoot $name
    if (-not (Test-Path -LiteralPath $dir)) { return $null }
    return $dir
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

# Verzamel manifesten uit het register op familie-niveau.
if ($Manifest) {
    $manifestFiles = @(Get-Item -LiteralPath $Manifest)
} else {
    $connectorsRoot = Join-Path $FamilyRoot 'connectors'
    $manifestFiles = @()
    if (Test-Path -LiteralPath $connectorsRoot) {
        $manifestFiles = @(Get-ChildItem -LiteralPath $connectorsRoot -Filter '*.json' -File)
    }
}

if ($manifestFiles.Count -eq 0) {
    Write-Host 'Geen connectors-manifesten gevonden.' -ForegroundColor Yellow
    exit 0
}

$onlyPath = ''
if ($OnlyConsumer) {
    $onlyResolved = Resolve-Path -LiteralPath $OnlyConsumer -ErrorAction SilentlyContinue
    if ($onlyResolved) { $onlyPath = $onlyResolved.Path }
}

Write-Host "== check-connectors -- $($manifestFiles.Count) manifest(en) ==" -ForegroundColor Cyan

$checkedConsumers = @{}
$matched = 0

foreach ($mf in $manifestFiles) {
    $m = Get-Content -LiteralPath $mf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json

    # Checkout bepalen, met guardrails op het manifest-veld.
    if ($ConsumerPathOverride) {
        $checkout = $ConsumerPathOverride
    } else {
        if ([System.IO.Path]::IsPathRooted($m.localCheckout)) {
            Write-Fout "absoluut localCheckout-pad '$($m.localCheckout)' in $($mf.Name) -- geweigerd (alleen relatieve sibling-paden)."
            continue
        }
        $checkout = Join-Path $RepoRoot $m.localCheckout
    }
    if (-not (Test-Path -LiteralPath $checkout)) {
        if (-not $OnlyConsumer) {
            Write-Host "`n== connector: $($m.repo)" -ForegroundColor Cyan
            Write-Skip "checkout '$($m.localCheckout)' niet aanwezig op deze machine -- niet gecheckt."
        }
        continue
    }
    $checkout = (Resolve-Path -LiteralPath $checkout).Path
    if (-not $ConsumerPathOverride) {
        $scopeRoot = (Resolve-Path -LiteralPath (Join-Path $RepoRoot '..\..')).Path
        if (-not $checkout.StartsWith($scopeRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Fout "localCheckout '$($m.localCheckout)' valt buiten de toegestane scope ('$scopeRoot') -- geweigerd."
            continue
        }
    }

    # Scoping: alleen het manifest van de gevraagde consument (stil overslaan van de rest).
    if ($onlyPath -and $checkout -ne $onlyPath) { continue }
    $matched++

    Write-Host "`n== connector: $($m.repo)" -ForegroundColor Cyan

    # settings.json van de consument een keer inlezen.
    $settings = $null
    $settingsPath = Join-Path $checkout '.claude\settings.json'
    if (Test-Path -LiteralPath $settingsPath) {
        $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } else {
        Write-Fout ".claude/settings.json niet gevonden in '$checkout'"
    }
    $extDir = Join-Path $checkout '.claude\extensions'

    foreach ($p in @($m.plugins)) {
        Write-Host "  -- plugin: $($p.id)" -ForegroundColor Cyan

        $pluginDir = Get-PluginDir $p.id
        if ($null -eq $pluginDir) {
            Write-Fout "ongeldig of onbekend plugin-veld '$($p.id)' in $($mf.Name) -- plugin-blok overgeslagen."
            continue
        }

        # 2. Plugin enabled in de consument?
        if ($null -ne $settings) {
            $enabled = $false
            if ($settings.PSObject.Properties.Name -contains 'enabledPlugins') {
                $prop = $settings.enabledPlugins.PSObject.Properties | Where-Object { $_.Name -eq $p.id }
                if ($prop -and $prop.Value -eq $true) { $enabled = $true }
            }
            if ($enabled) { Write-Ok "plugin staat aan in .claude/settings.json" }
            else          { Write-Fout "plugin '$($p.id)' staat NIET (meer) aan in $settingsPath" }
        }

        # 3. Geregistreerde extensions aanwezig? + niet-geregistreerde extensions van deze plugin.
        $missing = @()
        foreach ($id in $p.extensions) {
            if (-not (Test-Path -LiteralPath (Join-Path $extDir "$id-extension.md"))) { $missing += $id }
        }
        if ($missing.Count -gt 0) { Write-Fout ("geregistreerde extension(s) ontbreken: " + ($missing -join ', ')) }
        else                      { Write-Ok  "alle $(@($p.extensions).Count) geregistreerde extensions aanwezig" }

        $ownedIds = Get-PluginIds $pluginDir
        if (Test-Path -LiteralPath $extDir) {
            $present = Get-ChildItem -LiteralPath $extDir -Filter '*-extension.md' -File |
                ForEach-Object { $_.BaseName -replace '-extension$', '' }
            $unregistered = $present | Where-Object { ($ownedIds -contains $_) -and ($p.extensions -notcontains $_) }
            foreach ($id in @($unregistered)) {
                Write-Info "extension '$id' bestaat in de consument maar staat niet in het register -- register bijwerken of wijziging beoordelen."
            }
        }

        # 4. Manifest-versie vs. bron.
        $pluginJsonPath = Join-Path $pluginDir '.claude-plugin\plugin.json'
        $sourceVersion = (Get-Content -LiteralPath $pluginJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json).version
        if ($p.syncedVersion -ne $sourceVersion) {
            Write-Info "manifest is gesynct op v$($p.syncedVersion), bron staat op v$sourceVersion -- sync en manifest bijwerken."
        } else {
            Write-Ok "manifest gesynct op de actuele bronversie (v$sourceVersion)"
        }

        # 5. Machine-record vs. bron.
        if (-not $SkipVersions) {
            $adminPath = Join-Path $env:USERPROFILE '.claude\plugins\installed_plugins.json'
            if (Test-Path -LiteralPath $adminPath) {
                $admin = Get-Content -LiteralPath $adminPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $prop = $admin.plugins.PSObject.Properties | Where-Object { $_.Name -eq $p.id }
                $record = $null
                if ($prop) {
                    # Een record kan een projectPath dragen dat niet (meer) bestaat op deze
                    # machine; Resolve-Path geeft dan $null en mag nooit blind op .Path worden
                    # uitgelezen (StrictMode-crash, vondst Victor).
                    foreach ($rec in @($prop.Value)) {
                        if (-not ($rec.PSObject.Properties.Name -contains 'projectPath')) { continue }
                        $resolved = Resolve-Path -LiteralPath $rec.projectPath -ErrorAction SilentlyContinue
                        if ($resolved -and $resolved.Path -eq $checkout) { $record = $rec; break }
                    }
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
    }

    if (-not $checkedConsumers.ContainsKey($checkout)) { $checkedConsumers[$checkout] = $m.repo }
}

if ($OnlyConsumer -and $matched -eq 0) {
    Write-Host "`nGeen manifest voor deze consument in het register." -ForegroundColor Yellow
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
