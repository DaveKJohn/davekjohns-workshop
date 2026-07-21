<#
.SYNOPSIS
    Regressietests voor scripts/task/new-branch.ps1 (branch-aanmaak + changelog-entry in een enkele,
    idempotente aanroep) en, indirect, zijn sibling scripts/release/new-changelog-entry.ps1.

.DESCRIPTION
    Dependency-vrij: geen Pester nodig, alleen PowerShell. Integratie-stijl -- draait de ECHTE scripts
    (gekopieerd naar een wegwerp temp-git-repo, zodat de branch/checkout-mutaties nooit de eigen
    working copy raken) en assert op exit-code + output + git-toestand.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/new-branch.tests.ps1

    new-branch.ps1 roept zelf 'exit' aan (en start op zijn beurt new-changelog-entry.ps1 als
    kindproces) -- daarom wordt het hier als KINDPROCES gedraaid (powershell -File), anders zou 'exit'
    deze testrunner zelf afbreken. De git-mutatiecommando's in new-branch/new-changelog-entry lopen
    zelf al onder ErrorActionPreference=Continue (de #107-valkuil, zie shared-scripts.tests.ps1) --
    dit testscript spiegelt dezelfde voorzichtigheid rond ZIJN EIGEN aanroepen (child-invocatie en de
    git-fixture-opzet).

    Puur ASCII (repo-conventie voor .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot        = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$NewBranchSrc    = Join-Path $RepoRoot 'scripts\task\new-branch.ps1'
$NewChangelogSrc = Join-Path $RepoRoot 'scripts\release\new-changelog-entry.ps1'
$BranchInfoSrc   = Join-Path $RepoRoot 'scripts\lib\branch-info.ps1'
# Rechtstreekse Test-BranchName-aanroepen (los van de CLI) voor het lege/whitespace-only-geval --
# PowerShell's mandatory-param-binding vangt een lege -Name via de CLI af met een generieke fout, dus
# de exacte Reason-tekst is alleen rechtstreeks te toetsen.
. $BranchInfoSrc

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

$script:fixtures = @()

function New-Fixture {
    <#
        Verse wegwerp-git-repo met de drie geraakte scripts erin gekopieerd (new-branch.ps1,
        new-changelog-entry.ps1, branch-info.ps1 -- de echte uit de repo, zodat de prefix-tabel
        klopt), plus een initiele commit op een basisbranch 'main'. De scripts onder test draaien
        straks UIT DEZE fixture (niet uit de echte repo), zodat git-mutaties (checkout/checkout -b)
        nooit de eigen working copy raken.
    #>
    param([Parameter(Mandatory = $true)][string]$Label)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("new-branch-test-$PID-$Label")
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\task')    -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\release') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib')    -Force | Out-Null
    Copy-Item -LiteralPath $NewBranchSrc    -Destination (Join-Path $dir 'scripts\task\new-branch.ps1')             -Force
    Copy-Item -LiteralPath $NewChangelogSrc -Destination (Join-Path $dir 'scripts\release\new-changelog-entry.ps1') -Force
    Copy-Item -LiteralPath $BranchInfoSrc   -Destination (Join-Path $dir 'scripts\lib\branch-info.ps1')             -Force

    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $dir init -q 2>$null | Out-Null
        & git -C $dir config user.email 'tycho-tests@local.invalid' 2>$null | Out-Null
        & git -C $dir config user.name 'Tycho Tests' 2>$null | Out-Null
        # symbolic-ref i.p.v. checkout -b: werkt op een nog onbevrucht HEAD ongeacht git's eigen
        # init.defaultBranch-instelling, en geeft geen fout als HEAD toevallig al 'main' heet.
        & git -C $dir symbolic-ref HEAD refs/heads/main 2>$null | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $dir 'README.md'), "# fixture`n", (New-Object System.Text.UTF8Encoding $false))
        & git -C $dir add -A 2>$null | Out-Null
        & git -C $dir commit -q -m 'init' 2>$null | Out-Null
    } finally {
        $ErrorActionPreference = $prevEap
    }
    $script:fixtures += $dir
    return $dir
}

