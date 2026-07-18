<#
.SYNOPSIS
    Regressietests voor het bootstrap-adoptiepad: de skill-bootstrap (bootstrap.ps1) en de
    persona-drift-detectie in check-consumer-drift.ps1.

.DESCRIPTION
    Dependency-vrij: geen Pester, alleen PowerShell. Integratie-stijl -- het draait de echte scripts
    tegen een wegwerp-fixture-consument in de temp-map en assert op hun exit-code + output. De
    scripts roepen zelf 'exit' aan, dus ze worden in een KINDPROCES (powershell -File) gedraaid,
    anders zou 'exit' de testrunner zelf afbreken.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/bootstrap-drift.tests.ps1

    De bootstrap seedt de lenzen op het PLUGIN-PAD (.claude/plugins/<familie>/<plugin>/) en de
    persona-lenzen zijn LENS-ONLY (geen body-kopie; de body komt via @-import uit de plugin-install).

    Puur ASCII (repo-conventie voor .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Bootstrap  = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\skills\specialists-init\bootstrap.ps1'
$DriftLint  = Join-Path $RepoRoot 'scripts\lint\check-consumer-drift.ps1'
$Integrity  = Join-Path $RepoRoot 'scripts\lint\check-plugin-integrity.ps1'
$Fixture    = Join-Path ([System.IO.Path]::GetTempPath()) 'specialists-init-test-fixture'
# Plugin-pad in een consument die vanuit de bron-repo wordt gebootstrapt (familie = claude-specialists).
$Pp         = '.claude\plugins\claude-specialists\specialists'
$PersonaSrc = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\personas\01-01-persona.md'

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

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

# Draait een .ps1 in een kindproces en geeft [pscustomobject]@{ Code; Out } terug.
function Invoke-Script {
    param([string]$Path, [string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

function Reset-Fixture {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

try {
    # --- 1. Bootstrap tegen een verse repo: lens-only persona's op het plugin-pad --------------------
    Write-Host "bootstrap.ps1 -- verse repo (plugin-pad + lens-only)" -ForegroundColor Cyan
    Reset-Fixture
    $r1 = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-Equal 0 $r1.Code 'bootstrap exit 0 op verse repo'
    foreach ($f in '01-01-extension.md', '05-05-extension.md', '05-06-extension.md') {
        Assert-True (Test-Path -LiteralPath (Join-Path $Fixture "$Pp\$f")) "persona-lens $f op het plugin-pad"
    }
    foreach ($f in '06-16-extension.md', '06-23-extension.md') {
        Assert-True (Test-Path -LiteralPath (Join-Path $Fixture "$Pp\$f")) "lens-scaffold $f op het plugin-pad"
    }
    $lensText = [System.IO.File]::ReadAllText((Join-Path $Fixture "$Pp\06-16-extension.md"), [System.Text.Encoding]::UTF8)
    Assert-True ($lensText -match 'VUL-IN') 'lens-scaffold draagt de VUL-IN-markering'
    $claudeMd = Join-Path $Fixture 'CLAUDE.md'
    Assert-True (Test-Path -LiteralPath $claudeMd) 'CLAUDE.md-scaffold aangemaakt'
    $mdText = [System.IO.File]::ReadAllText($claudeMd, [System.Text.Encoding]::UTF8)
    Assert-True ($mdText -match [regex]::Escape('@.claude/plugins/claude-specialists/specialists/01-01-extension.md')) 'CLAUDE.md draagt de lens-@-import (plugin-pad)'
    Assert-True ($mdText -match '(?m)^@[^\r\n]*personas/01-01-persona\.md') 'CLAUDE.md draagt de body-@-import (uit de plugin-install)'
    Assert-True (Test-Path -LiteralPath (Join-Path $Fixture '.claude\settings.suggested.jsonc')) 'settings.suggested.jsonc neergezet'

    # --- 1b. Persona-lens is LENS-ONLY: geen body-kopie, wel het VUL-IN-slot -------------------------
    Write-Host "persona-lens -- lens-only (geen body-kopie)" -ForegroundColor Cyan
    $srcPersona = [System.IO.File]::ReadAllText($PersonaSrc, [System.Text.Encoding]::UTF8)
    Assert-True (-not ($srcPersona -match '(?m)^## Eigen aan deze repo')) 'persona-sjabloon draagt geen ## Eigen aan deze repo-slot meer'
    $lens = [System.IO.File]::ReadAllText((Join-Path $Fixture "$Pp\01-01-extension.md"), [System.Text.Encoding]::UTF8)
    Assert-True ($lens -match 'Repo-lens \(lens-only persona\)') 'persona-lens opent met de lens-only-blockquote'
    Assert-True ($lens -match '(?m)^## Eigen aan deze repo \(VUL-IN\)') 'persona-lens draagt een vers VUL-IN-slot'
    Assert-True (-not ($lens -match 'vaste ritueel')) 'persona-lens bevat GEEN body-kopie'

    # --- 2. Idempotentie: tweede run overschrijft niets ----------------------------------------------
    Write-Host "bootstrap.ps1 -- idempotent (tweede run)" -ForegroundColor Cyan
    $r2 = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-Equal 0 $r2.Code 'tweede bootstrap exit 0'
    Assert-True ($r2.Out -match '0 persona-lens') 'tweede run zet 0 persona-lenzen (alles al aanwezig)'
    Assert-True ($r2.Out -match '0 lens-scaffold') 'tweede run zet 0 lens-scaffolds (alles al aanwezig)'
    Assert-True ($r2.Out -match 'bestaat al') 'tweede run laat bestaande lens met rust'

    # --- 2b. Versie-cache-layout: de semantisch hoogste versie wint (vondst Victor) ------------------
    # Nagebootste versie-cache: de specialists-plugin als 1.4.0, plus een sibling-domein-plugin met
    # 1.9.0 EN 1.10.0 naast elkaar -- een string-sort zou 1.9.0 kiezen, [version]-sort 1.10.0. In deze
    # layout (geen claude-code-plugins-segment) valt de familie-afleiding terug op 'davekjohns-workshop'.
    Write-Host "bootstrap.ps1 -- versie-cache kiest semantisch de hoogste versie" -ForegroundColor Cyan
    $cacheRoot = Join-Path $Fixture 'cache\davekjohns-workshop'
    $ownCache  = Join-Path $cacheRoot 'specialists\1.4.0'
    New-Item -ItemType Directory -Path $ownCache -Force | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\*') -Destination $ownCache -Recurse
    foreach ($v in '1.9.0', '1.10.0') {
        New-Item -ItemType Directory -Path (Join-Path $cacheRoot "specialists-lifehub\$v\agents") -Force | Out-Null
    }
    [System.IO.File]::WriteAllText((Join-Path $cacheRoot 'specialists-lifehub\1.9.0\agents\04-88-agent.md'), "---`nname: oudje`nid: 88`ngroup: 04`n---`nfixture")
    [System.IO.File]::WriteAllText((Join-Path $cacheRoot 'specialists-lifehub\1.10.0\agents\04-99-agent.md'), "---`nname: nieuwste`nid: 99`ngroup: 04`n---`nfixture")
    $cacheConsumer = Join-Path $Fixture 'cache-consumer'
    New-Item -ItemType Directory -Path (Join-Path $cacheConsumer '.claude') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $cacheConsumer '.claude\settings.json'), '{ "enabledPlugins": { "specialists@davekjohns-workshop": true, "specialists-lifehub@davekjohns-workshop": true } }')
    $cachedBootstrap = Join-Path $ownCache 'skills\specialists-init\bootstrap.ps1'
    $rc = Invoke-Script -Path $cachedBootstrap -ScriptArgs @('-ConsumerRoot', $cacheConsumer)
    Assert-Equal 0 $rc.Code 'versie-cache: bootstrap exit 0'
    $ppCache = '.claude\plugins\davekjohns-workshop\specialists-lifehub'
    Assert-True (Test-Path -LiteralPath (Join-Path $cacheConsumer "$ppCache\04-99-extension.md")) 'versie-cache: scaffold uit de hoogste versie (1.10.0)'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $cacheConsumer "$ppCache\04-88-extension.md"))) 'versie-cache: oudere versie (1.9.0) niet gebruikt'

    # --- 3. Drift op een verse bootstrap: LENS-ONLY (geen body om te vergelijken) --------------------
    Write-Host "check-consumer-drift.ps1 -- verse lens-only bootstrap = LENS-ONLY" -ForegroundColor Cyan
    $d1 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-Equal 0 $d1.Code 'drift exit 0 (geen agent-def-drift)'
    Assert-True ($d1.Out -match 'LENS-ONLY\] 01-01-persona') 'persona 01-01 gemeld als LENS-ONLY'
    Assert-True (-not ($d1.Out -match 'DRIFTED\]')) 'geen enkele DRIFTED op een verse bootstrap'

    # --- 3b. Root-fix #64: de indexregel is locatie-onafhankelijk (geen pad-diepte-link) ------------
    Write-Host "persona-indexregel -- locatie-onafhankelijk (inbound #64)" -ForegroundColor Cyan
    Assert-True (-not ($srcPersona -match '\]\((?:\.\./)+CLAUDE\.md\)')) 'persona-indexregel draagt geen pad-diepte-afhankelijke CLAUDE.md-link meer'

    # --- 4. Drift-vergelijking op een LEGACY body-kopie: IDENTICAL -> DRIFTED ------------------------
    # De drift-check ondersteunt nog steeds een consument met een volledige body-kopie (niet lens-only).
    # We zetten er zelf een neer (sjabloon-body + repo-lens-marker) om die vergelijking te testen.
    Write-Host "check-consumer-drift.ps1 -- legacy body-kopie: IDENTICAL, dan DRIFTED" -ForegroundColor Cyan
    $ext = Join-Path $Fixture "$Pp\01-01-extension.md"
    $fullBody = $srcPersona.TrimEnd() + "`n`n## Eigen aan deze repo (test-fixture)`n`nrepo-eigen.`n"
    [System.IO.File]::WriteAllText($ext, $fullBody, $Utf8NoBom)
    $d2 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-True ($d2.Out -match 'IDENTICAL\] 01-01-persona') 'volledige body-kopie is IDENTICAL aan de bron'
    $extText = [System.IO.File]::ReadAllText($ext, [System.Text.Encoding]::UTF8).Replace('Chief of Staff', 'OPPERBAAS-TESTWIJZIGING')
    [System.IO.File]::WriteAllText($ext, $extText, $Utf8NoBom)
    $d3 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-Equal 0 $d3.Code 'drift exit blijft 0 (persona-drift is informatief)'
    Assert-True ($d3.Out -match 'DRIFTED\]   01-01-persona') 'persona 01-01 DRIFTED na body-wijziging'

    # --- 5. Lint-smoke: de repo zelf blijft groen ----------------------------------------------------
    Write-Host "check-plugin-integrity.ps1 -- smoke" -ForegroundColor Cyan
    $li = Invoke-Script -Path $Integrity -ScriptArgs @()
    Assert-Equal 0 $li.Code 'lint-poort groen op de repo'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAALT: $($script:fail) fout, $($script:pass) goed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: alle $($script:pass) asserts geslaagd." -ForegroundColor Green
exit 0
