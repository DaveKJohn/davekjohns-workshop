<#
.SYNOPSIS
    Snijdt een repo-brede release rechtstreeks op main: bumpt alle plugin-versies in lockstep,
    genereert release-notes in releases/development/, zet in CHANGELOG.md een verwijzing onder
    ## Releases, werkt de overzichtstabel in releases/README.md bij, commit dat op main, en zet +
    pusht de git-tag vX.Y.Z.

.DESCRIPTION
    Een release is hier een *vastgelegd moment*: alle drie de plugins krijgen hetzelfde versienummer
    (lockstep, repo-breed) en de staat wordt getagd als vX.Y.Z. Er wordt niets naar GitHub Releases
    gepubliceerd -- alleen een git-tag, release-notes in releases/, en een verwijzing in CHANGELOG.md.

    Een release loopt bewust NIET via een branch + PR. Net als de fold-commit is de release-commit een
    toegestane directe-op-main-actie (de tweede uitzondering op "alles via branch + PR" -- zie de
    safety rules). Het script draait daarom op main zelf en wordt ALLEEN op Dave's expliciete verzoek
    gestart.

    Stappen (alles op main):
      1. Vangrails: schone main, geen ongevouwen entry-bestanden in de root, lint-poort groen.
      2. Leest de huidige lockstep-versie uit elke <plugin>/.claude-plugin/plugin.json; bepaalt de
         nieuwe versie (-Version of -Bump) en het bump-type.
      3. Genereert releases/development/<X.Y>/<X.Y.Z>.md uit de ## Pull Requests-entries (per
         branch-type gegroepeerd), voegt een rij toe aan releases/README.md, zet in CHANGELOG.md een
         verwijzing onder ## Releases en leegt de Pull-Requests-sectie, en bumpt alle plugin.json's.
      4. Commit dat rechtstreeks op main (release: vX.Y.Z) en zet een annotated tag vX.Y.Z.
      5. Pusht main + de tag (tenzij -NoPush).

.PARAMETER Version
    Expliciete nieuwe versie X.Y.Z (bv. "1.1.0"). Gebruik dit OF -Bump.

.PARAMETER Bump
    Verhoog de huidige versie automatisch: major | minor | patch. Gebruik dit OF -Version.

.PARAMETER Title
    Korte omschrijving van de release als geheel (1 zin, optioneel) -- komt in de notes + de tabelrij.

.PARAMETER NoPush
    Alles lokaal (commit + tag) maar main/tag niet pushen -- voor inspectie vooraf.

.PARAMETER SkipLint
    Sla de lint-poort bewust over (noodklep).

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Version 1.0.0 -Title "Eerste officiele release"

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Bump minor -NoPush
#>
[CmdletBinding()]
param(
    [string]$Version,
    [ValidateSet('major', 'minor', 'patch')][string]$Bump,
    [string]$Title = '',
    [switch]$NoPush,
    [switch]$SkipLint
)
$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

