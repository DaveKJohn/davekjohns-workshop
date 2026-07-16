<#
.SYNOPSIS
    SessionStart-hook van de specialists-plugin: checkt bij het starten van een sessie of alle
    connectors nog in sync zijn met de workshop-bron (davekjohns-workshop).

.DESCRIPTION
    Draait in ELKE repo die de plugin heeft (consumenten en de workshop zelf). Zoekt de lokale
    workshop-checkout via een paar vaste kandidaat-paden relatief aan de projectmap en draait
    daar scripts/sync/check-connectors.ps1. De hook is bewust zacht:
      - geen workshop-checkout op deze machine -> een melding en klaar (exit 0);
      - fouten in de check -> compacte samenvatting in de sessie-context, nooit een blokkade;
      - het script eindigt ALTIJD met exit 0 -- een sessiestart mag hier nooit op stranden.

    Read-only: de hook wijzigt niets, in geen enkele repo.

.PARAMETER WorkshopPathOverride
    (Optioneel, voor tests) Kandidaat-zoektocht overslaan en dit pad als workshop gebruiken.

.PARAMETER SkipDrift
    Doorgegeven aan check-connectors.ps1 (alleen de snelle registerchecks).
#>
param(
    [string]$WorkshopPathOverride = '',
    [switch]$SkipDrift
)

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
        if (Test-Path -LiteralPath (Join-Path $c 'scripts\sync\check-connectors.ps1')) {
            $workshop = (Resolve-Path -LiteralPath $c).Path
            break
        }
    }

    if (-not $workshop) {
        Write-Host 'connectors-sessiecheck: geen workshop-checkout gevonden op deze machine -- check overgeslagen.'
        exit 0
    }

    $checkScript = Join-Path $workshop 'scripts\sync\check-connectors.ps1'
    $checkArgs = @()
    if ($SkipDrift) { $checkArgs += '-SkipDrift' }
    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $checkScript @checkArgs)
    $code = $LASTEXITCODE

    $signals = @($out | Where-Object { $_ -match '\[FOUT\]|\[INFO\]|DRIFTED' })
    if ($code -eq 0 -and $signals.Count -eq 0) {
        Write-Host 'connectors-sessiecheck: alle connectors in sync met de workshop-bron.'
    } else {
        Write-Host 'connectors-sessiecheck: signalen gevonden -- samenvatting:'
        foreach ($line in $signals) { Write-Host "  $($line.Trim())" }
        Write-Host "  (volledige uitvoer: draai scripts/sync/check-connectors.ps1 in de workshop-repo: $workshop)"
    }
} catch {
    Write-Host ('connectors-sessiecheck overgeslagen door een fout: ' + $_.Exception.Message)
}
exit 0
