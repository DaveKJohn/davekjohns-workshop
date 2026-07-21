<#
.SYNOPSIS
    Maakt (of hergebruikt idempotent) een branch en maakt meteen z'n changelog entry-bestand aan.

.DESCRIPTION
    Kern-verbetering: branch-aanmaak en changelog-entry-aanmaak waren twee losse handmatige stappen
    (new-branch dan new-changelog-entry.ps1) -- dit script voegt ze samen tot een enkele, idempotente
    aanroep. Alleen git (checkout/checkout -b) + het aanmaken van de entry; geen push, geen PR, niets
    repo-specifieks.

    Validatie loopt via de gedeelde SSOT-helper Test-BranchName (scripts/lib/branch-info.ps1):
      - Hard-reject (exit 1): lege naam, naam 'main', of een naam die de substring 'final' bevat.
      - Soft-warn (ga door): onbekend branch-prefix -- valt verderop terug op 'Chore' (new-changelog-
        entry) resp. 'question' (open-pr), consistent met die scripts. Validatie is bewust gedelegeerd
        aan de tabel van de consument, zodat uitgebreide prefixes (bv. Shopify's style/, liquid/, ...)
        gewoon kloppen zonder dat dit script ze hoeft te kennen.

.PARAMETER Name
    De branch-naam, vorm <prefix>/<korte-naam> (bv. feat/nieuwe-plugin).

.PARAMETER Title
    (Optioneel) titel voor het changelog entry-bestand, doorgegeven aan new-changelog-entry.ps1.
    Standaard gelijk aan new-changelog-entry's eigen default ("TODO: titel").

.EXAMPLE
    ./scripts/task/new-branch.ps1 -Name feat/nieuwe-plugin -Title "Nieuwe domein-plugin"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$Title = "TODO: titel"
)

$ErrorActionPreference = 'Stop'

# Repo-root -- dual-context: draait een consument de gedeelde plugin-spiegel, dan levert
# CLAUDE_PROJECT_DIR diens repo-root; in de workshop-root (of buiten een sessie) valt het terug op de
# git-root. Zo werkt DEZELFDE file in beide locaties, en blijven de root-kopie en de plugin-spiegel
# byte-identiek (bewaakt door de shared-scripts-drift-lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# Pre-flight (#86): dit script leunt ALLEEN op scripts\lib\branch-info.ps1 in de repo-root van de
# consument (geen repo-config, geen gh). Ontbreekt dat -- typisch op een schone consument -- stop
# met een duidelijke wegwijzer i.p.v. een rauwe dot-source-fout hieronder.
$branchInfoPath = Join-Path $repoRoot 'scripts\lib\branch-info.ps1'
if (-not (Test-Path -LiteralPath $branchInfoPath)) {
    Write-Error "new-branch kan niet draaien -- ontbrekend repo-eigen bestand: $branchInfoPath (Get-BranchInfo / Test-BranchName / de branch-prefix-tabel). Dit bestand is repo-specifiek en hoort in de repo-root van de consument. Maak het aan (de specialists-init-bootstrap zet een VUL-IN-scaffold neer, of neem een bestaande consument / de werkplaats-repo als model) en draai daarna opnieuw."
    exit 1
}
. $branchInfoPath

# Validatie via de gedeelde SSOT-helper -- geen inline-herhaling van de hard-reject-regels.
$check = Test-BranchName -Branch $Name
if (-not $check.IsValid) {
    Write-Error "new-branch kan niet draaien -- ongeldige branch-naam '$Name': $($check.Reason)"
    exit 1
}
if (-not $check.IsKnown) {
    Write-Warning "Onbekend branch-prefix in '$Name' -- new-changelog-entry valt terug op 'Chore', open-pr straks op label 'question'. Classificeer handmatig indien nodig."
}

# Let op: Test-BranchName hierboven vangt alleen de expliciet genoemde hard-rejects (leeg/'main'/
# 'final'). De bescherming tegen bv. backslashes, '..', of een leidend streepje in $Name leunt NIET
# op eigen code hier, maar impliciet op git's eigen `check-ref-format`-validatie, die `git checkout
# -b` hieronder zelf afdwingt (met exit 128 bij een ongeldige ref-naam). Wijzig je ooit het
# checkout-mechanisme (bv. naar `git branch` + los `checkout`, of naar libgit2), controleer dan of
# die impliciete poort niet stilzwijgend verdwijnt.
#
# Idempotent: bestaat de branch al lokaal, dan gewoon checkout; anders aanmaken. Bewust `git -C
# $repoRoot` i.p.v. Set-Location -- dit script blijft composable en muteert de aanroeper-cwd niet.
# git schrijft voortgang/fouten soms naar stderr; onder ErrorActionPreference=Stop zou PS 5.1 dat tot
# een terminating error promoveren nog voor de graceful $LASTEXITCODE-afhandeling (de #107-valkuil,
# zie ook open-pr.ps1) -- daarom onder Continue draaien, output vangen, en pas dan oordelen.
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $null = & git -C $repoRoot rev-parse --verify --quiet "refs/heads/$Name" 2>&1
    $existsCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prevEap
}
$branchExists = ($existsCode -eq 0)

$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    if ($branchExists) {
        $checkoutOutput = & git -C $repoRoot checkout $Name 2>&1
    } else {
        $checkoutOutput = & git -C $repoRoot checkout -b $Name 2>&1
    }
    $checkoutCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prevEap
}
$checkoutOutput | ForEach-Object { Write-Host $_ }
if ($checkoutCode -ne 0) {
    Write-Error "git checkout van '$Name' mislukte."
    exit 1
}
if ($branchExists) {
    Write-Host "Branch '$Name' bestond al -- uitgecheckt." -ForegroundColor Yellow
} else {
    Write-Host "Branch '$Name' aangemaakt en uitgecheckt." -ForegroundColor Green
}

# Entry-aanmaak als CHILD-proces: new-changelog-entry.ps1 kan intern `exit 0` (entry bestaat al) of
# `exit 1` (op main) doen -- als kindproces sloopt die exit niet dit script, alleen het kind. Sibling
# gedeeld script relatief aan $PSScriptRoot (beide scripts reizen samen als mirror-paar, zie
# scripts/lib/shared-scripts-lib.ps1). `checkout`/`checkout -b` hierboven heeft HEAD al omgezet, dus
# new-changelog-entry leidt de juiste branch zelf af uit HEAD.
#
# $Title als los CLI-argument over deze native procesgrens is een injectie-primitief: vrije tekst
# (bv. plausibel gekopieerd uit een externe issue/PR-titel) met `"`/backslashes kan de argv-
# reconstructie van het kindproces breken. Daarom hier NIET als `-Title $Title` doorgeven, maar via
# een omgevingsvariabele -- env-var-waarden gaan niet door argv-requoting, dus de injectie
# verdwijnt. `finally` ruimt de var ook bij een fout op, zodat er niets lekt naar een volgend proces
# in dezelfde sessie.
try {
    $env:CLAUDE_NEWBRANCH_TITLE = $Title
    $entryScript = Join-Path $PSScriptRoot '..\release\new-changelog-entry.ps1'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $entryScript
    $entryCode = $LASTEXITCODE
} finally {
    Remove-Item Env:CLAUDE_NEWBRANCH_TITLE -ErrorAction SilentlyContinue
}

exit $entryCode
