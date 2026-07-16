<#
.SYNOPSIS
    Regressietests voor de connectors-check (scripts/sync/check-connectors.ps1).

.DESCRIPTION
    Dependency-vrij: geen Pester, alleen PowerShell. Integratie-stijl -- draait het echte script
    in een KINDPROCES tegen een wegwerp-fixture-consument in de temp-map en assert op exit-code +
    output. Alle runs met -SkipDrift en -SkipVersions: de drift-check heeft zijn eigen suite, en
    op CI bestaat geen plugin-administratie.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/connectors.tests.ps1

    Puur ASCII (repo-conventie voor .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\sync\check-connectors.ps1'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) 'connectors-test-fixture'

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         verwacht: '$Expected'`n         kreeg:    '$Actual'" -ForegroundColor Red
    }
}

function Assert-Match {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         patroon niet gevonden: '$Pattern'" -ForegroundColor Red
    }
}

function Invoke-Check {
    param([string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

# Bouwt een fixture-consument met settings.json + opgegeven extensions.
function New-FixtureConsumer {
    param([string[]]$ExtensionIds, [bool]$PluginEnabled = $true)
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path (Join-Path $Fixture '.claude\extensions') -Force | Out-Null
    $enabled = if ($PluginEnabled) { '{ "specialists@davekjohns-workshop": true }' } else { '{ }' }
    $settings = '{ "enabledPlugins": ' + $enabled + ' }'
    [System.IO.File]::WriteAllText((Join-Path $Fixture '.claude\settings.json'), $settings)
    foreach ($id in $ExtensionIds) {
        $p = Join-Path $Fixture ".claude\extensions\$id-extension.md"
        [System.IO.File]::WriteAllText($p, "---`nid: $($id.Split('-')[1])`ngroup: $($id.Split('-')[0])`n---`nfixture")
    }
}

# Schrijft een fixture-manifest en geeft het pad terug.
function New-FixtureManifest {
    param([string[]]$Extensions, [string]$LocalCheckout = 'onbestaand-fixture-pad')
    $mfPath = Join-Path $Fixture 'manifest.json'
    $obj = [ordered]@{
        repo          = 'fixture/consumer'
        visibility    = 'private'
        localCheckout = $LocalCheckout
        plugin        = 'specialists@davekjohns-workshop'
        syncedVersion = '0.0.0'
        lastChecked   = '2026-01-01'
        status        = 'in-sync'
        extensions    = $Extensions
        notes         = ''
    }
    [System.IO.File]::WriteAllText($mfPath, ($obj | ConvertTo-Json))
    return $mfPath
}

try {
    Write-Host "== connectors.tests ==" -ForegroundColor Cyan
    $base = @('-SkipDrift', '-SkipVersions')

    # --- 1. Happy path: alles aanwezig en enabled -> exit 0 -------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16', '06-17')
    $mf = New-FixtureManifest -Extensions @('06-16', '06-17')
    $r = Invoke-Check ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 0 $r.Code 'happy path: exit-code 0'
    Assert-Match '\[OK\]\s+plugin staat aan' $r.Out 'happy path: enabled-check OK'
    Assert-Match 'alle 2 geregistreerde extensions aanwezig' $r.Out 'happy path: extensions OK'

    # --- 2. Geregistreerde extension ontbreekt -> exit 1 ----------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16')
    $mf = New-FixtureManifest -Extensions @('06-16', '06-19')
    $r = Invoke-Check ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 1 $r.Code 'ontbrekende extension: exit-code 1'
    Assert-Match '\[FOUT\].*06-19' $r.Out 'ontbrekende extension: FOUT noemt het id'

    # --- 3. Plugin niet enabled -> exit 1 --------------------------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16') -PluginEnabled $false
    $mf = New-FixtureManifest -Extensions @('06-16')
    $r = Invoke-Check ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 1 $r.Code 'plugin uit: exit-code 1'
    Assert-Match '\[FOUT\].*staat NIET' $r.Out 'plugin uit: FOUT-melding'

    # --- 4. Checkout niet aanwezig -> SKIP, exit 0 -----------------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16')
    $mf = New-FixtureManifest -Extensions @('06-16') -LocalCheckout 'onbestaand-fixture-pad'
    $r = Invoke-Check ($base + @('-Manifest', $mf))
    Assert-Equal 0 $r.Code 'ontbrekende checkout: exit-code 0'
    Assert-Match '\[SKIP\]' $r.Out 'ontbrekende checkout: SKIP-melding'

    # --- 5. Niet-geregistreerde extension van deze plugin -> INFO, exit 0 ------------------------
    New-FixtureConsumer -ExtensionIds @('06-16', '06-23')
    $mf = New-FixtureManifest -Extensions @('06-16')
    $r = Invoke-Check ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 0 $r.Code 'niet-geregistreerd: exit-code 0 (INFO, geen fout)'
    Assert-Match "\[INFO\].*'06-23'" $r.Out 'niet-geregistreerd: INFO noemt het id'

    # --- 6. Echte manifesten van deze repo: het self-manifest checkt altijd ----------------------
    $selfManifest = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\connectors\davekjohns-workshop.json'
    $r = Invoke-Check ($base + @('-Manifest', $selfManifest))
    Assert-Equal 0 $r.Code 'self-manifest (werkplaats consumeert zichzelf): exit-code 0'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
}

Write-Host "`nResultaat: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
