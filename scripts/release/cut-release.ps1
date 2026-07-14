<#
.SYNOPSIS
    Snijdt een repo-brede release: bumpt alle plugin-versies in lockstep, verplaatst de gevouwen
    Pull-Requests-entries naar de ## Releases-sectie van CHANGELOG.md, en (in -Tag-modus) zet de
    git-tag vX.Y.Z.

.DESCRIPTION
    Een release is hier een *vastgelegd moment*: alle drie de plugins krijgen hetzelfde versienummer
    (lockstep, repo-breed) en de staat wordt getagd als vX.Y.Z. Er wordt niets naar GitHub Releases
    gepubliceerd -- alleen een git-tag + een versieblok in CHANGELOG.md.

    De cut verloopt in twee fasen, gescheiden door de PR (net als de rest van de workflow):

      FASE 1 -- PREPARE (standaard, draait op master):
        1. Vangrails: moet op een schone master staan, geen ongevouwen entry-bestanden in de root,
           en de lint-poort (check-plugin-integrity.ps1) moet groen zijn.
        2. Leest de huidige lockstep-versie uit elke <plugin>/.claude-plugin/plugin.json (moeten
           gelijk zijn) en bepaalt de nieuwe versie (-Version expliciet, of -Bump major|minor|patch).
        3. Maakt branch release/vX.Y.Z, bumpt alle plugin.json-versies, verplaatst de
           Pull-Requests-entries naar een nieuw blok ### vX.Y.Z onder ## Releases (en leegt de
           Pull-Requests-sectie tot zijn intro), en commit dat op de branch.
        4. Pusht NIET en opent GEEN PR -- dat doet Dave's woord via open-pr.ps1.

      FASE 2 -- TAG (-Tag, draait op master NA het mergen van de release-PR):
        Verifieert dat master schoon is en de plugin.json-versies op X.Y.Z staan (release gemerged),
        zet dan een annotated git-tag vX.Y.Z en pusht die.

.PARAMETER Version
    Expliciete nieuwe versie in de vorm X.Y.Z (bv. "0.2.0"). Gebruik dit OF -Bump.

.PARAMETER Bump
    Verhoog de huidige versie automatisch: major | minor | patch. Gebruik dit OF -Version.

.PARAMETER Tag
    Fase 2: zet en push de git-tag vX.Y.Z op master (na de merge). Vereist -Version of -Bump zodat
    het versienummer eenduidig is.

.PARAMETER SkipLint
    Sla de lint-poort in fase 1 bewust over (noodklep).

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Bump minor
    # Fase 1: bereidt release/v0.2.0 voor op een branch.

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Version 0.2.0 -Tag
    # Fase 2: tagt master als v0.2.0 na de merge.
#>
[CmdletBinding()]
param(
    [string]$Version,
    [ValidateSet('major', 'minor', 'patch')][string]$Bump,
    [switch]$Tag,
    [switch]$SkipLint
)
$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