. (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')

# BOM-loze UTF8 -- de rest van de repo heeft geen BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

$reservedRootMd = @('CHANGELOG.md', 'CLAUDE.md', 'README.md', 'LICENSE.md')

function Get-PluginManifests {
    # De marketplace-definitie is de bron van waarheid over wat een plugin is: de manifesten worden
    # afgeleid uit plugins[].source in marketplace.json in plaats van een repo-brede scan, zodat een
    # toevallige geneste .claude-plugin/plugin.json (bv. toekomstig test- of voorbeeldmateriaal)
    # nooit stilzwijgend meegebumpt wordt. Dezelfde controle als de marketplace-check in de lint-poort.
    $marketplacePath = Join-Path $repoRoot '.claude-plugin\marketplace.json'
    if (-not (Test-Path -LiteralPath $marketplacePath)) {
        Write-Error ".claude-plugin/marketplace.json ontbreekt."; exit 1
    }
    $marketplace = Get-Content -Path $marketplacePath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($p in $marketplace.plugins) {
        $manifest = [System.IO.Path]::GetFullPath(
            (Join-Path $repoRoot (Join-Path $p.source '.claude-plugin\plugin.json')))
        # Containment-check (advies Sean): een absoluut of ..-pad in source mag de bump nooit
        # buiten de repo laten schrijven.
        $rootPrefix = [System.IO.Path]::GetFullPath($repoRoot).TrimEnd('\') + '\'
        if (-not $manifest.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Error "Plugin '$($p.name)': source '$($p.source)' wijst buiten de repo ($manifest)."; exit 1
        }
        if (-not (Test-Path -LiteralPath $manifest)) {
            Write-Error "Plugin '$($p.name)' staat in marketplace.json maar mist zijn manifest ($manifest)."; exit 1
        }
        $manifest
    }
}

# --- Vangrails: op main, schoon, geen ongevouwen entries ---------------------------------------
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne 'main') { Write-Error "Een release wordt rechtstreeks op main gesneden; je staat op '$branch'."; exit 1 }
if ((git status --porcelain)) { Write-Error "Working tree niet schoon -- commit/stash eerst."; exit 1 }

$strayEntries = Get-ChildItem -Path $repoRoot -Filter '*.md' -File |
    Where-Object { $reservedRootMd -notcontains $_.Name } |
    Select-Object -ExpandProperty Name
if ($strayEntries.Count -gt 0) {
    Write-Error "Er staan nog ongevouwen changelog entry-bestanden in de root: $($strayEntries -join ', '). Fold die eerst (fold-changelog-entry.ps1)."
    exit 1
}

# --- Versie + bump-type bepalen ------------------------------------------------------------------
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

$bumpType = Get-BumpType -From $current -To $new
$typeLabel = @{ major = 'Major'; minor = 'Minor'; patch = 'Patch' }[$bumpType]
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

# --- Inhoud opbouwen (voor de schrijf-acties, zodat een parse-fout niets achterlaat) --------------
$minorDir = ($new -split '\.')[0..1] -join '.'
$notesRelPath = "releases/development/$minorDir/$new.md"
$today = (Get-Date -Format 'yyyy-MM-dd')

$changelogPath = Join-Path $repoRoot 'CHANGELOG.md'
$changelogRaw = Get-Content -Path $changelogPath -Raw -Encoding UTF8
$entries = @(Get-PullRequestEntries -Content $changelogRaw)
$notesContent = Build-ReleaseNotes -Entries $entries -Version $new -Date $today -Type $typeLabel -Title $Title
$changelogNew = Convert-ChangelogForRelease -Content $changelogRaw -Version $new -Date $today -Type $typeLabel -NotesRelPath $notesRelPath

# --- Release-notes-bestand schrijven -------------------------------------------------------------
$notesDir = Join-Path $repoRoot ("releases\development\$minorDir")
New-Item -ItemType Directory -Force -Path $notesDir | Out-Null
$notesAbs = Join-Path $repoRoot ($notesRelPath -replace '/', '\')
if (Test-Path $notesAbs) { Write-Error "$notesRelPath bestaat al."; exit 1 }
Write-Utf8NoBom -Path $notesAbs -Content $notesContent
Write-Host "  aangemaakt: $notesRelPath ($($entries.Count) entries)" -ForegroundColor DarkGray

# --- releases/README.md overzichtstabel bijwerken ------------------------------------------------
$relReadme = Join-Path $repoRoot 'releases\README.md'
$shortTitle = if ($Title) { $Title } else { "$typeLabel release" }
$newRow = "| [$new](development/$minorDir/$new.md) | $today | $typeLabel | $shortTitle |"
if (Test-Path $relReadme) {
    $rm = Get-Content -Path $relReadme -Raw -Encoding UTF8
    $rmNl = if ($rm.Contains("`r`n")) { "`r`n" } else { "`n" }
    $headerRe = [regex]"(?m)^\| Versie \| Datum \| Type \| Titel \|\r?\n\|[-| ]+\|\r?\n"
    $hm = $headerRe.Match($rm)
    if ($hm.Success) {
        $at = $hm.Index + $hm.Length
        $rm = $rm.Substring(0, $at) + $newRow + $rmNl + $rm.Substring($at)
        Write-Utf8NoBom -Path $relReadme -Content $rm
        Write-Host "  bijgewerkt: releases/README.md" -ForegroundColor DarkGray
    } else {
        Write-Warning "Overzichtstabel niet gevonden in releases/README.md -- voeg de rij handmatig toe: $newRow"
    }
} else {
    Write-Warning "releases/README.md ontbreekt -- rij niet toegevoegd: $newRow"
}

Write-Utf8NoBom -Path $changelogPath -Content $changelogNew

# --- Plugin-versies bumpen (regex op de version-regel -- behoudt de JSON-opmaak) -----------------
foreach ($m in $manifests) {
    $raw = Get-Content -Path $m -Raw -Encoding UTF8
    $bumped = [regex]::Replace($raw, '("version"\s*:\s*")\d+\.\d+\.\d+(")', "`${1}$new`$2", 1)
    Write-Utf8NoBom -Path $m -Content $bumped
    $pluginName = Split-Path (Split-Path (Split-Path $m -Parent) -Parent) -Leaf
    Write-Host "  gebumpt: $pluginName/.claude-plugin/plugin.json -> $new" -ForegroundColor DarkGray
}

# --- Commit + tag rechtstreeks op main ---------------------------------------------------------
git add -A
git commit -m "release: v$new"
if ($LASTEXITCODE -ne 0) { Write-Error "git commit mislukte."; exit 1 }

git tag -a $tagName -m "Release $tagName"
if ($LASTEXITCODE -ne 0) { Write-Error "git tag mislukte."; exit 1 }

if ($NoPush) {
    Write-Host ""
    Write-Host "Release v$new lokaal vastgelegd op main (commit + tag $tagName), niet gepusht." -ForegroundColor Green
    Write-Host "Push zelf wanneer je klaar bent:" -ForegroundColor Cyan
    Write-Host "  git push origin main; git push origin $tagName"
    exit 0
}

git push origin main
if ($LASTEXITCODE -ne 0) { Write-Error "git push van main mislukte."; exit 1 }
git push origin $tagName
if ($LASTEXITCODE -ne 0) { Write-Error "git push van de tag mislukte."; exit 1 }

Write-Host ""
Write-Host "En... actie: v$new is gesneden ($current -> $new, $typeLabel), gecommit op main en getagd als $tagName. Vastgelegd." -ForegroundColor Green
