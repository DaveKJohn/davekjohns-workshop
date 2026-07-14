<#
.SYNOPSIS
    Snijdt een repo-brede release rechtstreeks op master: bumpt alle plugin-versies in lockstep,
    verplaatst de gevouwen Pull-Requests-entries naar de ## Releases-sectie van CHANGELOG.md, commit
    dat op master, en zet + pusht de git-tag vX.Y.Z.

.DESCRIPTION
    Een release is hier een *vastgelegd moment*: alle drie de plugins krijgen hetzelfde versienummer
    (lockstep, repo-breed) en de staat wordt getagd als vX.Y.Z. Er wordt niets naar GitHub Releases
    gepubliceerd -- alleen een git-tag + een versieblok in CHANGELOG.md.

    Een release loopt bewust NIET via een branch + PR. Net als de fold-commit is de release-commit een
    toegestane directe-op-master-actie (de tweede uitzondering op "alles via branch + PR" -- zie de
    safety rules). Het script draait daarom op master zelf en wordt ALLEEN op Dave's expliciete verzoek
    gestart (een versie-bump is expliciet-verzoek-werk).

    Stappen (alles op master):
      1. Vangrails: moet op een schone master staan, geen ongevouwen entry-bestanden in de root, en
         de lint-poort (check-plugin-integrity.ps1) moet groen zijn.
      2. Leest de huidige lockstep-versie uit elke <plugin>/.claude-plugin/plugin.json (moeten gelijk
         zijn) en bepaalt de nieuwe versie (-Version expliciet, of -Bump major|minor|patch).
      3. Bumpt alle plugin.json-versies, verplaatst de Pull-Requests-entries naar een nieuw blok
         ### vX.Y.Z onder ## Releases (en leegt de Pull-Requests-sectie tot zijn intro).
      4. Commit dat rechtstreeks op master (release: vX.Y.Z) en zet een annotated tag vX.Y.Z.
      5. Pusht master + de tag (tenzij -NoPush).

.PARAMETER Version
    Expliciete nieuwe versie in de vorm X.Y.Z (bv. "1.0.0"). Gebruik dit OF -Bump.

.PARAMETER Bump
    Verhoog de huidige versie automatisch: major | minor | patch. Gebruik dit OF -Version.

.PARAMETER NoPush
    Doe alles lokaal (commit + tag) maar push master/tag niet -- voor inspectie vooraf. Push daarna
    zelf: git push origin master && git push origin vX.Y.Z.

.PARAMETER SkipLint
    Sla de lint-poort bewust over (noodklep).

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Version 1.0.0

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Bump minor -NoPush
#>
[CmdletBinding()]
param(
    [string]$Version,
    [ValidateSet('major', 'minor', 'patch')][string]$Bump,
    [switch]$NoPush,
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

# --- Vangrails: op master, schoon, geen ongevouwen entries ---------------------------------------
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne 'master') { Write-Error "Een release wordt rechtstreeks op master gesneden; je staat op '$branch'."; exit 1 }
if ((git status --porcelain)) { Write-Error "Working tree niet schoon -- commit/stash eerst."; exit 1 }

$strayEntries = Get-ChildItem -Path $repoRoot -Filter '*.md' -File |
    Where-Object { $reservedRootMd -notcontains $_.Name } |
    Select-Object -ExpandProperty Name
if ($strayEntries.Count -gt 0) {
    Write-Error "Er staan nog ongevouwen changelog entry-bestanden in de root: $($strayEntries -join ', '). Fold die eerst (fold-changelog-entry.ps1)."
    exit 1
}

# --- Versie bepalen ------------------------------------------------------------------------------
$manifests = @(Get-PluginManifests)
if ($manifests.Count -eq 0) { Write-Error "Geen plugin-manifesten gevonden."; exit 1 }
$manifestContents = @{}
foreach ($m in $manifests) { $manifestContents[$m] = (Get-Content -Path $m -Raw -Encoding UTF8) }
$current = Get-LockstepVersion -ManifestContents $manifestContents

