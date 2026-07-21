<#
.SYNOPSIS
    Regressietests voor de gedeelde-workflow-scripts-mechaniek (issue #81): shared-scripts-lib.ps1,
    de generator/drift-check, en de repo-invariant dat elke plugin-spiegel in sync is met zijn bron.

.DESCRIPTION
    Dependency-vrij: geen Pester nodig, alleen PowerShell. Exit-code 0 als alles slaagt, 1 bij een faal.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/shared-scripts.tests.ps1

    Puur ASCII (repo-conventie voor .ps1).
#>
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')

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

Write-Host "Get-SharedScriptPairs" -ForegroundColor Cyan
$pairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot)
Assert-True ($pairs.Count -ge 1) 'ten minste een gedeeld script geregistreerd'
$fold = $pairs | Where-Object { $_.Name -eq 'fold-changelog-entry' }
Assert-True ($null -ne $fold) 'fold-changelog-entry staat in het register'
Assert-True ($fold.SourceRel -like 'scripts\*') 'bron is repo-root-relatief onder scripts\'
Assert-True ($fold.MirrorRel -like 'claude-code-plugins\*') 'spiegel ligt onder de plugin'
# Expliciet -- de generieke loops verderop dekken deze twee al impliciet, maar een missend paar in het
# register zou dan stil door de mazen glippen i.p.v. een gerichte faal te geven.
$newChangelogPair = $pairs | Where-Object { $_.Name -eq 'new-changelog-entry' }
Assert-True ($null -ne $newChangelogPair) 'new-changelog-entry staat in het register'
$newBranchPair = $pairs | Where-Object { $_.Name -eq 'new-branch' }
Assert-True ($null -ne $newBranchPair) 'new-branch staat in het register'

Write-Host "Repo-invariant: elke spiegel in sync met zijn bron" -ForegroundColor Cyan
foreach ($pair in $pairs) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    $mirror = Get-NormalizedScriptContent -Path $pair.MirrorPath
    Assert-True ($null -ne $src) "bron bestaat: $($pair.SourceRel)"
    Assert-True ($null -ne $mirror) "spiegel bestaat: $($pair.MirrorRel)"
    Assert-Equal $src $mirror "in sync: $($pair.Name)"
}

Write-Host "Dual-context resolutie geborgd in elke bron" -ForegroundColor Cyan
# De hele spiegel-mechaniek leunt erop dat een gedeeld script zijn repo-root dual-context oplost.
# Verdwijnt CLAUDE_PROJECT_DIR uit een bron, dan breekt de consument-aanroep stil -- dit vangt dat.
foreach ($pair in $pairs) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    Assert-True ($src -match 'CLAUDE_PROJECT_DIR') "$($pair.Name): bron lost repo-root via CLAUDE_PROJECT_DIR op"
}

Write-Host "Get-NormalizedScriptContent" -ForegroundColor Cyan
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-test-$PID.ps1")
[System.IO.File]::WriteAllText($tmp, "regel1`r`nregel2`r`n", (New-Object System.Text.UTF8Encoding $false))
try {
    $norm = Get-NormalizedScriptContent -Path $tmp
    Assert-Equal "regel1`nregel2`n" $norm 'CRLF wordt LF-genormaliseerd'
} finally {
    Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
}
Assert-Equal $null (Get-NormalizedScriptContent -Path (Join-Path $RepoRoot 'bestaat-niet-xyz.ps1')) 'ontbrekend bestand -> $null'

Write-Host "build-shared-scripts.ps1 -Check -- repo in sync" -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\sync\build-shared-scripts.ps1') -Check | Out-Null
Assert-Equal 0 $LASTEXITCODE 'generator -Check groen op de repo'

