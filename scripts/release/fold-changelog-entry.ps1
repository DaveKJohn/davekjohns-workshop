<#
Folds one or more changelog entry files (<branch-name>.md in the repo root) into the
## Pull Requests section of CHANGELOG.md, and then removes the entry files.

The entry file is already compact (heading `### title - type - date` with middot separation,
followed by the description) -- matching the CHANGELOG format. When folding, fold only adds
'#NN - ' at the front of the title and, as the last line, the link `[PR #NN](url)`. The PR number +
url are fetched via `gh pr list` (on -Branch, or in fold-all mode derived from the file name) --
that can only happen after opening the PR. If no PR is found (e.g. a manual merge without a PR),
no number/url is added and the heading stays without #NN.

Usage:
  .\scripts\release\fold-changelog-entry.ps1 -Branch feat/new-plugin
  .\scripts\release\fold-changelog-entry.ps1              # folds all present entry files

Run this on main, right after merging a branch (after Dave has approved the merge).
Commit the result (CHANGELOG.md + removed entry files) directly to main afterward.
#>

param(
    [string]$Branch
)

$ErrorActionPreference = "Stop"

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }
Set-Location $repoRoot

# Pre-flight (#86): fold relies on scripts\repo-config.ps1 in the consumer's repo root. If that is
# missing -- typically on a clean consumer -- stop with a clear pointer instead of a raw
# dot-source error on the . (dot-source) line below.
$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Error "fold-changelog cannot run -- missing repo-owned file: $configPath (Get-RepoName / Get-RepoBlobUrl / Get-LintScript). This file is repo-specific and belongs in the consumer's repo root. Create it (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward."
    exit 1
}

# Repo name from the repo root's local repo-config (single source), no longer hardcoded.
# Deliberately from $repoRoot and not $PSScriptRoot: from the plugin mirror, $PSScriptRoot points
# to the plugin cache, while repo-config always lives in the consumer's repo root.
. (Join-Path $repoRoot 'scripts\repo-config.ps1')
$repo = Get-RepoName

# Pre-flight (#86): an unfilled scaffold (repo-config still at VUL-IN) would otherwise only fail
# further down with an unclear gh error. Stop here with a clear pointer.
if ($repo -match 'VUL-IN') {
    Write-Error "fold-changelog cannot run -- scripts\repo-config.ps1 still contains VUL-IN placeholders. Fill in Get-RepoName with this repo's value and run again."
    exit 1
}

# The 'Plugins:' detection relies on Get-TouchedPlugins from scripts\lib\release-lib.ps1 (#103,
# Victor #3) -- but release-lib.ps1 is deliberately NOT mirrored to the plugin (workshop-specific
# tooling, see scripts\lib\shared-scripts-lib.ps1), unlike this fold script itself. In the
# workshop root it simply exists; in a consumer repo running the plugin mirror it is missing, and
# the Plugins line is omitted -- functionally the same as before, since
# claude-code-plugins/claude-specialists/<plugin>/ paths do not exist there anyway.
$releaseLibPath = Join-Path $repoRoot 'scripts\lib\release-lib.ps1'
$canDetectPlugins = Test-Path -LiteralPath $releaseLibPath
if ($canDetectPlugins) { . $releaseLibPath }

# BOM-less UTF8 -- Set-Content -Encoding UTF8 always adds a BOM in Windows PowerShell 5.1,
# and the rest of the repo (CHANGELOG.md etc.) has no BOM.
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
    Write-Host "No entry files found to fold." -ForegroundColor Yellow
    exit 0
}

$changelogPath = Join-Path $repoRoot "CHANGELOG.md"
$headingPattern = '(?m)^## Pull Requests\s*?$'

