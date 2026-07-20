<#
Vouwt een of meer changelog entry-bestanden (<branch-naam>.md in de repo-root) in de
## Pull Requests-sectie van CHANGELOG.md, en verwijdert de entry-bestanden daarna.

Het entry-bestand is al compact (kop `### titel - type - datum` met middot-scheiding, daaronder de
beschrijving) -- gelijk aan het CHANGELOG-format. Fold voegt bij het invouwen alleen '#NN - ' vooraan
in de titel toe en als laatste regel de link `[PR #NN](url)`. Het PR-nummer + url worden opgehaald via
`gh pr list` (op -Branch, of in fold-all-modus afgeleid uit de bestandsnaam) -- dat kan pas na het
openen van de PR. Wordt er geen PR gevonden (bv. een handmatige merge zonder PR), dan komt er geen
nummer/url in en blijft de kop zonder #NN.

Gebruik:
  .\scripts\release\fold-changelog-entry.ps1 -Branch feat/nieuwe-plugin
  .\scripts\release\fold-changelog-entry.ps1              # vouwt alle aanwezige entry-bestanden

Draai dit op main, direct na het mergen van een branch (nadat Dave de merge heeft goedgekeurd).
Commit het resultaat (CHANGELOG.md + verwijderde entry-bestanden) daarna rechtstreeks op main.
#>

param(
    [string]$Branch
)

$ErrorActionPreference = "Stop"

# Repo-root -- dual-context: draait een consument de gedeelde plugin-spiegel, dan levert
# CLAUDE_PROJECT_DIR diens repo-root; in de workshop-root (of buiten een sessie) valt het terug op de
# git-root. Zo werkt DEZELFDE file in beide locaties, en blijven de root-kopie en de plugin-spiegel
# byte-identiek (bewaakt door de shared-scripts-drift-lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }
Set-Location $repoRoot

# Pre-flight (#86): fold leunt op scripts\repo-config.ps1 in de repo-root van de consument. Ontbreekt
# die -- typisch op een schone consument -- stop met een duidelijke wegwijzer i.p.v. een rauwe
# dot-source-fout op de . (dot-source)-regel hieronder.
$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Error "fold-changelog kan niet draaien -- ontbrekend repo-eigen bestand: $configPath (Get-RepoName / Get-RepoBlobUrl / Get-LintScript). Dit bestand is repo-specifiek en hoort in de repo-root van de consument. Maak het aan (de specialists-init-bootstrap zet een VUL-IN-scaffold neer, of neem een bestaande consument / de werkplaats-repo als model) en draai daarna opnieuw."
    exit 1
}

# Repo-naam uit de lokale repo-config van de repo-root (enige bron), niet langer hardcoded. Bewust
# vanuit $repoRoot en niet $PSScriptRoot: vanuit de plugin-spiegel wijst $PSScriptRoot naar de
# plugin-cache, terwijl repo-config altijd in de repo-root van de consument woont.
. (Join-Path $repoRoot 'scripts\repo-config.ps1')
$repo = Get-RepoName

# Pre-flight (#86): een niet-ingevulde scaffold (repo-config nog op VUL-IN) faalt anders pas verderop
# met een onduidelijke gh-fout. Stop hier met een duidelijke wegwijzer.
if ($repo -match 'VUL-IN') {
    Write-Error "fold-changelog kan niet draaien -- scripts\repo-config.ps1 bevat nog VUL-IN-placeholders. Vul Get-RepoName in met de waarde van deze repo en draai opnieuw."
    exit 1
}

# BOM-loze UTF8 -- Set-Content -Encoding UTF8 voegt in Windows PowerShell 5.1 altijd een BOM
# toe, en de rest van de repo (CHANGELOG.md etc.) heeft geen BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

if ($Branch) {
    $entryFiles = @(($Branch -replace '/', '-') + ".md")
}
else {
    $reserved = @("CHANGELOG.md", "CLAUDE.md", "README.md")
    $entryFiles = Get-ChildItem -Path $repoRoot -Filter "*.md" -File |
        Where-Object { $reserved -notcontains $_.Name } |
        Select-Object -ExpandProperty Name
}

if ($entryFiles.Count -eq 0) {
    Write-Host "Geen entry-bestanden gevonden om te vouwen." -ForegroundColor Yellow
    exit 0
}

$changelogPath = Join-Path $repoRoot "CHANGELOG.md"
$headingPattern = '(?m)^## Pull Requests\s*?$'

