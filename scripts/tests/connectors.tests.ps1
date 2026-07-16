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
    param(
        [string[]]$Extensions,
        [string]$LocalCheckout = 'onbestaand-fixture-pad',
        [string]$Plugin = 'specialists@davekjohns-workshop'
    )
    $mfPath = Join-Path $Fixture 'manifest.json'
    $obj = [ordered]@{
        repo          = 'fixture/consumer'
        visibility    = 'private'
        localCheckout = $LocalCheckout
        plugin        = $Plugin
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
    $selfManifest = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\connectors\specialists\davekjohns-workshop.json'
    $r = Invoke-Check ($base + @('-Manifest', $selfManifest))
    Assert-Equal 0 $r.Code 'self-manifest (werkplaats consumeert zichzelf): exit-code 0'

    # --- 7. Guardrails (advies Sean): manifestvelden worden niet blind vertrouwd -----------------
    # 7a. Absoluut localCheckout-pad -> geweigerd, exit 1.
    New-FixtureConsumer -ExtensionIds @('06-16')
    $mf = New-FixtureManifest -Extensions @('06-16') -LocalCheckout 'C:\Windows'
    $r = Invoke-Check ($base + @('-Manifest', $mf))
    Assert-Equal 1 $r.Code 'absoluut pad: exit-code 1'
    Assert-Match '\[FOUT\].*geweigerd' $r.Out 'absoluut pad: geweigerd-melding'

    # 7b. Pad-traversal buiten de scope-root -> geweigerd, exit 1. '..\..\..' resolvet vanaf de
    #     repo-root altijd tot boven de scope-root (= twee niveaus boven de repo-root).
    $mf = New-FixtureManifest -Extensions @('06-16') -LocalCheckout '..\..\..'
    $r = Invoke-Check ($base + @('-Manifest', $mf))
    Assert-Equal 1 $r.Code 'pad-traversal: exit-code 1'
    Assert-Match '\[FOUT\].*buiten de toegestane scope' $r.Out 'pad-traversal: scope-melding'

    # 7c. Plugin-veld met pad-tekens -> geweigerd, exit 1.
    $mf = New-FixtureManifest -Extensions @('06-16') -Plugin '..\..\evil@davekjohns-workshop'
    $r = Invoke-Check ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 1 $r.Code 'ongeldig plugin-veld: exit-code 1'
    Assert-Match '\[FOUT\].*plugin-veld' $r.Out 'ongeldig plugin-veld: FOUT-melding'

    # --- 8. Machine-record-check (zonder -SkipVersions; vondst Victor) ---------------------------
    # De administratie wordt gelezen via $env:USERPROFILE; het kindproces erft de env-var, dus we
    # wijzen die tijdelijk naar de fixture. -SkipDrift blijft aan (eigen suite).
    function Set-FixtureAdmin([string]$RecordsJson) {
        $dir = Join-Path $Fixture '.claude\plugins'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $dir 'installed_plugins.json'), $RecordsJson)
    }
    $oldProfile = $env:USERPROFILE
    try {
        # 8a. Stale record (projectPath bestaat niet) -> geen crash, INFO, exit 0.
        New-FixtureConsumer -ExtensionIds @('06-16')
        $mf = New-FixtureManifest -Extensions @('06-16')
        Set-FixtureAdmin '{ "version": 2, "plugins": { "specialists@davekjohns-workshop": [ { "scope": "project", "projectPath": "C:\\bestaat-niet-connectors-fixture", "installPath": "x", "version": "0.0.1" } ] } }'
        $env:USERPROFILE = $Fixture
        $r = Invoke-Check @('-SkipDrift', '-Manifest', $mf, '-ConsumerPathOverride', $Fixture)
        Assert-Equal 0 $r.Code 'stale record: exit-code 0 (geen crash)'
        Assert-Match '\[INFO\].*geen machine-record' $r.Out 'stale record: INFO-melding'

        # 8b. Record wijst naar de fixture maar met oudere versie dan de bron -> FOUT, exit 1.
        $fixtureEscaped = ($Fixture -replace '\\', '\\')
        Set-FixtureAdmin ('{ "version": 2, "plugins": { "specialists@davekjohns-workshop": [ { "scope": "project", "projectPath": "' + $fixtureEscaped + '", "installPath": "x", "version": "0.0.1" } ] } }')
        $r = Invoke-Check @('-SkipDrift', '-Manifest', $mf, '-ConsumerPathOverride', $Fixture)
        Assert-Equal 1 $r.Code 'verouderd record: exit-code 1'
        Assert-Match '\[FOUT\].*machine-record staat op v0\.0\.1' $r.Out 'verouderd record: FOUT-melding'
    } finally {
        $env:USERPROFILE = $oldProfile
    }

    # --- 9. SessionStart-hook (connector-sessioncheck.ps1) ---------------------------------------
    $Hook = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\hooks\connector-sessioncheck.ps1'

    # 9a. Geen workshop-checkout vindbaar -> zachte melding, exit 0 (sessie nooit blokkeren).
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Hook -WorkshopPathOverride (Join-Path $Fixture 'bestaat-niet')
    Assert-Equal 0 $LASTEXITCODE 'hook zonder workshop: exit-code 0'
    Assert-Match 'overgeslagen' ($out -join "`n") 'hook zonder workshop: overgeslagen-melding'

    # 9b. Met de echte workshop (registerchecks) -> exit 0 en een sessiecheck-regel.
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Hook -WorkshopPathOverride $RepoRoot -SkipDrift
    Assert-Equal 0 $LASTEXITCODE 'hook met workshop: exit-code 0'
    Assert-Match 'connectors-sessiecheck' ($out -join "`n") 'hook met workshop: sessiecheck-uitvoer'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
}

Write-Host "`nResultaat: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
