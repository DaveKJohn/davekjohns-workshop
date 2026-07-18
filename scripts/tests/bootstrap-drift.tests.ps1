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

    Puur ASCII (repo-conventie voor .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Bootstrap  = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\skills\specialists-init\bootstrap.ps1'
$DriftLint  = Join-Path $RepoRoot 'scripts\lint\check-consumer-drift.ps1'
$Integrity  = Join-Path $RepoRoot 'scripts\lint\check-plugin-integrity.ps1'
$Fixture    = Join-Path ([System.IO.Path]::GetTempPath()) 'specialists-init-test-fixture'

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

# Draait een .ps1 in een kindproces en geeft [pscustomobject]@{ Code; Out } terug. Out = de
# gecombineerde stdout (incl. Write-Host van het kind). Geen 2>&1 -- de scripts schrijven op de
# happy path niet naar stderr, en 2>&1 op een native exe is in PS 5.1 juist een bron van ruis.
function Invoke-Script {
    param([string]$Path, [string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

function Reset-Fixture {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null
}

try {
    # --- 1. Bootstrap tegen een verse repo -----------------------------------------------------------
    Write-Host "bootstrap.ps1 -- verse repo" -ForegroundColor Cyan
    Reset-Fixture
    $r1 = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-Equal 0 $r1.Code 'bootstrap exit 0 op verse repo'
    foreach ($f in '01-01-extension.md', '05-05-extension.md', '05-06-extension.md') {
        Assert-True (Test-Path -LiteralPath (Join-Path $Fixture ".claude\extensions\$f")) "persona-kopie $f aangemaakt"
    }
    foreach ($f in '06-16-extension.md', '06-23-extension.md') {
        Assert-True (Test-Path -LiteralPath (Join-Path $Fixture ".claude\extensions\$f")) "lens-scaffold $f aangemaakt"
    }
    $lensText = [System.IO.File]::ReadAllText((Join-Path $Fixture '.claude\extensions\06-16-extension.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($lensText -match 'VUL-IN') 'lens-scaffold draagt de VUL-IN-markering'
    $claudeMd = Join-Path $Fixture 'CLAUDE.md'
    Assert-True (Test-Path -LiteralPath $claudeMd) 'CLAUDE.md-scaffold aangemaakt'
    $mdText = [System.IO.File]::ReadAllText($claudeMd, [System.Text.Encoding]::UTF8)
    Assert-True ($mdText -match [regex]::Escape('@.claude/extensions/01-01-extension.md')) 'CLAUDE.md draagt de orchestrator-import'
    Assert-True (Test-Path -LiteralPath (Join-Path $Fixture '.claude\settings.suggested.jsonc')) 'settings.suggested.jsonc neergezet'

    # --- 1b. Persona-slot: sjabloon schoon, bootstrap voegt VUL-IN zelf toe (inbound #69) ------------
    # Het persona-sjabloon draagt bewust geen '## Eigen aan deze repo'-slot meer (dat laadt bij een
    # lens-only consument als ruis mee); de bootstrap genereert het slot zelf bij het kopieren.
    Write-Host "persona-slot -- sjabloon schoon, bootstrap genereert VUL-IN" -ForegroundColor Cyan
    $srcPersona = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\personas\01-01-persona.md'), [System.Text.Encoding]::UTF8)
    Assert-True (-not ($srcPersona -match '(?m)^## Eigen aan deze repo')) 'persona-sjabloon draagt geen ## Eigen aan deze repo-slot meer'
    $copiedPersona = [System.IO.File]::ReadAllText((Join-Path $Fixture '.claude\extensions\01-01-extension.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($copiedPersona -match '(?m)^## Eigen aan deze repo \(VUL-IN\)') 'bootstrap-kopie krijgt een vers VUL-IN-slot'

    # --- 2. Idempotentie: tweede run overschrijft niets ----------------------------------------------
    Write-Host "bootstrap.ps1 -- idempotent (tweede run)" -ForegroundColor Cyan
    $r2 = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-Equal 0 $r2.Code 'tweede bootstrap exit 0'
    Assert-True ($r2.Out -match '0 persona') 'tweede run kopieert 0 persona (alles al aanwezig)'
    Assert-True ($r2.Out -match '0 lens-scaffold') 'tweede run zet 0 lens-scaffolds (alles al aanwezig)'
    Assert-True ($r2.Out -match 'bestaat al') 'tweede run laat bestaande kopie met rust'

    # --- 2b. Cache-layout: de semantisch hoogste versie wint (vondst Victor) -------------------------
    # Nagebootste plugin-cache: de echte specialists-plugin als 1.4.0, plus een sibling-domein-plugin
    # met 1.9.0 EN 1.10.0 naast elkaar -- een string-sort zou 1.9.0 kiezen, [version]-sort 1.10.0.
    Write-Host "bootstrap.ps1 -- cache-layout kiest semantisch de hoogste versie" -ForegroundColor Cyan
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
    Assert-Equal 0 $rc.Code 'cache-layout: bootstrap exit 0'
    Assert-True (Test-Path -LiteralPath (Join-Path $cacheConsumer '.claude\extensions\04-99-extension.md')) 'cache-layout: scaffold uit de hoogste versie (1.10.0)'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $cacheConsumer '.claude\extensions\04-88-extension.md'))) 'cache-layout: oudere versie (1.9.0) niet gebruikt'

    # --- 3. Drift op een verse kopie: IDENTICAL ------------------------------------------------------
    Write-Host "check-consumer-drift.ps1 -- verse kopie = IDENTICAL" -ForegroundColor Cyan
    $d1 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-Equal 0 $d1.Code 'drift exit 0 (geen agent-def-drift)'
    Assert-True ($d1.Out -match 'IDENTICAL\] 01-01-persona') 'persona 01-01 body IDENTICAL'
    Assert-True (-not ($d1.Out -match 'DRIFTED\]')) 'geen enkele DRIFTED op verse kopie'

    # --- 3b. Root-fix #64: de indexregel is locatie-onafhankelijk (geen pad-diepte-link) ------------
    # De persona-sjablonen dragen geen '](../../CLAUDE.md)'-link meer in de indexregel; daardoor is er
    # geen link-normalisatie meer nodig en neemt een consument de body op elk pad byte-identiek over.
    # (Vervangt de oude normalisatie-tests 3b/3c, die de inmiddels verwijderde workaround dekten.)
    Write-Host "persona-indexregel -- locatie-onafhankelijk (inbound #64)" -ForegroundColor Cyan
    $srcIndex = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\personas\01-01-persona.md'), [System.Text.Encoding]::UTF8)
    Assert-True (-not ($srcIndex -match '\]\((?:\.\./)+CLAUDE\.md\)')) 'persona-indexregel draagt geen pad-diepte-afhankelijke CLAUDE.md-link meer'

    # --- 4. Drift na een body-wijziging: DRIFTED (informatief, exit blijft 0) ------------------------
    Write-Host "check-consumer-drift.ps1 -- gewijzigde body = DRIFTED" -ForegroundColor Cyan
    $ext = Join-Path $Fixture '.claude\extensions\01-01-extension.md'
    $extText = [System.IO.File]::ReadAllText($ext, [System.Text.Encoding]::UTF8)
    # Wijzig een regel BOVEN de '## Eigen aan deze repo'-marker, zodat de draagbare body afwijkt.
    $extText = $extText.Replace('Chief of Staff', 'OPPERBAAS-TESTWIJZIGING')
    [System.IO.File]::WriteAllText($ext, $extText, (New-Object System.Text.UTF8Encoding($false)))
    $d2 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-Equal 0 $d2.Code 'drift exit blijft 0 (persona-drift is informatief)'
    Assert-True ($d2.Out -match 'DRIFTED\]   01-01-persona') 'persona 01-01 nu DRIFTED na body-wijziging'

    # --- 4b. Lens-only-model: geen body-kopie -> LENS-ONLY, niet DRIFTED (inbound #69) ---------------
    # Een consument-extension die met de '> Repo-lens (lens-only persona)'-blockquote opent heeft per
    # definitie geen body-kopie; de body komt uit de plugin. De check moet dat herkennen en de
    # persona als LENS-ONLY melden i.p.v. de (vals-positieve) DRIFTED die de body-vergelijking gaf.
    Write-Host "check-consumer-drift.ps1 -- lens-only extension = LENS-ONLY" -ForegroundColor Cyan
    $lensOnly = @'
---
id: 01
group: 01
---

# Chris -- repo-lens (lens-only persona)

> Repo-lens (lens-only persona) bij het draagbare vakboek in de plugin; de body komt uit de marketplace-clone.

## Eigen aan deze repo (test-fixture)

Repo-eigen lens-content, geen body-kopie.
'@
    [System.IO.File]::WriteAllText($ext, $lensOnly, (New-Object System.Text.UTF8Encoding($false)))
    $d3 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-Equal 0 $d3.Code 'lens-only: drift exit blijft 0'
    Assert-True ($d3.Out -match 'LENS-ONLY\] 01-01-persona') 'lens-only extension wordt als LENS-ONLY gemeld'
    Assert-True (-not ($d3.Out -match 'DRIFTED\]   01-01-persona')) 'lens-only extension niet meer als DRIFTED gemeld'

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
