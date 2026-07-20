<#
.SYNOPSIS
    Push de huidige branch en open een Pull Request naar main.

.DESCRIPTION
    Pusht de huidige branch naar origin en maakt een PR naar main via de GitHub CLI. Vangrail:
    weigert als je op main staat. Gebruikt .github/pull_request_template.md als startpunt voor
    de PR-body tenzij je zelf -Body meegeeft (LET OP: gh pr create --fill vult de body met de
    volledige commit-geschiedenis sinds main, niet met de template -- gebruik dat dus niet als
    je de checklist-template wil).

    Auto-invullen (als je -Body NIET meegeeft): het script vult de template zelf zoveel mogelijk in,
    zodat de PR nooit als een leeg formulier op github.com belandt:
      1. Het juiste "Type wijziging"-vakje wordt aangekruist op basis van het branch-prefix
         (dezelfde bron als het label -- de `<prefix>/`-regel in de template).
      2. "Wat doet deze wijziging?" wordt gevuld met de beschrijving uit het changelog entry-bestand
         (<SafeName>.md in de repo-root), dat op de branch altijd bestaat. Zo hoef je niets dubbel te
         typen.
      3. De twee checklist-items die op dat moment altijd waar zijn worden aangevinkt: "Changelog
         entry-bestand aangemaakt" (bestaat, want net uitgelezen) en "Aangevraagd door Dave" (het
         script draait alleen op Dave's verzoek). De overige checklist-items blijven leeg -- dat zijn
         menselijke oordeel-checks die het script niet eerlijk kan verifieren.
      Geef je wel -Body mee, dan wordt die letterlijk gebruikt (override).

    Zet ALTIJD een GitHub-label op basis van het branch-prefix (elke PR heeft een label). De
    prefix-naar-label-tabel staat in scripts/lib/branch-info.ps1 (gedeeld met de andere scripts) en
    volgt de hoofdcategorieen van de PR-template. Onbekend prefix -> label 'question' + waarschuwing
    (= nader te classificeren).

    Lint-poort (vangrail voor main): voor de push draait scripts/lint/check-plugin-integrity.ps1.
    Vindt die fouten (ongeldige marketplace/plugin-manifesten, ontbrekende agent-def-frontmatter,
    dode links), dan wordt de branch NIET gepusht en GEEN PR geopend. Gebruik -SkipLint om de poort
    bewust over te slaan (noodklep).

    Test-poort (les van PR #54, waar een rode suite pas op CI opviel): na de lint draaien ALLE
    testsuites (scripts/tests/*.tests.ps1), exact zoals CI dat doet. Een falende suite blokkeert
    de push en de PR. Gebruik -SkipTests om deze poort bewust over te slaan (noodklep).

.PARAMETER Title
    PR-titel, bv. "feat: nieuwe domein-plugin" of "fix: kapotte agent-def-frontmatter".

.PARAMETER Body
    (Optioneel) PR-omschrijving. Standaard: de ingevulde .github/pull_request_template.md.

.EXAMPLE
    ./scripts/release/open-pr.ps1 -Title "feat: nieuwe domein-plugin"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Title,
    [string]$Body = '',
    [switch]$SkipLint,
    [switch]$SkipTests
)
$ErrorActionPreference = 'Stop'

# Repo-root -- dual-context: draait een consument de gedeelde plugin-spiegel, dan levert
# CLAUDE_PROJECT_DIR diens repo-root; in de workshop-root (of buiten een sessie) valt het terug op de
# git-root. Zo werkt DEZELFDE file in beide locaties, en blijven de root-kopie en de plugin-spiegel
# byte-identiek (bewaakt door de shared-scripts-drift-lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# Pre-flight (#86): de gedeelde scripts leunen op twee repo-eigen bestanden in de repo-root van de
# consument. Ontbreken ze -- typisch op een schone consument waar ze nog niet zijn aangemaakt -- stop
# dan met een duidelijke wegwijzer i.p.v. een rauwe dot-source-fout (het pad-niet-gevonden dat je
# anders op de . (dot-source)-regels hieronder zou krijgen).
$needed = @('scripts\repo-config.ps1', 'scripts\lib\branch-info.ps1')
$absent = @($needed | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_)) })
if ($absent.Count -gt 0) {
    Write-Error ("open-pr kan niet draaien -- ontbrekende repo-eigen configuratie in de repo-root ($repoRoot):`n  " + ($absent -join "`n  ") + "`n`nDeze bestanden zijn repo-specifiek en horen in de repo-root van de consument:`n  scripts\repo-config.ps1      -- Get-RepoName / Get-RepoBlobUrl / Get-LintScript`n  scripts\lib\branch-info.ps1  -- de repo-eigen branch-prefix-tabel`n`nMaak ze aan (de specialists-init-bootstrap zet een VUL-IN-scaffold neer, of neem een bestaande consument / de werkplaats-repo als model) en draai daarna opnieuw.")
    exit 1
}

# Repo-eigen config + gedeelde branch-lib uit de repo-root (enige bron). Bewust vanuit $repoRoot en
# niet $PSScriptRoot: vanuit de plugin-spiegel wijst $PSScriptRoot naar de plugin-cache, terwijl
# repo-config/branch-info altijd in de repo-root van de consument wonen.
. (Join-Path $repoRoot 'scripts\repo-config.ps1')
. (Join-Path $repoRoot 'scripts\lib\branch-info.ps1')
$repo = Get-RepoName

# Pre-flight (#86): een niet-ingevulde scaffold (repo-config nog op VUL-IN) faalt anders pas verderop
# met een onduidelijke gh-fout. Stop hier met een duidelijke wegwijzer.
if ($repo -match 'VUL-IN' -or (Get-LintScript) -match 'VUL-IN') {
    Write-Error "open-pr kan niet draaien -- scripts\repo-config.ps1 bevat nog VUL-IN-placeholders. Vul Get-RepoName en Get-LintScript in met de waarden van deze repo en draai opnieuw."
    exit 1
}

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq 'main') { Write-Error "Je staat op main; een PR maak je vanaf een branch."; exit 1 }

# Lint-poort: vang ongeldige manifesten/frontmatter/dode links voor ze via een PR op main belanden.
# Het lint-script is repo-specifiek (via repo-config); fouten blokkeren (exit-code 1). -SkipLint
# slaat de poort bewust over.
if (-not $SkipLint) {
    $lintPath = Join-Path $repoRoot (Get-LintScript)
    if (Test-Path $lintPath) {
        Write-Host "lint-poort: integriteitscheck voor de PR..." -ForegroundColor Cyan
        & powershell -NoProfile -ExecutionPolicy Bypass -File $lintPath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "lint-poort vond fouten - branch niet gepusht, geen PR geopend. Fix de fouten, of draai met -SkipLint om de poort over te slaan."
            exit 1
        }
    } else {
        Write-Warning "lint-script niet gevonden op '$lintPath' - lint-poort overgeslagen."
    }
}

# Test-poort: alle suites, exact zoals CI -- een rode suite hoort hier al te blokkeren, niet pas
# op de PR (les van PR #54). -SkipTests is de bewuste noodklep.
if (-not $SkipTests) {
    $testsDir = Join-Path $repoRoot 'scripts\tests'
    if (Test-Path $testsDir) {
        Write-Host "test-poort: alle testsuites draaien voor de PR..." -ForegroundColor Cyan
        $testFailed = $false
        $suites = @(Get-ChildItem -Path $testsDir -Filter '*.tests.ps1' -File)
        if ($suites.Count -eq 0) {
            Write-Warning "geen *.tests.ps1-suites gevonden in scripts/tests - test-poort had niets te draaien."
        }
        $suites | ForEach-Object {
            Write-Host "== $($_.Name) ==" -ForegroundColor Cyan
            & powershell -NoProfile -ExecutionPolicy Bypass -File $_.FullName
            if ($LASTEXITCODE -ne 0) { $testFailed = $true }
        }
        if ($testFailed) {
            Write-Error "test-poort vond falende suites - branch niet gepusht, geen PR geopend. Fix de tests, of draai met -SkipTests om de poort over te slaan."
            exit 1
        }
    } else {
        Write-Warning "scripts/tests niet gevonden - test-poort overgeslagen."
    }
}

# git push schrijft zijn 'remote:'-voortgang naar stderr. Onder ErrorActionPreference=Stop
# promoveert PowerShell 5.1 die stderr-regels tot een TERMINATING NativeCommandError -- het script
# sterft dan op de push voordat de exitcode-check hieronder draait, terwijl git zelf exit 0 gaf
# (dezelfde klasse valkuil als #96/#97: nooit op stderr-als-fout leunen, altijd op $LASTEXITCODE).
# Daarom de push met EAP=Continue draaien, de volledige output vangen, meteen de exitcode
# vastleggen en pas daarna oordelen.
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $pushOutput = & git push -u origin $branch 2>&1
    $pushCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prevEap
}
$pushOutput | ForEach-Object { Write-Host $_ }
if ($pushCode -ne 0) { Write-Error "git push mislukte."; exit 1 }

$info = Get-BranchInfo -Branch $branch
if ($info.IsKnown) {
    $label = $info.Label
} else {
    $label = 'question'
    Write-Warning "Onbekend branch-prefix '$($info.Prefix)' - label 'question' gezet; classificeer de PR handmatig."
}

if (-not $Body) {
    $templatePath = Join-Path $repoRoot ".github\pull_request_template.md"
    if (Test-Path $templatePath) {
        $templateLines = Get-Content -Path $templatePath -Encoding UTF8

        # Beschrijving uit het changelog entry-bestand <SafeName>.md: alles na de compacte ###-kopregel
        # ("### titel - type - datum"). Op de branch bestaat dit bestand altijd.
        $desc = ''
        $entryPath = Join-Path $repoRoot ($info.SafeName + '.md')
        if (Test-Path $entryPath) {
            $entryLines = Get-Content -Path $entryPath -Encoding UTF8
            $h3Idx = -1
            for ($i = 0; $i -lt $entryLines.Count; $i++) {
                if ($entryLines[$i] -match '^###\s') { $h3Idx = $i; break }
            }
            if ($h3Idx -ge 0 -and ($h3Idx + 1) -lt $entryLines.Count) {
                $desc = (($entryLines[($h3Idx + 1)..($entryLines.Count - 1)]) -join "`n").Trim()
            }
        }

        # Tick / fill in what the script deterministically knows:
        #   - the "Type of change" box whose line contains `<prefix>/`;
        #   - the placeholder under "What does this change do?" -> the description;
        #   - "Changelog entry file created": true as soon as <SafeName>.md exists (just read);
        #   - "Requested by Dave": always true -- this script only runs at Dave's request.
        # The remaining checklist items stay empty on purpose: human judgement checks.
        # Each of the three string matches is BILINGUAL: it accepts both the legacy Dutch template
        # strings AND the new English ones, so a consumer whose PR template is still Dutch keeps working.
        $prefixPattern = '^- \[ \] `' + [regex]::Escape($info.Prefix) + '/`'
        $entryExists = Test-Path $entryPath
        $descPlaceholders = @(
            '<!-- Korte beschrijving van wat er verandert en waarom. -->',
            '<!-- Short description of what changes and why. -->'
        )
        $filled = foreach ($line in $templateLines) {
            if ($line -match $prefixPattern) {
                $line -replace '^- \[ \]', '- [x]'
            } elseif ($desc -and ($descPlaceholders -contains $line)) {
                $desc
            } elseif ($entryExists -and $line -match '^- \[ \] Changelog entry(-bestand aangemaakt| file created)') {
                $line -replace '^- \[ \]', '- [x]'
            } elseif ($line -match '^- \[ \] (Aangevraagd door Dave|Requested by Dave)') {
                $line -replace '^- \[ \]', '- [x]'
            } else {
                $line
            }
        }
        $Body = ($filled -join "`n")
    }
}

# Body via een tijdelijk bestand: --body $Body laat PowerShell 5.1 ingesloten aanhalingstekens
# verhaspelen bij native commando's, waardoor gh de body als losse argumenten leest.
$bodyFile = Join-Path ([System.IO.Path]::GetTempPath()) "open-pr-body-$PID.md"
[System.IO.File]::WriteAllText($bodyFile, $Body, (New-Object System.Text.UTF8Encoding $false))
$prevEap = $ErrorActionPreference
try {
    # gh schrijft zijn voortgang/URL deels naar stderr; onder EAP=Stop zou PS 5.1 dat tot een
    # terminating error promoveren nog voor de $LASTEXITCODE-check (dezelfde valkuil als de push
    # hierboven, #107). Draai onder Continue, vang de output, en oordeel dan op de exitcode.
    $ErrorActionPreference = 'Continue'
    $createOut = & gh pr create --base main --head $branch --title $Title --body-file $bodyFile --label $label --repo $repo 2>&1
    $createCode = $LASTEXITCODE
    $createOut | ForEach-Object { Write-Host $_ }
    if ($createCode -ne 0) { Write-Error "PR aanmaken mislukte (is gh ingelogd?)."; exit 1 }
} finally {
    $ErrorActionPreference = $prevEap
    Remove-Item -Path $bodyFile -Force -ErrorAction SilentlyContinue
}
Write-Host "PR aangemaakt voor '$branch'." -ForegroundColor Green
