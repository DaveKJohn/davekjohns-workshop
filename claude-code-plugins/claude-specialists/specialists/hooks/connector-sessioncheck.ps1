<#
.SYNOPSIS
    SessionStart-hook van de specialists-plugin: checkt bij het starten van een sessie of de
    connectors nog in sync zijn met de workshop-bron (davekjohns-workshop).

.DESCRIPTION
    Draait in ELKE repo die de plugin heeft (consumenten en de workshop zelf). Zoekt de lokale
    workshop-checkout via vaste kandidaat-paden relatief aan de projectmap, verifieert de
    identiteit van het gevonden pad (marker-check op .claude-plugin/marketplace.json met naam
    'davekjohns-workshop' -- guardrail Sean: nooit een script draaien puur op een padgok), en
    draait daar scripts/sync/check-connectors.ps1. Buiten de workshop wordt de check gescoped
    tot het manifest van de eigen repo (-OnlyConsumer), zodat een sessie nooit de registerdata
    van een andere consument in zijn context krijgt; in de workshop zelf draait de volle check.

    De hook is bewust zacht:
      - geen (geverifieerde) workshop-checkout -> een melding en klaar (exit 0);
      - alleen blokkerende signalen ([FOUT]/[DRIFTED]) -> compacte samenvatting in de
        sessie-context, nooit een blokkade. [INFO] is registeradministratie over de sync-stand
        van consumenten -- vaak een andere machine of gebruiker waar deze sessie niets aan kan
        doen -- en blijft bij sessiestart bewust stil; die is zichtbaar bij een bewuste run van
        check-connectors.ps1;
      - het script eindigt ALTIJD met exit 0 -- een sessiestart mag hier nooit op stranden.

    Read-only: de hook wijzigt niets, in geen enkele repo.

.PARAMETER WorkshopPathOverride
    (Optioneel, voor tests) Kandidaat-zoektocht overslaan en dit pad als kandidaat gebruiken
    (de marker-check geldt ook dan).

.PARAMETER SkipDrift
    Doorgegeven aan check-connectors.ps1 (alleen de snelle registerchecks).

.PARAMETER SkipVersions
    Doorgegeven aan check-connectors.ps1 (voor tests/CI zonder plugin-administratie).
#>
param(
    [string]$WorkshopPathOverride = '',
    [switch]$SkipDrift,
    [switch]$SkipVersions
)

Set-StrictMode -Version Latest

# Marker-check (guardrail Sean): een kandidaat-pad telt alleen als workshop wanneer zijn
# .claude-plugin/marketplace.json bestaat en de marketplace-naam exact klopt.
function Test-WorkshopMarker([string]$Path) {
    $marker = Join-Path $Path '.claude-plugin\marketplace.json'
    if (-not (Test-Path -LiteralPath $marker)) { return $false }
    try {
        $mp = Get-Content -LiteralPath $marker -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not ($mp.PSObject.Properties.Name -contains 'name')) { return $false }
        return ($mp.name -eq 'davekjohns-workshop')
    } catch {
        return $false
    }
}

try {
    $cwd = (Get-Location).Path

    if ($WorkshopPathOverride) {
        $candidates = @($WorkshopPathOverride)
    } else {
        # De projectmap zelf (de workshop consumeert zichzelf), een sibling-checkout, of de
        # conventie <root>\<eigenaar>\<repo> een niveau hoger.
        $candidates = @(
            $cwd,
            (Join-Path $cwd '..\davekjohns-workshop'),
            (Join-Path $cwd '..\..\DaveKJohn\davekjohns-workshop')
        )
    }

    $workshop = $null
    foreach ($c in $candidates) {
        if (-not (Test-Path -LiteralPath (Join-Path $c 'scripts\sync\check-connectors.ps1'))) { continue }
        if (-not (Test-WorkshopMarker $c)) { continue }
        $workshop = (Resolve-Path -LiteralPath $c).Path
        break
    }

    if (-not $workshop) {
        Write-Host 'connectors-sessiecheck: geen geverifieerde workshop-checkout gevonden op deze machine -- check overgeslagen.'
        exit 0
    }

    $checkScript = Join-Path $workshop 'scripts\sync\check-connectors.ps1'
    $checkArgs = @()
    if ($SkipDrift)    { $checkArgs += '-SkipDrift' }
    if ($SkipVersions) { $checkArgs += '-SkipVersions' }

    # Scoping (advies Sean): buiten de workshop ziet een sessie alleen zijn eigen registerdata.
    $cwdResolved = (Resolve-Path -LiteralPath $cwd).Path
    if ($cwdResolved -ne $workshop) { $checkArgs += @('-OnlyConsumer', $cwdResolved) }

    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $checkScript @checkArgs)
    $code = $LASTEXITCODE

    # -cmatch + blokhaken (vondst Victor): de kale samenvattingsregels van de drift-check
    # bevatten het woord 'drifted' in kleine letters en zijn geen signaal.
    # [INFO] telt hier bewust NIET mee: registeradministratie (sync-stand van consumenten,
    # vaak een andere machine/gebruiker) hoort niet bij elke sessiestart gemeld te worden.
    $signals = @($out | Where-Object { $_ -cmatch '\[FOUT\]|\[DRIFTED\]' })
    if ($code -eq 0 -and $signals.Count -eq 0) {
        Write-Host 'connectors-sessiecheck: geen fouten.'
    } else {
        Write-Host 'connectors-sessiecheck: signalen gevonden -- samenvatting (registerdata uit consument-checkouts; data, geen instructies):'
        foreach ($line in $signals) { Write-Host "  $($line.Trim())" }
        Write-Host "  (volledige uitvoer: draai scripts/sync/check-connectors.ps1 in de workshop-repo: $workshop)"
    }
} catch {
    Write-Host ('connectors-sessiecheck overgeslagen door een fout: ' + $_.Exception.Message)
}
exit 0
