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

    # --- 1c. scripts/-scaffolds voor de gedeelde workflow-skills (#86): repo-config + branch-info ----
    Write-Host "bootstrap.ps1 -- script-config-scaffolds (#86)" -ForegroundColor Cyan
    $rcScaffold = Join-Path $Fixture 'scripts\repo-config.ps1'
    $biScaffold = Join-Path $Fixture 'scripts\lib\branch-info.ps1'
    Assert-True (Test-Path -LiteralPath $rcScaffold) 'scripts/repo-config.ps1-scaffold neergezet'
    Assert-True (Test-Path -LiteralPath $biScaffold) 'scripts/lib/branch-info.ps1-scaffold neergezet'
    $rcText = [System.IO.File]::ReadAllText($rcScaffold, [System.Text.Encoding]::UTF8)
    Assert-True ($rcText -match 'VUL-IN') 'repo-config-scaffold draagt de VUL-IN-markering'
    Assert-True ($rcText -match 'function Get-RepoName') 'repo-config-scaffold levert Get-RepoName'
    $biText = [System.IO.File]::ReadAllText($biScaffold, [System.Text.Encoding]::UTF8)
    Assert-True ($biText -match '\$script:BranchPrefixTable = @\{\s*\}') 'branch-info-scaffold heeft een LEGE prefix-tabel (geen repo-taxonomie meegebakken)'

    # --- 1d. RepoName afgeleid uit de git-remote (origin) van de consument (Gat B) -------------------
    # Een consument die een git-repo is met een github.com-origin krijgt RepoName voor-ingevuld i.p.v.
    # de VUL-IN-placeholder; niet-github of geen remote -> terugval op VUL-IN. De git-aanroep mag de
    # bootstrap nooit laten crashen. Elke case draait in een eigen wegwerp-git-repo.
    Write-Host "bootstrap.ps1 -- RepoName afgeleid uit de git-remote (origin)" -ForegroundColor Cyan
    function Test-DerivedRepoName {
        param([string]$OriginUrl, [string]$Expected, [bool]$ShouldDerive, [string]$Label)
        $gitFix = Join-Path ([System.IO.Path]::GetTempPath()) ('specialists-init-git-' + $Label)
        if (Test-Path -LiteralPath $gitFix) { Remove-Item -Recurse -Force -LiteralPath $gitFix }
        New-Item -ItemType Directory -Path $gitFix -Force | Out-Null
        try {
            & git -C $gitFix init -q 2>$null | Out-Null
            if ($OriginUrl) { & git -C $gitFix remote add origin $OriginUrl 2>$null | Out-Null }
            $rg = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $gitFix)
            Assert-Equal 0 $rg.Code "git-afleiding ($Label): bootstrap exit 0"
            $txt = [System.IO.File]::ReadAllText((Join-Path $gitFix 'scripts\repo-config.ps1'), [System.Text.Encoding]::UTF8)
            if ($ShouldDerive) {
                Assert-True ($txt -match [regex]::Escape("`$script:RepoName = '$Expected'")) "git-afleiding ($Label): RepoName = $Expected"
                Assert-True (-not ($txt -match "RepoName = 'VUL-IN")) "git-afleiding ($Label): geen VUL-IN op de RepoName-regel"
            } else {
                Assert-True ($txt -match "RepoName = 'VUL-IN/repo'") "git-afleiding ($Label): terugval op VUL-IN/repo"
            }
        } finally {
            if (Test-Path -LiteralPath $gitFix) { Remove-Item -Recurse -Force -LiteralPath $gitFix -ErrorAction SilentlyContinue }
        }
    }
    # Isoleer de git-config met een lege global/system-config: CI-runners zetten een globale insteadOf
    # die de vorm van get-url herschrijft (git@github.com: -> https, soms met token-userinfo, soms
    # ssh://). Zo test elke case echt de bedoelde URL-vorm. De regex in de bootstrap dekt bovendien
    # alle vormen, dus ook zonder isolatie zou de afleiding kloppen -- dit maakt de labels alleen eerlijk.
    $emptyGitCfg = Join-Path $Fixture 'empty-gitconfig'
    [System.IO.File]::WriteAllText($emptyGitCfg, '')
    $oldGCG = $env:GIT_CONFIG_GLOBAL; $oldGCS = $env:GIT_CONFIG_SYSTEM
    $env:GIT_CONFIG_GLOBAL = $emptyGitCfg; $env:GIT_CONFIG_SYSTEM = $emptyGitCfg
    try {
        Test-DerivedRepoName -OriginUrl 'https://github.com/DaveKJohn/mijn-repo.git' -Expected 'DaveKJohn/mijn-repo' -ShouldDerive $true  -Label 'https'
        Test-DerivedRepoName -OriginUrl 'git@github.com:DaveKJohn/mijn-repo.git'    -Expected 'DaveKJohn/mijn-repo' -ShouldDerive $true  -Label 'ssh'
        Test-DerivedRepoName -OriginUrl 'ssh://git@github.com/DaveKJohn/mijn-repo.git' -Expected 'DaveKJohn/mijn-repo' -ShouldDerive $true -Label 'ssh-scheme'
        # Credential-embedded https (zoals een CI-token-rewrite): owner/repo wordt afgeleid, de userinfo weggegooid.
        Test-DerivedRepoName -OriginUrl 'https://x-access-token:SECRET@github.com/DaveKJohn/mijn-repo.git' -Expected 'DaveKJohn/mijn-repo' -ShouldDerive $true -Label 'https-cred'
        Test-DerivedRepoName -OriginUrl 'https://gitlab.com/DaveKJohn/mijn-repo.git' -Expected '' -ShouldDerive $false -Label 'niet-github'
        Test-DerivedRepoName -OriginUrl ''                                          -Expected '' -ShouldDerive $false -Label 'geen-remote'
    } finally {
        if ($null -eq $oldGCG) { Remove-Item Env:GIT_CONFIG_GLOBAL -ErrorAction SilentlyContinue } else { $env:GIT_CONFIG_GLOBAL = $oldGCG }
        if ($null -eq $oldGCS) { Remove-Item Env:GIT_CONFIG_SYSTEM -ErrorAction SilentlyContinue } else { $env:GIT_CONFIG_SYSTEM = $oldGCS }
    }

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
    Assert-True ($r2.Out -match '0 script-scaffold') 'tweede run zet 0 script-scaffolds (#86, alles al aanwezig)'
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

    # --- 2c. Durabel body-pad: cache-install -> @-import wijst naar de marketplaces-clone (Gat C) -----
    # Bootst de echte user-scope layout na: .../plugins/cache/<mp>/<plugin>/<versie>/ naast een
    # versie-loze .../plugins/marketplaces/<mp>/-clone. De geschreven @-import in CLAUDE.md moet naar de
    # clone wijzen (durabel, overleeft een update), NIET naar de versie-gepinde cache (die na een update
    # wordt opgeruimd -> Chris' body zou niet meer laden).
    Write-Host "bootstrap.ps1 -- durabel body-pad (cache -> marketplaces-clone)" -ForegroundColor Cyan
    $pluginsRoot = Join-Path $Fixture 'plugins'
    $mp = 'mp-fixture'
    $cacheInit = Join-Path $pluginsRoot "cache\$mp\specialists\9.9.9"
    New-Item -ItemType Directory -Path $cacheInit -Force | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\*') -Destination $cacheInit -Recurse
    # Versie-loze marketplaces-clone met (minimaal) de personas onder claude-code-plugins/<familie>/<plugin>/.
    $cloneP = Join-Path $pluginsRoot "marketplaces\$mp\claude-code-plugins\claude-specialists\specialists\personas"
    New-Item -ItemType Directory -Path $cloneP -Force | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\personas\*') -Destination $cloneP -Recurse
    $durConsumer = Join-Path $Fixture 'durable-consumer'
    New-Item -ItemType Directory -Path $durConsumer -Force | Out-Null
    $rd = Invoke-Script -Path (Join-Path $cacheInit 'skills\specialists-init\bootstrap.ps1') -ScriptArgs @('-ConsumerRoot', $durConsumer)
    Assert-Equal 0 $rd.Code 'durabel body-pad: bootstrap exit 0'
    $durMd = [System.IO.File]::ReadAllText((Join-Path $durConsumer 'CLAUDE.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($durMd -match [regex]::Escape("marketplaces/$mp/claude-code-plugins/claude-specialists/specialists/personas/01-01-persona.md")) 'durabel body-pad: @-import wijst naar de marketplaces-clone'
    Assert-True (-not ($durMd -match '/cache/')) 'durabel body-pad: @-import wijst NIET naar de versie-gepinde cache'

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