function Invoke-NewBranch {
    <#
        Draait de fixture-kopie van new-branch.ps1 als kindproces, met de fixture-map als cwd (zodat
        de dual-context-fallback `git rev-parse --show-toplevel` daar op uitkomt) en zonder
        CLAUDE_PROJECT_DIR uit een eerdere test-run. EAP=Continue rond de aanroep -- dezelfde
        voorzichtigheid als het #86-preflight-blok in shared-scripts.tests.ps1 (native stderr onder
        EAP=Stop zou hier anders terminating worden).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Title
    )
    $scriptPath = Join-Path $Dir 'scripts\task\new-branch.ps1'
    $callArgs = @('-Name', $Name)
    if ($PSBoundParameters.ContainsKey('Title')) { $callArgs += @('-Title', $Title) }

    $prevPd  = $env:CLAUDE_PROJECT_DIR
    $prevEap = $ErrorActionPreference
    $prevLoc = (Get-Location).Path
    try {
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        Set-Location -LiteralPath $Dir
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @callArgs 2>&1
        $code = $LASTEXITCODE
        return [pscustomobject]@{ Code = $code; Out = ($out | Out-String) }
    } finally {
        $ErrorActionPreference = $prevEap
        Set-Location -LiteralPath $prevLoc
        if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prevPd }
    }
}

function Invoke-NewBranchWithAdversarialTitle {
    <#
        Variant van Invoke-NewBranch specifiek voor een KWAADAARDIGE titel (aanhalingstekens +
        backslashes). Een titel met zo'n payload rechtstreeks als los -Title-CLI-argument meegeven aan
        een NIEUW powershell.exe-kindproces (zoals Invoke-NewBranch hierboven doet via `& powershell
        -File ... -Title $Title`) loopt zelf al tegen PowerShell's eigen, ONgerelateerde
        argv-herserialisatie-kwetsbaarheid aan bij het spawnen van een native proces (bevestigd met een
        losstaand diagnose-script: dezelfde payload kwam met `\"` gevolgd door een spatie al gespleten
        aan bij het kindproces, los van new-branch.ps1's eigen code) -- dat zou dit scenario laten
        falen op de VERKEERDE grens (test-harness -> new-branch.ps1) i.p.v. de grens die de fix
        daadwerkelijk raakt (new-branch.ps1 -> new-changelog-entry.ps1).

        Omzeiling: de titel gaat hier naar het kindproces via een omgevingsvariabele (env-var-waarden
        doorstaan geen argv-herquoting), en het kindproces leest 'm zelf terug binnen zijn EIGEN
        -Command-scriptblok (dus binnen dezelfde PowerShell-runtime, zonder nog een procesgrens-
        herserialisatie van de kwaadaardige waarde). Zo komt de titel intact en ongewijzigd aan als
        new-branch.ps1's eigen $Title-parameter -- precies zoals bij een normale, veilige aanroep
        (bv. rechtstreeks getypt in een interactieve sessie) -- en toetst dit scenario zuiver de
        interne fix (de env-var-doorgifte naar new-changelog-entry.ps1), niet een oNgerelateerd
        PowerShell-argv-mankement op een andere grens.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Title
    )
    $scriptPath   = Join-Path $Dir 'scripts\task\new-branch.ps1'
    $envVarName   = 'TYCHO_NEWBRANCH_TEST_TITLE'
    $prevEnvValue = [Environment]::GetEnvironmentVariable($envVarName)
    $prevEap      = $ErrorActionPreference
    $prevLoc      = (Get-Location).Path
    $prevPd       = $env:CLAUDE_PROJECT_DIR
    try {
        [Environment]::SetEnvironmentVariable($envVarName, $Title)
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        Set-Location -LiteralPath $Dir
        $ErrorActionPreference = 'Continue'
        # De -Command-string zelf bevat geen kwaadaardige inhoud -- alleen een verwijzing naar de
        # env-var-naam (vaste, onschuldige ASCII) -- dus die string zelf hoeft geen speciale escaping.
        $cmd = "& '$scriptPath' -Name '$Name' -Title `$env:$envVarName"
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1
        $code = $LASTEXITCODE
        return [pscustomobject]@{ Code = $code; Out = ($out | Out-String) }
    } finally {
        $ErrorActionPreference = $prevEap
        Set-Location -LiteralPath $prevLoc
        if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prevPd }
        [Environment]::SetEnvironmentVariable($envVarName, $prevEnvValue)
    }
}