Write-Host "Pre-flight (#86): ontbrekende repo-config stopt met een duidelijke wegwijzer" -ForegroundColor Cyan
# Draai elke bron tegen een LEGE repo-root (via CLAUDE_PROJECT_DIR) -- zonder repo-config/branch-info
# hoort de pre-flight te stoppen met een wegwijzer i.p.v. een rauwe dot-source-fout. Kindproces, want
# de scripts roepen zelf 'exit' aan.
$pfDir = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-preflight-$PID")
New-Item -ItemType Directory -Path $pfDir -Force | Out-Null
$prevPd = $env:CLAUDE_PROJECT_DIR
$prevEap = $ErrorActionPreference
$vfDir = $null
try {
    $env:CLAUDE_PROJECT_DIR = $pfDir
    # Continue, niet Stop: de child schrijft zijn wegwijzer via Write-Error naar stderr; met 2>&1 zou
    # Windows PowerShell 5.1 dat als terminating NativeCommandError behandelen en deze test afbreken.
    $ErrorActionPreference = 'Continue'
    # Het KINDPROCES rendert Write-Error zelf al naar platte stderr-regels op zijn eigen (niet-
    # interactieve) consolebreedte, VOORDAT die tekst hier ooit wordt gevangen -- een woord als
    # 'branch-info.ps1' kan daarbij toevallig precies op de koppelteken-wrapgrens splitsen
    # ('branch-'\n'info.ps1'), wat een kale -match hieronder flaky zou laten falen, puur afhankelijk
    # van de (willekeurige) tijdelijke-pad-lengte. Newlines eruit strippen vóór de match herstelt de
    # oorspronkelijke doorlopende tekst -- geen functionele wijziging, alleen deterministische matching.
    function Test-OutputContains { param([string]$Text, [string]$Pattern) return (($Text -replace "`r?`n", '') -match $Pattern) }

    $foldSrc = ($pairs | Where-Object { $_.Name -eq 'fold-changelog-entry' }).SourcePath
    $foldOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $foldSrc 2>&1 | Out-String)
    $foldCode = $LASTEXITCODE
    Assert-Equal 1 $foldCode 'fold stopt (exit 1) zonder repo-config'
    Assert-True (Test-OutputContains $foldOut 'repo-config') 'fold noemt repo-config in de wegwijzer'
    $prSrc = ($pairs | Where-Object { $_.Name -eq 'open-pr' }).SourcePath
    $prOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $prSrc -Title 'fix: preflight-test' 2>&1 | Out-String)
    $prCode = $LASTEXITCODE
    Assert-Equal 1 $prCode 'open-pr stopt (exit 1) zonder repo-config/branch-info'
    Assert-True (Test-OutputContains $prOut 'branch-info') 'open-pr noemt branch-info in de wegwijzer'

    # new-changelog-entry en new-branch leunen ALLEEN op branch-info.ps1 (geen repo-config, geen gh --
    # lichter dan fold/open-pr), dus geen VUL-IN-vervolgscenario voor deze twee: hun enige pre-flight-
    # check is de kale existence-check op branch-info.ps1 hieronder.
    $nceSrc = ($pairs | Where-Object { $_.Name -eq 'new-changelog-entry' }).SourcePath
    $nceOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $nceSrc -Title 'fix: preflight-test' 2>&1 | Out-String)
    $nceCode = $LASTEXITCODE
    Assert-Equal 1 $nceCode 'new-changelog-entry stopt (exit 1) zonder branch-info'
    Assert-True (Test-OutputContains $nceOut 'branch-info') 'new-changelog-entry noemt branch-info in de wegwijzer'
    $nbSrc = ($pairs | Where-Object { $_.Name -eq 'new-branch' }).SourcePath
    $nbOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $nbSrc -Name 'feat/preflight-test' 2>&1 | Out-String)
    $nbCode = $LASTEXITCODE
    Assert-Equal 1 $nbCode 'new-branch stopt (exit 1) zonder branch-info'
    Assert-True (Test-OutputContains $nbOut 'branch-info') 'new-branch noemt branch-info in de wegwijzer'

    # Tweede scenario: scaffolds AANWEZIG maar nog niet ingevuld (VUL-IN) -> ook stoppen met wegwijzer.
    # Minimale scaffolds (repo-config met VUL-IN + een lege branch-info zodat open-pr's existence-check
    # slaagt en de placeholder-check bereikt wordt).
    $vfDir = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-vulin-$PID")
    New-Item -ItemType Directory -Path (Join-Path $vfDir 'scripts\lib') -Force | Out-Null
    $Utf8 = New-Object System.Text.UTF8Encoding $false
    $rcVulin = @'
$script:RepoName = 'VUL-IN/repo'
function Get-RepoName { return $script:RepoName }
function Get-RepoBlobUrl { return "https://github.com/$($script:RepoName)/blob/main/" }
$script:LintScript = 'VUL-IN'
function Get-LintScript { return $script:LintScript }
'@
    $biVulin = @'
