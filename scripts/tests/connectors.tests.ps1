<#
.SYNOPSIS
    Regressietests voor de connectors-check (scripts/sync/check-connectors.ps1) en de
    SessionStart-hook (connector-sessioncheck.ps1).

.DESCRIPTION
    Dependency-vrij: geen Pester, alleen PowerShell. Integratie-stijl -- draait de echte scripts
    in een KINDPROCES tegen wegwerp-fixtures in de temp-map en assert op exit-code + output.
    Registerchecks draaien met -SkipDrift en -SkipVersions tenzij een test juist dat codepad
    dekt (de drift-check heeft zijn eigen suite; op CI bestaat geen plugin-administratie).

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/connectors.tests.ps1

    Puur ASCII (repo-conventie voor .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\sync\check-connectors.ps1'
$Hook     = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\hooks\connector-sessioncheck.ps1'
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

function Assert-NotMatch {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -notmatch $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         patroon gevonden dat er niet mag zijn: '$Pattern'" -ForegroundColor Red
    }
}

function Invoke-Ps {
    param([string]$Path, [string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

# Bouwt een fixture-consument met settings.json + opgegeven extensions. -Layout kiest waar de
# lenzen wonen: 'legacy' (.claude/extensions/) of 'plugins'
# (.claude/plugins/claude-specialists/specialists/, sinds de life-hub-pariteit).
function New-FixtureConsumer {
    param([string[]]$ExtensionIds, [bool]$PluginEnabled = $true, [string]$Layout = 'legacy')
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    $extDir = if ($Layout -eq 'plugins') {
        Join-Path $Fixture '.claude\plugins\claude-specialists\specialists'
    } else {
        Join-Path $Fixture '.claude\extensions'
    }
    New-Item -ItemType Directory -Path $extDir -Force | Out-Null
    $enabled = if ($PluginEnabled) { '{ "specialists@davekjohns-workshop": true }' } else { '{ }' }
    $settings = '{ "enabledPlugins": ' + $enabled + ' }'
    [System.IO.File]::WriteAllText((Join-Path $Fixture '.claude\settings.json'), $settings)
    foreach ($id in $ExtensionIds) {
        $p = Join-Path $extDir "$id-extension.md"
        [System.IO.File]::WriteAllText($p, "---`nid: $($id.Split('-')[1])`ngroup: $($id.Split('-')[0])`n---`nfixture")
    }
}

# Schrijft een fixture-manifest (per-repo-schema) en geeft het pad terug.
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
        lastChecked   = '2026-01-01'
        status        = 'in-sync'
        plugins       = @(
            [ordered]@{
                id            = $Plugin
                syncedVersion = '0.0.0'
                extensions    = $Extensions
            }
        )
        notes         = ''
    }
    [System.IO.File]::WriteAllText($mfPath, ($obj | ConvertTo-Json -Depth 5))
    return $mfPath
}

# Bouwt een stub-workshop (voor de hook-tests): marker + een nep-check-script met vaste uitvoer.
function New-StubWorkshop {
    param([string]$Name, [string[]]$OutputLines, [int]$ExitCode, [bool]$ValidMarker = $true)
    $root = Join-Path $Fixture $Name
    New-Item -ItemType Directory -Path (Join-Path $root 'scripts\sync') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root '.claude-plugin') -Force | Out-Null
    $markerName = if ($ValidMarker) { 'davekjohns-workshop' } else { 'nep-marketplace' }
    [System.IO.File]::WriteAllText((Join-Path $root '.claude-plugin\marketplace.json'), ('{ "name": "' + $markerName + '" }'))
    $body = (($OutputLines | ForEach-Object { 'Write-Host "' + $_ + '"' }) -join "`r`n") + "`r`nexit $ExitCode`r`n"
    [System.IO.File]::WriteAllText((Join-Path $root 'scripts\sync\check-connectors.ps1'), $body)
    return $root
}

