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

# BOM-loze UTF8 -- Set-Content -Encoding UTF8 voegt in Windows PowerShell 5.1 altijd een BOM
# toe, en de rest van de repo (CHANGELOG.md etc.) heeft geen BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

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
    $prJson = gh pr list --head $branchForPr --state all --json number,url --limit 1 --repo DaveKJohn/davekjohns-workshop
    $prs = if ($LASTEXITCODE -eq 0 -and $prJson) { @($prJson | ConvertFrom-Json) } else { @() }
    if ($prs.Count -ge 1) {
        $num = $prs[0].number
        $entryContent = ([regex]'(?m)^### ').Replace($entryContent, "### #$num $midDot ", 1)

        # Geraakte plugins afleiden uit de PR-bestanden (automation-first): paden onder
        # claude-code-plugins/claude-specialists/<plugin>/ worden een 'Plugins:'-regel, waarmee
        # cut-release.ps1 later de per-plugin CHANGELOGs bijschrijft. De connectors-map is
        # werkplaats-administratie en telt niet mee.
        $filesJson = gh pr view $num --json files --repo DaveKJohn/davekjohns-workshop
        if ($LASTEXITCODE -eq 0 -and $filesJson) {
            $touched = @()
            foreach ($f in @(($filesJson | ConvertFrom-Json).files)) {
                if ($f.path -match '^claude-code-plugins/claude-specialists/([a-z0-9][a-z0-9-]*)/') {
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