foreach ($file in $entryFiles) {
    $filePath = Join-Path $repoRoot $file
    if (-not (Test-Path $filePath)) {
        Write-Host "Entry file '$file' not found - skipped." -ForegroundColor Yellow
        continue
    }

    $entryContent = (Get-Content -Path $filePath -Raw -Encoding UTF8).TrimEnd()
    $changelogContent = Get-Content -Path $changelogPath -Raw -Encoding UTF8

    $usesCRLF = $changelogContent.Contains("`r`n")
    $nl = if ($usesCRLF) { "`r`n" } else { "`n" }
    $entryContent = ($entryContent -replace "`r`n", "`n") -replace "`n", $nl

    # The entry file is already compact ("### <title> <midDot> <type> <midDot> <date>" +
    # description), matching the CHANGELOG format. Fold only adds '#NN <midDot> ' at the front of
    # the title and the PR link at the end. The PR number only exists after the merge; we fetch it
    # via the branch -- from -Branch, or in fold-all mode derived from the file name
    # (<prefix>-<rest>.md -> <prefix>/<rest>).
    $midDot = [char]0x00B7
    $branchForPr = $Branch
    if (-not $branchForPr) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $branchForPr = $base -replace '^([^-]+)-', '$1/'
    }
    # gh can write messages to stderr; under ErrorActionPreference=Stop, PS 5.1 would promote that
    # to a terminating error before the graceful $LASTEXITCODE handling below (the #107 pitfall).
    # Run under Continue and discard stderr (2>$null), so it cannot pollute the captured JSON
    # either. 'files' is simply included in --json (Victor #4, #103) -- gh pr list supplies that
    # field just as well as gh pr view, so the second gh call (previously gh pr view --json files)
    # has been dropped: one PR lookup suffices for both the number/url and the touched files.
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $prJson = gh pr list --head $branchForPr --state all --json number,url,files --limit 1 --repo $repo 2>$null
    $ghCode = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ($ghCode -ne 0) { Write-Host "  (gh pr list returned exit code $ghCode -- PR-number enrichment skipped; run gh manually for the reason.)" -ForegroundColor DarkYellow }
    $prs = if ($ghCode -eq 0 -and $prJson) { @($prJson | ConvertFrom-Json) } else { @() }
    if ($prs.Count -ge 1) {
        $num = $prs[0].number
        $entryContent = ([regex]'(?m)^### ').Replace($entryContent, "### #$num $midDot ", 1)

        # Deriving touched plugins from the PR files (automation-first): paths under
        # claude-code-plugins/claude-specialists/<plugin>/ become a 'Plugins:' line, which
        # cut-release.ps1 later uses to update the per-plugin CHANGELOGs. The detection itself
        # lives in the pure Get-TouchedPlugins (release-lib.ps1, #103) -- only the guard is here;
        # 'files' already came along with the gh pr list call above, so no separate gh roundtrip
        # is needed anymore.
        if ($canDetectPlugins) {
            $paths = @($prs[0].files | ForEach-Object { $_.path })
            $touched = @(Get-TouchedPlugins -Files $paths)
            if ($touched.Count -gt 0) {
                $entryContent = $entryContent.TrimEnd() + "$nl$nl" + ('Plugins: ' + ($touched -join ', '))
            }
        }

        $entryContent = $entryContent.TrimEnd() + "$nl$nl[PR #$num]($($prs[0].url))"
    }
    else {
        Write-Host "  No PR found for '$branchForPr' - entry without PR number/url." -ForegroundColor Yellow
    }

    $headingMatch = [regex]::Match($changelogContent, $headingPattern)
    if (-not $headingMatch.Success) {
        Write-Host "Could not find the '## Pull Requests' heading in CHANGELOG.md - stopping." -ForegroundColor Red
        exit 1
    }
    $afterHeader = $headingMatch.Index + $headingMatch.Length

    # Insert after any intro paragraph: before the first ###-entry in the Pull Requests section,
    # or - if the section is still empty - before the ## Releases heading. This keeps the intro
    # line at the top.
    $relMatch = [regex]::Match($changelogContent, '(?m)^## Releases\s*?$')
    $relPos = if ($relMatch.Success) { $relMatch.Index } else { $changelogContent.Length }
    $firstEntry = ([regex]'(?m)^### ').Match($changelogContent, $afterHeader)
    $insertPos = if ($firstEntry.Success -and $firstEntry.Index -lt $relPos) { $firstEntry.Index } else { $relPos }

    $entryBlock = "$entryContent$nl$nl---$nl$nl"
    $changelogContent = $changelogContent.Substring(0, $insertPos) + $entryBlock + $changelogContent.Substring($insertPos)

    Write-Utf8NoBom -Path $changelogPath -Content $changelogContent
    Remove-Item -Path $filePath -Force
    Write-Host "Folded and removed: $file" -ForegroundColor Green
}

Write-Host "CHANGELOG.md updated." -ForegroundColor Green