if ($Version) {
    if ($Version -notmatch '^\d+\.\d+\.\d+$') { Write-Error "-Version moet de vorm X.Y.Z hebben (bv. 1.0.0)."; exit 1 }
    $new = $Version
} elseif ($Bump) {
    $new = Get-NextVersion -Current $current -BumpKind $Bump
} else {
    Write-Error "Geef -Version <X.Y.Z> of -Bump <major|minor|patch>. Huidige versie: $current."
    exit 1
}
if ($new -eq $current) { Write-Error "Nieuwe versie ($new) is gelijk aan de huidige -- niets te bumpen."; exit 1 }

$tagName = "v$new"
if ((git tag --list $tagName)) { Write-Error "Tag $tagName bestaat al."; exit 1 }

# --- Lint-poort ----------------------------------------------------------------------------------
if (-not $SkipLint) {
    $lintPath = Join-Path $PSScriptRoot '..\lint\check-plugin-integrity.ps1'
    if (Test-Path $lintPath) {
        Write-Host "check-plugin-integrity: integriteitscheck voor de release..." -ForegroundColor Cyan
        & powershell -NoProfile -ExecutionPolicy Bypass -File $lintPath
        if ($LASTEXITCODE -ne 0) { Write-Error "check-plugin-integrity vond fouten -- release afgebroken. Fix ze, of draai met -SkipLint."; exit 1 }
    } else {
        Write-Warning "check-plugin-integrity.ps1 niet gevonden -- lint-poort overgeslagen."
    }
}

# --- CHANGELOG transformeren (voor de schrijf-acties, zodat een parse-fout niets achterlaat) ------
$changelogPath = Join-Path $repoRoot 'CHANGELOG.md'
$today = (Get-Date -Format 'yyyy-MM-dd')
$changelogNew = Convert-ChangelogForRelease -Content (Get-Content -Path $changelogPath -Raw -Encoding UTF8) -Version $new -Date $today

# --- Plugin-versies bumpen (regex op de version-regel -- behoudt de JSON-opmaak) -----------------
foreach ($m in $manifests) {
    $raw = Get-Content -Path $m -Raw -Encoding UTF8
    $bumped = [regex]::Replace($raw, '("version"\s*:\s*")\d+\.\d+\.\d+(")', "`${1}$new`$2", 1)
    Write-Utf8NoBom -Path $m -Content $bumped
    # Plugin-naam = de map twee niveaus boven plugin.json (<plugin>/.claude-plugin/plugin.json).
    $pluginName = Split-Path (Split-Path (Split-Path $m -Parent) -Parent) -Leaf
    Write-Host "  gebumpt: $pluginName/.claude-plugin/plugin.json -> $new" -ForegroundColor DarkGray
}

Write-Utf8NoBom -Path $changelogPath -Content $changelogNew

# --- Commit + tag rechtstreeks op master ---------------------------------------------------------
git add -A
git commit -m "release: v$new"
if ($LASTEXITCODE -ne 0) { Write-Error "git commit mislukte."; exit 1 }

git tag -a $tagName -m "Release $tagName"
if ($LASTEXITCODE -ne 0) { Write-Error "git tag mislukte."; exit 1 }

if ($NoPush) {
    Write-Host ""
    Write-Host "Release v$new lokaal vastgelegd op master (commit + tag $tagName), niet gepusht." -ForegroundColor Green
    Write-Host "Push zelf wanneer je klaar bent:" -ForegroundColor Cyan
    Write-Host "  git push origin master; git push origin $tagName"
    exit 0
}

git push origin master
if ($LASTEXITCODE -ne 0) { Write-Error "git push van master mislukte."; exit 1 }
git push origin $tagName
if ($LASTEXITCODE -ne 0) { Write-Error "git push van de tag mislukte."; exit 1 }

Write-Host ""
Write-Host "En... actie: v$new is gesneden ($current -> $new), gecommit op master en getagd als $tagName. Vastgelegd." -ForegroundColor Green