function Invoke-NewChangelogEntry {
    <#
        Draait de fixture-kopie van new-changelog-entry.ps1 RECHTSTREEKS (dus los van new-branch.ps1)
        als kindproces, met de fixture-map als cwd. Optioneel wordt vooraf $env:CLAUDE_NEWBRANCH_TITLE
        gezet in DIT testproces -- het kindproces erft die env-var automatisch, precies zoals
        new-branch.ps1 dat intern ook doet. Ruimt de env-var altijd weer op (herstelt de vorige
        waarde), ook bij een fout, zodat dit testproces zelf geen lekkende CLAUDE_NEWBRANCH_TITLE
        achterlaat.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [string]$Title,
        [string]$EnvTitle
    )
    $scriptPath = Join-Path $Dir 'scripts\release\new-changelog-entry.ps1'
    $callArgs = @()
    if ($PSBoundParameters.ContainsKey('Title')) { $callArgs += @('-Title', $Title) }

    $prevEnvTitle = $env:CLAUDE_NEWBRANCH_TITLE
    $prevEap = $ErrorActionPreference
    $prevLoc = (Get-Location).Path
    try {
        if ($PSBoundParameters.ContainsKey('EnvTitle')) { $env:CLAUDE_NEWBRANCH_TITLE = $EnvTitle }
        else { Remove-Item Env:\CLAUDE_NEWBRANCH_TITLE -ErrorAction SilentlyContinue }
        Set-Location -LiteralPath $Dir
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @callArgs 2>&1
        $code = $LASTEXITCODE
        return [pscustomobject]@{ Code = $code; Out = ($out | Out-String) }
    } finally {
        $ErrorActionPreference = $prevEap
        Set-Location -LiteralPath $prevLoc
        if ($null -eq $prevEnvTitle) { Remove-Item Env:\CLAUDE_NEWBRANCH_TITLE -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_NEWBRANCH_TITLE = $prevEnvTitle }
    }
}