. (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')

# BOM-loze UTF8 -- de rest van de repo (CHANGELOG.md, plugin.json) heeft geen BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

$reservedRootMd = @('CHANGELOG.md', 'CLAUDE.md', 'README.md', 'LICENSE.md')

function Get-PluginManifests {
    # Alle plugin-manifesten in de marketplace: <plugin>/.claude-plugin/plugin.json
    Get-ChildItem -Path $repoRoot -Directory |
        ForEach-Object { Join-Path $_.FullName '.claude-plugin\plugin.json' } |
        Where-Object { Test-Path $_ }
}

# --- Uitvoering ----------------------------------------------------------------------------------

# Versie bepalen (vereist bij zowel prepare als tag).
$manifests = @(Get-PluginManifests)
if ($manifests.Count -eq 0) { Write-Error "Geen plugin-manifesten gevonden."; exit 1 }
$manifestContents = @{}
foreach ($m in $manifests) { $manifestContents[$m] = (Get-Content -Path $m -Raw -Encoding UTF8) }
$current = Get-LockstepVersion -ManifestContents $manifestContents

if ($Version) {
    if ($Version -notmatch '^\d+\.\d+\.\d+$') { Write-Error "-Version moet de vorm X.Y.Z hebben (bv. 0.2.0)."; exit 1 }
    $new = $Version
} elseif ($Bump) {
    $new = Get-NextVersion -Current $current -BumpKind $Bump
} else {
    Write-Error "Geef -Version <X.Y.Z> of -Bump <major|minor|patch>. Huidige versie: $current."
    exit 1
}

$branch = (git rev-parse --abbrev-ref HEAD).Trim()

if ($Tag) {
    # -------- FASE 2: TAG --------
    if ($branch -ne 'master') { Write-Error "De tag-stap draait op master (na de merge); je staat op '$branch'."; exit 1 }
    if ((git status --porcelain)) { Write-Error "Working tree niet schoon -- commit/stash eerst."; exit 1 }
    if ($current -ne $new) {
        Write-Error "master staat op versie $current, niet op $new -- is de release-PR al gemerged? (Verwacht dat plugin.json op $new staat.)"
        exit 1
    }
    $tagName = "v$new"
    $existing = (git tag --list $tagName)
    if ($existing) { Write-Error "Tag $tagName bestaat al."; exit 1 }
    git tag -a $tagName -m "Release $tagName"
    if ($LASTEXITCODE -ne 0) { Write-Error "git tag mislukte."; exit 1 }
    git push origin $tagName
    if ($LASTEXITCODE -ne 0) { Write-Error "git push van de tag mislukte."; exit 1 }
    Write-Host "En... vastgelegd: $tagName staat op master en is gepusht." -ForegroundColor Green
    exit 0
}

# -------- FASE 1: PREPARE --------
if ($branch -ne 'master') { Write-Error "Bereid een release voor vanaf een schone master; je staat op '$branch'."; exit 1 }
if ((git status --porcelain)) { Write-Error "Working tree niet schoon -- commit/stash eerst."; exit 1 }

# Geen ongevouwen entry-bestanden in de root (die horen eerst gevouwen te zijn -- anders raken ze
# de release niet in en blijven ze rondslingeren).
$strayEntries = Get-ChildItem -Path $repoRoot -Filter '*.md' -File |
    Where-Object { $reservedRootMd -notcontains $_.Name } |
    Select-Object -ExpandProperty Name
if ($strayEntries.Count -gt 0) {
    Write-Error "Er staan nog ongevouwen changelog entry-bestanden in de root: $($strayEntries -join ', '). Fold die eerst (fold-changelog-entry.ps1)."
    exit 1
}

if ($new -eq $current) { Write-Error "Nieuwe versie ($new) is gelijk aan de huidige -- niets te bumpen."; exit 1 }

# Lint-poort.
if (-not $SkipLint) {
    $lintPath = Join-Path $PSScriptRoot '..\lint\check-plugin-integrity.ps1'
    if (Test-Path $lintPath) {
        Write-Host "check-plugin-integrity: integriteitscheck voor de release..." -ForegroundColor Cyan
        & powershell -NoProfile -ExecutionPolicy Bypass -File $lintPath
        if ($LASTEXITCODE -ne 0) { Write-Error "check-plugin-integrity vond fouten -- release niet voorbereid. Fix ze, of draai met -SkipLint."; exit 1 }
    } else {
        Write-Warning "check-plugin-integrity.ps1 niet gevonden -- lint-poort overgeslagen."
    }
}

# CHANGELOG transformeren (voor de git-branch, zodat een parse-fout niets achterlaat).
$changelogPath = Join-Path $repoRoot 'CHANGELOG.md'
$today = (Get-Date -Format 'yyyy-MM-dd')
$changelogNew = Convert-ChangelogForRelease -Content (Get-Content -Path $changelogPath -Raw -Encoding UTF8) -Version $new -Date $today

# Release-branch aanmaken.
$relBranch = "release/v$new"
git checkout -b $relBranch
if ($LASTEXITCODE -ne 0) { Write-Error "Kon branch '$relBranch' niet aanmaken (bestaat hij al?)."; exit 1 }

# Plugin-versies bumpen (regex op de version-regel -- behoudt de JSON-opmaak).
foreach ($m in $manifests) {
    $raw = Get-Content -Path $m -Raw -Encoding UTF8
    $bumped = [regex]::Replace($raw, '("version"\s*:\s*")\d+\.\d+\.\d+(")', "`${1}$new`$2", 1)
    Write-Utf8NoBom -Path $m -Content $bumped
    # Plugin-naam = de map twee niveaus boven plugin.json (<plugin>/.claude-plugin/plugin.json).
    $pluginName = Split-Path (Split-Path (Split-Path $m -Parent) -Parent) -Leaf
    Write-Host "  gebumpt: $pluginName/.claude-plugin/plugin.json -> $new" -ForegroundColor DarkGray
}

Write-Utf8NoBom -Path $changelogPath -Content $changelogNew

git add -A
git commit -m "release: cut v$new"
if ($LASTEXITCODE -ne 0) { Write-Error "git commit mislukte."; exit 1 }

Write-Host ""
Write-Host "Release v$new voorbereid op branch '$relBranch' (versies $current -> $new, CHANGELOG bijgewerkt)." -ForegroundColor Green
Write-Host "Volgende stappen:" -ForegroundColor Cyan
Write-Host "  1. Bekijk de diff."
Write-Host "  2. Op Dave's woord: ./scripts/release/open-pr.ps1 -Title `"release: v$new`" -> mergen."
Write-Host "  3. Daarna op master: ./scripts/release/cut-release.ps1 -Version $new -Tag"
