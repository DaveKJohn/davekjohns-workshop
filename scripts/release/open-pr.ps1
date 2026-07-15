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
    [switch]$SkipLint
)
$ErrorActionPreference = 'Stop'

$repo = 'DaveKJohn/davekjohns-workshop'

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq 'main') { Write-Error "Je staat op main; een PR maak je vanaf een branch."; exit 1 }

# Lint-poort: vang ongeldige manifesten/frontmatter/dode links voor ze via een PR op main belanden.
# Fouten blokkeren (exit-code 1); -SkipLint slaat de poort bewust over.
if (-not $SkipLint) {
    $lintPath = Join-Path $PSScriptRoot '..\lint\check-plugin-integrity.ps1'
    if (Test-Path $lintPath) {
        Write-Host "check-plugin-integrity: integriteitscheck voor de PR..." -ForegroundColor Cyan
        & powershell -NoProfile -ExecutionPolicy Bypass -File $lintPath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "check-plugin-integrity vond fouten - branch niet gepusht, geen PR geopend. Fix de fouten, of draai met -SkipLint om de poort over te slaan."
            exit 1
        }
    } else {
        Write-Warning "check-plugin-integrity.ps1 niet gevonden op '$lintPath' - lint-poort overgeslagen."
    }
}

git push -u origin $branch
if ($LASTEXITCODE -ne 0) { Write-Error "git push mislukte."; exit 1 }

. (Join-Path $PSScriptRoot '..\lib\branch-info.ps1')

$info = Get-BranchInfo -Branch $branch
if ($info.IsKnown) {
    $label = $info.Label
} else {
    $label = 'question'
    Write-Warning "Onbekend branch-prefix '$($info.Prefix)' - label 'question' gezet; classificeer de PR handmatig."
}

if (-not $Body) {
    $repoRoot = (git rev-parse --show-toplevel).Trim()
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

        # Kruis aan / vul in wat het script deterministisch weet:
        #   - het "Type wijziging"-vakje waarvan de regel `<prefix>/` bevat;
        #   - de placeholder onder "Wat doet deze wijziging?" -> de beschrijving;
        #   - "Changelog entry-bestand aangemaakt": waar zodra <SafeName>.md bestaat (net uitgelezen);
        #   - "Aangevraagd door Dave": altijd waar -- dit script draait alleen op Dave's verzoek.
        # De overige checklist-items blijven bewust leeg: menselijke oordeel-checks.
        $prefixPattern = '^- \[ \] `' + [regex]::Escape($info.Prefix) + '/`'
        $entryExists = Test-Path $entryPath
        $filled = foreach ($line in $templateLines) {
            if ($line -match $prefixPattern) {
                $line -replace '^- \[ \]', '- [x]'
            } elseif ($desc -and $line -eq '<!-- Korte beschrijving van wat er verandert en waarom. -->') {
                $desc
            } elseif ($entryExists -and $line -match '^- \[ \] Changelog entry-bestand aangemaakt') {
                $line -replace '^- \[ \]', '- [x]'
            } elseif ($line -match '^- \[ \] Aangevraagd door Dave') {
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
try {
    gh pr create --base main --head $branch --title $Title --body-file $bodyFile --label $label --repo $repo
    if ($LASTEXITCODE -ne 0) { Write-Error "PR aanmaken mislukte (is gh ingelogd?)."; exit 1 }
} finally {
    Remove-Item -Path $bodyFile -Force -ErrorAction SilentlyContinue
}
Write-Host "PR aangemaakt voor '$branch'." -ForegroundColor Green