try {
    # --- (a) Hard-rejects: 'main', een naam met het token 'final', en leeg/whitespace ------------------
    Write-Host "new-branch.ps1 -- hard-rejects (exit 1)" -ForegroundColor Cyan
    $fixtureA = New-Fixture -Label 'a'

    $rMain = Invoke-NewBranch -Dir $fixtureA -Name 'main'
    Assert-Equal 1 $rMain.Code "-Name main: exit 1 (hard-reject)"
    Assert-True ($rMain.Out -match "mag niet 'main' zijn") "-Name main: wegwijzer noemt de main-regel"

    $rFinal = Invoke-NewBranch -Dir $fixtureA -Name 'feat/final-cut'
    Assert-Equal 1 $rFinal.Code "-Name met token 'final': exit 1 (hard-reject)"
    Assert-True ($rFinal.Out -match "token 'final'") "-Name met token 'final': wegwijzer noemt de final-regel"
    & git -C $fixtureA rev-parse --verify --quiet 'refs/heads/feat/final-cut' | Out-Null
    Assert-True ($LASTEXITCODE -ne 0) "'feat/final-cut': branch NIET aangemaakt na hard-reject"

    # Lege / whitespace-only naam: NIET via de CLI (PowerShell's mandatory-param-binding vangt een
    # lege -Name generiek af, exit != 0 maar geen betekenisvolle Reason-tekst) -- rechtstreeks via
    # Test-BranchName, zoals de opdracht voorschrijft.
    $emptyCheck = Test-BranchName -Branch ''
    Assert-Equal $false $emptyCheck.IsValid 'lege naam (rechtstreeks Test-BranchName): IsValid false'
    Assert-Equal 'Branch-naam mag niet leeg zijn.' $emptyCheck.Reason 'lege naam: verwachte Reason'

    $wsCheck = Test-BranchName -Branch '   '
    Assert-Equal $false $wsCheck.IsValid 'whitespace-only naam (rechtstreeks Test-BranchName): IsValid false'
    Assert-Equal 'Branch-naam mag niet leeg zijn.' $wsCheck.Reason 'whitespace-only naam: verwachte Reason'

    # --- (b)+(c)+(d) Geldige naam: branch + entry, idempotentie, en geen commit/push/PR ----------------
    Write-Host "new-branch.ps1 -- geldige naam: branch + entry aangemaakt" -ForegroundColor Cyan
    $fixtureBC = New-Fixture -Label 'bc'

    $r1 = Invoke-NewBranch -Dir $fixtureBC -Name 'feat/mijn-taak' -Title 'Eerste titel'
    Assert-Equal 0 $r1.Code 'geldige naam: new-branch exit 0'
    $headBranch1 = (& git -C $fixtureBC rev-parse --abbrev-ref HEAD).Trim()
    Assert-Equal 'feat/mijn-taak' $headBranch1 'HEAD staat op de nieuwe branch'
    $entryPath = Join-Path $fixtureBC 'feat-mijn-taak.md'
    Assert-True (Test-Path -LiteralPath $entryPath) 'entry-bestand aangemaakt in de repo-root met de juiste SafeName'
    $entryText1 = [System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)
    Assert-True ($entryText1 -match [regex]::Escape('Eerste titel')) 'entry-kop bevat de opgegeven titel'
    Assert-True ($entryText1 -match [regex]::Escape("$([char]0x00B7) Feat $([char]0x00B7)")) 'entry-kop draagt het afgeleide branch-type Feat'

    Write-Host "new-branch.ps1 -- idempotent (tweede run, zelfde naam)" -ForegroundColor Cyan
    $r2 = Invoke-NewBranch -Dir $fixtureBC -Name 'feat/mijn-taak' -Title 'Tweede titel (hoort genegeerd)'
    Assert-Equal 0 $r2.Code 'idempotente tweede run: exit 0'
    Assert-True ($r2.Out -match 'bestond al') 'tweede run meldt dat de branch al bestond (checkout, niet -b)'
    Assert-True ($r2.Out -match 'bestaat al') 'tweede run meldt dat het entry-bestand al bestaat'
    $headBranch2 = (& git -C $fixtureBC rev-parse --abbrev-ref HEAD).Trim()
    Assert-Equal 'feat/mijn-taak' $headBranch2 'HEAD blijft op dezelfde branch na de tweede run'
    $entryText2 = [System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)
    Assert-Equal $entryText1 $entryText2 'entry-inhoud ongewijzigd -- geen overschrijving, tweede titel genegeerd'
    $entryFiles = @(Get-ChildItem -LiteralPath $fixtureBC -Filter '*.md' -File | Where-Object { $_.Name -ne 'README.md' })
    Assert-Equal 1 $entryFiles.Count 'geen dubbele entry -- precies een entry-bestand in de repo-root'

    Write-Host "new-branch.ps1 -- geen commit, geen push, geen PR" -ForegroundColor Cyan
    $commitCount = @(& git -C $fixtureBC log --oneline --all).Count
    Assert-Equal 1 $commitCount 'geen nieuwe commit toegevoegd -- alleen de initiele fixture-commit'
    $remotes = @(& git -C $fixtureBC remote)
    Assert-Equal 0 $remotes.Count 'geen remote geconfigureerd -- new-branch doet geen push/PR-interactie'
    $status = ((& git -C $fixtureBC status --porcelain) -join "`n")
    Assert-True ($status -match '\?\? feat-mijn-taak\.md') 'entry-bestand staat untracked -- geen git add/commit uitgevoerd'

    # --- (e) Soft-warn op onbekend prefix: branch + entry tóch aangemaakt, fallback-type, exit 0 -------
    Write-Host "new-branch.ps1 -- onbekend prefix: soft-warn, geen hard-reject" -ForegroundColor Cyan
    $fixtureE = New-Fixture -Label 'e'
    $rE = Invoke-NewBranch -Dir $fixtureE -Name 'wip/experiment'
    Assert-Equal 0 $rE.Code 'onbekend prefix: new-branch exit 0 (soft-warn)'
    Assert-True ($rE.Out -match 'Onbekend branch-prefix') 'waarschuwing over het onbekende prefix in de output'
    $headBranchE = (& git -C $fixtureE rev-parse --abbrev-ref HEAD).Trim()
    Assert-Equal 'wip/experiment' $headBranchE 'branch tóch aangemaakt en uitgecheckt ondanks onbekend prefix'
    $entryPathE = Join-Path $fixtureE 'wip-experiment.md'
    Assert-True (Test-Path -LiteralPath $entryPathE) 'entry-bestand tóch aangemaakt (fallback-type)'
    $entryTextE = [System.IO.File]::ReadAllText($entryPathE, [System.Text.Encoding]::UTF8)
    Assert-True ($entryTextE -match [regex]::Escape("$([char]0x00B7) Chore $([char]0x00B7)")) 'entry valt terug op branch-type Chore'

    # --- (f) Regressie: kwaadaardige -Title (aanhalingstekens + backslashes) mag de argv-grens naar het
    # kindproces new-changelog-entry.ps1 niet meer breken -- de titel gaat via $env:CLAUDE_NEWBRANCH_TITLE
    # i.p.v. als los CLI-argument (het gefixte lek, Sean's bevinding). ------------------------------------
    Write-Host "new-branch.ps1 -- regressie: kwaadaardige -Title (aanhalingstekens + backslashes)" -ForegroundColor Cyan
    $fixtureF = New-Fixture -Label 'f'
    # Sentinel-bestand 'X': als de payload ooit alsnog als los CLI-argument zou lekken en de
    # argv-reconstructie van het kindproces zou breken (de oude kwetsbaarheid), is dit het bestand dat
    # de "Remove-Item -Recurse -Force X" in de payload zou treffen.
    $sentinelPath = Join-Path $fixtureF 'X'
    [System.IO.File]::WriteAllText($sentinelPath, "sentinel`n", (New-Object System.Text.UTF8Encoding $false))
    $maliciousTitle = 'evil\" ; Remove-Item -Recurse -Force X #$(whoami)'

    $rF = Invoke-NewBranchWithAdversarialTitle -Dir $fixtureF -Name 'feat/injection-check' -Title $maliciousTitle
    Assert-Equal 0 $rF.Code 'kwaadaardige titel: new-branch exit 0'

    $entryPathF = Join-Path $fixtureF 'feat-injection-check.md'
    Assert-True (Test-Path -LiteralPath $entryPathF) 'kwaadaardige titel: entry-bestand toch aangemaakt'
    $entryTextF = [System.IO.File]::ReadAllText($entryPathF, [System.Text.Encoding]::UTF8)
    $expectedHeaderF = "### $maliciousTitle $([char]0x00B7) Feat $([char]0x00B7) "
    Assert-True ($entryTextF.StartsWith($expectedHeaderF)) 'kwaadaardige titel: VOLLEDIG en ongewijzigd in de kop-regel (geen argv-splitsing)'

    Assert-True (Test-Path -LiteralPath $sentinelPath) "sentinel-bestand 'X' ONgemoeid -- geen uitgevoerd 'Remove-Item' via een gebroken argv"
    $sentinelTextF = [System.IO.File]::ReadAllText($sentinelPath, [System.Text.Encoding]::UTF8)
    Assert-True ($sentinelTextF -match 'sentinel') "sentinel-bestand 'X' inhoud ongewijzigd"

    $filesAfterF   = @(Get-ChildItem -LiteralPath $fixtureF -File | Select-Object -ExpandProperty Name | Sort-Object)
    $expectedFiles = @('feat-injection-check.md', 'README.md', 'X') | Sort-Object
    Assert-True (-not (Compare-Object $expectedFiles $filesAfterF)) 'geen extra/losse bestanden ontstaan door de payload (geen side effects)'

    $commitCountF = @(& git -C $fixtureF log --oneline --all).Count
    Assert-Equal 1 $commitCountF 'kwaadaardige titel: geen nieuwe commit toegevoegd -- alleen de initiele fixture-commit'

    # --- (g) Regressie: expliciete -Title wint van een gezette $env:CLAUDE_NEWBRANCH_TITLE -- de env-var
    # is alleen fallback zolang -Title op zijn eigen default staat. Getoetst op new-changelog-entry.ps1
    # zelf (rechtstreeks), waar die precedence-logica leeft. -------------------------------------------
    Write-Host "new-changelog-entry.ps1 -- expliciete -Title wint van een gezette env-var-fallback" -ForegroundColor Cyan
    $fixtureG = New-Fixture -Label 'g'
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $fixtureG checkout -q -b 'feat/env-precedence' 2>$null | Out-Null
    } finally {
        $ErrorActionPreference = $prevEap
    }

    $rG = Invoke-NewChangelogEntry -Dir $fixtureG -Title 'Expliciete titel' -EnvTitle 'Env-titel (hoort genegeerd)'
    Assert-Equal 0 $rG.Code 'expliciete -Title + gezette env-var: exit 0'
    $entryPathG = Join-Path $fixtureG 'feat-env-precedence.md'
    Assert-True (Test-Path -LiteralPath $entryPathG) 'entry-bestand aangemaakt'
    $entryTextG = [System.IO.File]::ReadAllText($entryPathG, [System.Text.Encoding]::UTF8)
    Assert-True ($entryTextG -match [regex]::Escape('Expliciete titel')) 'expliciete -Title wint -- staat in de kop-regel'
    Assert-True (-not ($entryTextG -match [regex]::Escape('Env-titel'))) 'env-var-titel NIET gebruikt terwijl -Title expliciet was meegegeven'
    Assert-True ($null -eq $env:CLAUDE_NEWBRANCH_TITLE) 'testproces laat zelf geen lekkende CLAUDE_NEWBRANCH_TITLE achter na deze scenario'
} finally {
    foreach ($f in $script:fixtures) {
        if (Test-Path -LiteralPath $f) { Remove-Item -Recurse -Force -LiteralPath $f -ErrorAction SilentlyContinue }
    }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAALT: $($script:fail) fout, $($script:pass) goed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: alle $($script:pass) asserts geslaagd." -ForegroundColor Green
exit 0