foreach ($file in $entryFiles) {
    $filePath = Join-Path $repoRoot $file
    if (-not (Test-Path $filePath)) {
        Write-Host "Entry-bestand '$file' niet gevonden - overgeslagen." -ForegroundColor Yellow
        continue
    }

    $entryContent = (Get-Content -Path $filePath -Raw -Encoding UTF8).TrimEnd()
    $changelogContent = Get-Content -Path $changelogPath -Raw -Encoding UTF8

    $usesCRLF = $changelogContent.Contains("`r`n")
    $nl = if ($usesCRLF) { "`r`n" } else { "`n" }
    $entryContent = ($entryContent -replace "`r`n", "`n") -replace "`n", $nl

    # Het entry-bestand is al compact ("### <titel> <midDot> <type> <midDot> <datum>" + beschrijving),
    # gelijk aan het CHANGELOG-format. Fold voegt alleen '#NN <midDot> ' vooraan in de titel toe en de
    # PR-link onderaan. Het PR-nummer bestaat pas na de merge; we halen het op via de branch -- uit
    # -Branch, of in fold-all-modus afgeleid uit de bestandsnaam (<prefix>-<rest>.md -> <prefix>/<rest>).
    $midDot = [char]0x00B7
    $branchForPr = $Branch
    if (-not $branchForPr) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $branchForPr = $base -replace '^([^-]+)-', '$1/'
    }
    # gh kan meldingen naar stderr schrijven; onder ErrorActionPreference=Stop zou PS 5.1 dat tot een
    # terminating error promoveren nog voor de graceful $LASTEXITCODE-afhandeling hieronder (de #107-
    # valkuil). Draai onder Continue en gooi stderr weg (2>$null), zodat het ook de gevangen JSON niet
    # kan vervuilen.
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $prJson = gh pr list --head $branchForPr --state all --json number,url --limit 1 --repo $repo 2>$null
    $ghCode = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ($ghCode -ne 0) { Write-Host "  (gh pr list gaf exitcode $ghCode -- PR-nummer-verrijking overgeslagen; draai gh handmatig voor de reden.)" -ForegroundColor DarkYellow }
    $prs = if ($ghCode -eq 0 -and $prJson) { @($prJson | ConvertFrom-Json) } else { @() }
    if ($prs.Count -ge 1) {
        $num = $prs[0].number
        $entryContent = ([regex]'(?m)^### ').Replace($entryContent, "### #$num $midDot ", 1)

        # Geraakte plugins afleiden uit de PR-bestanden (automation-first): paden onder
        # claude-code-plugins/claude-specialists/<plugin>/ worden een 'Plugins:'-regel, waarmee
        # cut-release.ps1 later de per-plugin CHANGELOGs bijschrijft. De connectors-map is
        # werkplaats-administratie en telt niet mee.
        $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        $filesJson = gh pr view $num --json files --repo $repo 2>$null
        $ghViewCode = $LASTEXITCODE
        $ErrorActionPreference = $prevEap
        if ($ghViewCode -ne 0) { Write-Host "  (gh pr view gaf exitcode $ghViewCode -- Plugins:-regel overgeslagen; draai gh handmatig voor de reden.)" -ForegroundColor DarkYellow }
        if ($ghViewCode -eq 0 -and $filesJson) {
            $touched = @()
            foreach ($f in @(($filesJson | ConvertFrom-Json).files)) {
                # -cmatch (advies Sean): -match is case-insensitief en zou de kleine-letters-
                # tekenklasse stilzwijgend oprekken; plugin-mapnamen zijn altijd lowercase slugs.
                if ($f.path -cmatch '^claude-code-plugins/claude-specialists/([a-z0-9][a-z0-9-]*)/') {
                    if ($Matches[1] -ne 'connectors' -and $touched -notcontains $Matches[1]) { $touched += $Matches[1] }
                }
            }
            if ($touched.Count -gt 0) {
                $entryContent = $entryContent.TrimEnd() + "$nl$nl" + ('Plugins: ' + ((@($touched) | Sort-Object) -join ', '))
            }
        } else {
            Write-Host "  Kon de PR-bestanden niet ophalen - entry zonder Plugins-regel." -ForegroundColor Yellow
        }

        $entryContent = $entryContent.TrimEnd() + "$nl$nl[PR #$num]($($prs[0].url))"
    }
    else {
        Write-Host "  Geen PR gevonden voor '$branchForPr' - entry zonder PR-nummer/url." -ForegroundColor Yellow
    }

    $headingMatch = [regex]::Match($changelogContent, $headingPattern)
    if (-not $headingMatch.Success) {
        Write-Host "Kon de '## Pull Requests' heading niet vinden in CHANGELOG.md - stoppen." -ForegroundColor Red
        exit 1
    }
    $afterHeader = $headingMatch.Index + $headingMatch.Length

    # Invoegen na een eventuele intro-alinea: voor de eerste ###-entry in de Pull Requests-sectie,
    # of - als de sectie nog leeg is - voor het ## Releases-kopje. Zo blijft de intro-regel bovenaan.
    $relMatch = [regex]::Match($changelogContent, '(?m)^## Releases\s*?$')
    $relPos = if ($relMatch.Success) { $relMatch.Index } else { $changelogContent.Length }
    $firstEntry = ([regex]'(?m)^### ').Match($changelogContent, $afterHeader)
    $insertPos = if ($firstEntry.Success -and $firstEntry.Index -lt $relPos) { $firstEntry.Index } else { $relPos }

    $entryBlock = "$entryContent$nl$nl---$nl$nl"
    $changelogContent = $changelogContent.Substring(0, $insertPos) + $entryBlock + $changelogContent.Substring($insertPos)

    Write-Utf8NoBom -Path $changelogPath -Content $changelogContent
    Remove-Item -Path $filePath -Force
    Write-Host "Gevouwen en verwijderd: $file" -ForegroundColor Green
}

Write-Host "CHANGELOG.md bijgewerkt." -ForegroundColor Green