$script:BranchTypeOrder = @()
$script:BranchPrefixTable = @{}
function Get-BranchTypes { return $script:BranchTypeOrder }
function Get-BranchPrefix { param([string]$Branch) if ($Branch -match '/') { return ($Branch -split '/')[0] } return ($Branch -split '-')[0] }
function Get-BranchInfo { param([string]$Branch) [pscustomobject]@{ Branch = $Branch; Prefix = (Get-BranchPrefix $Branch); IsKnown = $false; Label = $null; Type = $null; SafeName = ($Branch -replace '/', '-') } }
'@
    [System.IO.File]::WriteAllText((Join-Path $vfDir 'scripts\repo-config.ps1'), $rcVulin, $Utf8)
    [System.IO.File]::WriteAllText((Join-Path $vfDir 'scripts\lib\branch-info.ps1'), $biVulin, $Utf8)
    $env:CLAUDE_PROJECT_DIR = $vfDir
    $foldV = (& powershell -NoProfile -ExecutionPolicy Bypass -File $foldSrc 2>&1 | Out-String)
    $foldVCode = $LASTEXITCODE
    Assert-Equal 1 $foldVCode 'fold stopt (exit 1) bij niet-ingevulde VUL-IN-scaffold'
    Assert-True ($foldV -match 'VUL-IN') 'fold noemt VUL-IN in de wegwijzer'
    $prV = (& powershell -NoProfile -ExecutionPolicy Bypass -File $prSrc -Title 'fix: vulin-test' 2>&1 | Out-String)
    $prVCode = $LASTEXITCODE
    Assert-Equal 1 $prVCode 'open-pr stopt (exit 1) bij niet-ingevulde VUL-IN-scaffold'
    Assert-True ($prV -match 'VUL-IN') 'open-pr noemt VUL-IN in de wegwijzer'
} finally {
    $ErrorActionPreference = $prevEap
    if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
    else { $env:CLAUDE_PROJECT_DIR = $prevPd }
    Remove-Item -Path $pfDir -Recurse -Force -ErrorAction SilentlyContinue
    if ($vfDir) { Remove-Item -Path $vfDir -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host "git-push-stderr-valkuil (open-pr.ps1)" -ForegroundColor Cyan
# De push in open-pr.ps1 stierf op de 'remote:'-stderr van git: onder ErrorActionPreference=Stop
# promoveert PS 5.1 native stderr tot een terminating NativeCommandError, nog voor de exitcode-check.
# (a) Mechanisme-bewijs: het kale patroon breekt, het capture-patroon niet -- op een echt native
# commando (cmd.exe echoot naar stderr en geeft exit 0). NB: .ps1 is puur ASCII, dus geen trema's.
$naiveThrew = $false
try {
    $prevE = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
    & cmd /c 'echo remote: iets 1>&2 & exit 0' 2>&1 | Out-Null
    $ErrorActionPreference = $prevE
} catch { $naiveThrew = $true; $ErrorActionPreference = 'Stop' }
Assert-True $naiveThrew 'kaal patroon (native stderr onder EAP=Stop) is inderdaad terminating'

$fixThrew = $false; $fixCode = $null
try {
    $prevE = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
    $prevInner = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $out = & cmd /c 'echo remote: iets 1>&2 & exit 0' 2>&1
    $fixCode = $LASTEXITCODE
    $ErrorActionPreference = $prevInner
    $out | Out-Null
    $ErrorActionPreference = $prevE
} catch { $fixThrew = $true }
Assert-True (-not $fixThrew) 'capture-patroon (EAP=Continue rond de aanroep) is NIET terminating'
Assert-Equal 0 $fixCode 'capture-patroon leest de echte exitcode (0) van het commando'

# (b) Regressie-guard: de bron van open-pr.ps1 mag niet terugvallen op het kale 'git push' + directe
# exitcode-check onder EAP=Stop; hij hoort de push met EAP=Continue te draaien en de output te vangen.
# (De live push tegen een echte remote is hier bewust NIET testbaar -- eerlijke test-gap.)
$openPrSrc = ($pairs | Where-Object { $_.Name -eq 'open-pr' }).SourcePath
$openPrText = [System.IO.File]::ReadAllText($openPrSrc)
Assert-True ($openPrText -match "git push -u origin \`$branch 2>&1") 'open-pr vangt de push-output (2>&1)'
Assert-True ($openPrText -match "ErrorActionPreference = 'Continue'") 'open-pr draait de push onder EAP=Continue'
# open-pr's gh pr create moet ook onder de guard vallen (gh kan naar stderr schrijven).
Assert-True ($openPrText -match "gh pr create.*2>&1") 'open-pr vangt de gh-pr-create-output (2>&1)'

# Sweep-guard (na de v1.12.0-breuk): de andere release-scripts die native git/gh muteren mogen de
# #107-valkuil niet dragen -- de mutatie-/gh-aanroepen horen onder EAP=Continue te draaien.
$cutSrc = Join-Path $RepoRoot 'scripts\release\cut-release.ps1'
$cutText = [System.IO.File]::ReadAllText($cutSrc)
Assert-True ($cutText -match "ErrorActionPreference = 'Continue'") 'cut-release draait het git-mutatieblok onder EAP=Continue'
Assert-True ($cutText -match "(?s)ErrorActionPreference = 'Continue'.*git add -A") 'cut-release: EAP=Continue staat voor git add'

$foldSrc = ($pairs | Where-Object { $_.Name -eq 'fold-changelog-entry' }).SourcePath
$foldText = [System.IO.File]::ReadAllText($foldSrc)
Assert-True ($foldText -match "gh pr list.*2>\`$null") 'fold draait gh pr list met stderr-discard'
Assert-True ($foldText -match "gh pr view.*2>\`$null") 'fold draait gh pr view met stderr-discard'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAALT: $($script:fail) fout, $($script:pass) goed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: alle $($script:pass) asserts geslaagd." -ForegroundColor Green
exit 0