try {
    Write-Host "== connectors.tests ==" -ForegroundColor Cyan
    $base = @('-SkipDrift', '-SkipVersions')

    # --- 1. Happy path: alles aanwezig en enabled -> exit 0 -------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16', '06-17')
    $mf = New-FixtureManifest -Extensions @('06-16', '06-17')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 0 $r.Code 'happy path: exit-code 0'
    Assert-Match '\[OK\]\s+plugin staat aan' $r.Out 'happy path: enabled-check OK'
    Assert-Match 'alle 2 geregistreerde extensions aanwezig' $r.Out 'happy path: extensions OK'

    # --- 1b. Nieuwe lay-out: lenzen op het plugin-pad -> zelfde happy path -----------------------
    New-FixtureConsumer -ExtensionIds @('06-16', '06-17') -Layout 'plugins'
    $mf = New-FixtureManifest -Extensions @('06-16', '06-17')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 0 $r.Code 'plugin-pad: exit-code 0'
    Assert-Match 'alle 2 geregistreerde extensions aanwezig' $r.Out 'plugin-pad: extensions OK'

    # --- 2. Geregistreerde extension ontbreekt -> exit 1 ----------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16')
    $mf = New-FixtureManifest -Extensions @('06-16', '06-19')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 1 $r.Code 'ontbrekende extension: exit-code 1'
    Assert-Match '\[FOUT\].*06-19' $r.Out 'ontbrekende extension: FOUT noemt het id'

    # --- 3. Plugin niet enabled -> exit 1 --------------------------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16') -PluginEnabled $false
    $mf = New-FixtureManifest -Extensions @('06-16')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 1 $r.Code 'plugin uit: exit-code 1'
    Assert-Match '\[FOUT\].*staat NIET' $r.Out 'plugin uit: FOUT-melding'

    # --- 4. Checkout niet aanwezig -> SKIP, exit 0 -----------------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16')
    $mf = New-FixtureManifest -Extensions @('06-16') -LocalCheckout 'onbestaand-fixture-pad'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf))
    Assert-Equal 0 $r.Code 'ontbrekende checkout: exit-code 0'
    Assert-Match '\[SKIP\]' $r.Out 'ontbrekende checkout: SKIP-melding'

    # --- 5. Niet-geregistreerde extension van deze plugin -> INFO, exit 0 ------------------------
    New-FixtureConsumer -ExtensionIds @('06-16', '06-23')
    $mf = New-FixtureManifest -Extensions @('06-16')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 0 $r.Code 'niet-geregistreerd: exit-code 0 (INFO, geen fout)'
    Assert-Match "\[INFO\].*'06-23'" $r.Out 'niet-geregistreerd: INFO noemt het id'

    # --- 5b. Zelfde INFO-signaal vanaf het plugin-pad --------------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16', '06-23') -Layout 'plugins'
    $mf = New-FixtureManifest -Extensions @('06-16')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 0 $r.Code 'niet-geregistreerd op plugin-pad: exit-code 0'
    Assert-Match "\[INFO\].*'06-23'" $r.Out 'niet-geregistreerd op plugin-pad: INFO noemt het id'

    # --- 5c. -OnlyConsumer zonder manifest in het register -> INFO, exit 0 -----------------------
    #     Een verse/niet-geregistreerde consument (zoals de SessionStart-hook via -OnlyConsumer
    #     doorgeeft) hoort een informatief "niet-geregistreerd"-signaal te zien -- NIET de
    #     geruststellende "in sync"-tak. De manifest-checkout bestaat niet, dus geen enkel manifest
    #     matcht deze consument -> matched=0 (regressie: dit was een kale Write-Host die niet als
    #     info-signaal telde, waardoor de hook "alle connectors in sync" toonde).
    New-FixtureConsumer -ExtensionIds @('06-16')
    $mf = New-FixtureManifest -Extensions @('06-16') -LocalCheckout 'onbestaand-fixture-pad'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-OnlyConsumer', $Fixture))
    Assert-Equal 0 $r.Code 'onregistreerde consument: exit-code 0 (INFO, geen blokkade)'
    Assert-Match '\[INFO\].*niet-geregistreerd' $r.Out 'onregistreerde consument: niet-geregistreerd-signaal'
    Assert-Match '1 info-signa' $r.Out 'onregistreerde consument: telt als info-signaal'

    # --- 6. Echte manifesten van deze repo: het self-manifest checkt altijd ----------------------
    $selfManifest = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\connectors\davekjohns-workshop.json'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $selfManifest))
    Assert-Equal 0 $r.Code 'self-manifest (werkplaats consumeert zichzelf): exit-code 0'

    # --- 7. Guardrails (advies Sean): manifestvelden worden niet blind vertrouwd -----------------
    # 7a. Absoluut localCheckout-pad -> geweigerd, exit 1.
    New-FixtureConsumer -ExtensionIds @('06-16')
    $mf = New-FixtureManifest -Extensions @('06-16') -LocalCheckout 'C:\Windows'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf))
    Assert-Equal 1 $r.Code 'absoluut pad: exit-code 1'
    Assert-Match '\[FOUT\].*geweigerd' $r.Out 'absoluut pad: geweigerd-melding'

    # 7b. Pad-traversal buiten de scope-root -> geweigerd, exit 1. '..\..\..' resolvet vanaf de
    #     repo-root altijd tot boven de scope-root (= twee niveaus boven de repo-root).
    $mf = New-FixtureManifest -Extensions @('06-16') -LocalCheckout '..\..\..'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf))
    Assert-Equal 1 $r.Code 'pad-traversal: exit-code 1'
    Assert-Match '\[FOUT\].*buiten de toegestane scope' $r.Out 'pad-traversal: scope-melding'

    # 7c. Plugin-veld met pad-tekens -> geweigerd, exit 1.
    $mf = New-FixtureManifest -Extensions @('06-16') -Plugin '..\..\evil@davekjohns-workshop'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
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
        $r = Invoke-Ps $Script @('-SkipDrift', '-Manifest', $mf, '-ConsumerPathOverride', $Fixture)
        Assert-Equal 0 $r.Code 'stale record: exit-code 0 (geen crash)'
        Assert-Match '\[INFO\].*geen machine-record' $r.Out 'stale record: INFO-melding'

        # 8b. Record wijst naar de fixture maar met oudere versie dan de bron -> FOUT, exit 1.
        $fixtureEscaped = ($Fixture -replace '\\', '\\')
        Set-FixtureAdmin ('{ "version": 2, "plugins": { "specialists@davekjohns-workshop": [ { "scope": "project", "projectPath": "' + $fixtureEscaped + '", "installPath": "x", "version": "0.0.1" } ] } }')
        $r = Invoke-Ps $Script @('-SkipDrift', '-Manifest', $mf, '-ConsumerPathOverride', $Fixture)
        Assert-Equal 1 $r.Code 'verouderd record: exit-code 1'
        Assert-Match '\[FOUT\].*machine-record staat op v0\.0\.1' $r.Out 'verouderd record: FOUT-melding'
    } finally {
        $env:USERPROFILE = $oldProfile
    }

    # --- 9. SessionStart-hook (connector-sessioncheck.ps1) ---------------------------------------
    # 9a. Geen workshop-checkout vindbaar -> zachte melding, exit 0 (sessie nooit blokkeren).
    New-FixtureConsumer -ExtensionIds @('06-16')
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', (Join-Path $Fixture 'bestaat-niet'))
    Assert-Equal 0 $r.Code 'hook zonder workshop: exit-code 0'
    Assert-Match 'overgeslagen' $r.Out 'hook zonder workshop: overgeslagen-melding'

    # 9b. Met de echte workshop: integratie-smoke. Welke tak (in-sync of signalen) hangt af van
    #     de actuele register-staat van de repo (bv. manifesten die na een release-bump nog niet
    #     bijgewerkt zijn) -- die is hier bewust niet ge-assert; de takken zelf worden
    #     deterministisch gedekt door de stub-tests 9c en 9d (les van CI-run PR #54).
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $RepoRoot, '-SkipDrift', '-SkipVersions')
    Assert-Equal 0 $r.Code 'hook met workshop: exit-code 0'
    Assert-Match 'connectors-sessiecheck:' $r.Out 'hook met workshop: sessiecheck-uitvoer'

    # 9c. Stub-workshop met schone uitvoer incl. boilerplate-drifted-regels (vondst Victor):
    #     de kale samenvattingsregels mogen NIET als signaal tellen.
    $stub = New-StubWorkshop -Name 'stub-schoon' -ExitCode 0 -OutputLines @(
        '  [OK]    alles goed',
        'Samenvatting agent-defs: 19 missing, 0 identical (dode kopieen), 0 drifted.',
        'Persona-drift is INFORMATIEF (telt niet mee in de exit-code): 0 drifted.'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'stub schoon: exit-code 0'
    Assert-Match 'geen fouten' $r.Out 'stub schoon: boilerplate telt niet als signaal'

    # 9c2. Stub-workshop met alleen INFO-regels -> OK-tak, geen sessie-alert (wens Dave,
    #      20 juli 2026): INFO is registeradministratie over consumenten-sync (vaak een andere
    #      machine/gebruiker) en hoort niet bij elke sessiestart gemeld te worden.
    $stub = New-StubWorkshop -Name 'stub-info' -ExitCode 0 -OutputLines @(
        '  [INFO]  manifest is gesynct op v1.5.0, bron staat op v1.10.0 -- sync en manifest bijwerken.',
        '  [INFO]  extension 06-24 bestaat in de consument maar staat niet in het register.'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'stub info: exit-code 0'
    Assert-Match 'geen fouten' $r.Out 'stub info: OK-tak (INFO geeft geen sessie-alert)'
    Assert-NotMatch 'gesynct op v1\.5\.0' $r.Out 'stub info: INFO-regel NIET doorgegeven'

    # 9d. Stub-workshop met een echte FOUT -> signalen-tak, regel komt door.
    $stub = New-StubWorkshop -Name 'stub-fout' -ExitCode 1 -OutputLines @(
        '  [FOUT]  fixture-fout'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'stub fout: exit-code 0 (hook blokkeert nooit)'
    Assert-Match 'signalen gevonden' $r.Out 'stub fout: signalen-tak'
    Assert-Match 'fixture-fout' $r.Out 'stub fout: FOUT-regel doorgegeven'

    # 9d2. Stub met FOUT én INFO in dezelfde run -> de FOUT komt door, de INFO blijft weg
    #      (het gevoeligste regressie-scenario voor de scheiding, vondst Victor).
    $stub = New-StubWorkshop -Name 'stub-mix' -ExitCode 1 -OutputLines @(
        '  [FOUT]  fixture-mix-fout',
        '  [INFO]  fixture-mix-info'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Match 'fixture-mix-fout' $r.Out 'stub mix: FOUT-regel doorgegeven'
    Assert-NotMatch 'fixture-mix-info' $r.Out 'stub mix: INFO-regel NIET doorgegeven'

    # 9e. Marker-check (guardrail Sean): kandidaat-pad zonder geldige marker wordt NIET uitgevoerd.
    $stub = New-StubWorkshop -Name 'stub-nep' -ExitCode 0 -ValidMarker $false -OutputLines @(
        'FAKE-EXECUTED'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'nep-workshop: exit-code 0'
    Assert-Match 'overgeslagen' $r.Out 'nep-workshop: geweigerd als workshop'
    Assert-NotMatch 'FAKE-EXECUTED' $r.Out 'nep-workshop: script is NIET uitgevoerd'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
}

Write-Host "`nResultaat: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
