<#
.SYNOPSIS
    Push the current branch and open a Pull Request to main.

.DESCRIPTION
    Pushes the current branch to origin and creates a PR to main via the GitHub CLI. Guardrail:
    refuses if you are on main. Uses .github/pull_request_template.md as the starting point for
    the PR body unless you supply -Body yourself (NOTE: gh pr create --fill fills the body with
    the full commit history since main, not with the template -- so don't use that if you want
    the checklist template).

    Auto-fill (if you do NOT supply -Body): the script fills in the template itself as much as
    possible, so the PR never lands on github.com as an empty form:
      1. The correct "Type of change" box is ticked based on the branch prefix (the same source
         as the label -- the `<prefix>/` rule in the template).
      2. "What does this change do?" is filled with the description from the changelog entry file
         (<SafeName>.md in the repo root), which always exists on the branch. So you never have to
         type anything twice.
      3. The two checklist items that are always true at that point are ticked: "Changelog entry
         file created" (exists, since it was just read) and "Requested by Dave" (the script only
         runs at Dave's request). The remaining checklist items stay empty -- those are human
         judgement checks the script cannot honestly verify.
      If you do supply -Body, it is used literally (override).

    ALWAYS sets a GitHub label based on the branch prefix (every PR has a label). The
    prefix-to-label table lives in scripts/lib/branch-info.ps1 (shared with the other scripts) and
    follows the main categories of the PR template. Unknown prefix -> label 'question' + warning
    (= needs further classification).

    Lint gate (guardrail for main): before the push, scripts/lint/check-plugin-integrity.ps1 runs.
    If that finds errors (invalid marketplace/plugin manifests, missing agent-def frontmatter,
    dead links), the branch is NOT pushed and NO PR is opened. Use -SkipLint to deliberately skip
    the gate (escape valve).

    Test gate (a lesson from PR #54, where a red suite only surfaced on CI): after the lint, ALL
    test suites run (scripts/tests/*.tests.ps1), exactly as CI does. A failing suite blocks the
    push and the PR. Use -SkipTests to deliberately skip this gate (escape valve).

.PARAMETER Title
    PR title, e.g. "feat: new domain plugin" or "fix: broken agent-def frontmatter".

.PARAMETER Body
    (Optional) PR description. Default: the filled-in .github/pull_request_template.md.

.EXAMPLE
    ./scripts/release/open-pr.ps1 -Title "feat: new domain plugin"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Title,
    [string]$Body = '',
    [switch]$SkipLint,
    [switch]$SkipTests
)
$ErrorActionPreference = 'Stop'

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# Pre-flight (#86): the shared scripts rely on two repo-owned files in the consumer's repo root.
# If they are missing -- typically on a clean consumer where they have not yet been created --
# stop with a clear pointer instead of a raw dot-source error (the path-not-found you would
# otherwise get on the . (dot-source) lines below).
$needed = @('scripts\repo-config.ps1', 'scripts\lib\branch-info.ps1')
$absent = @($needed | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_)) })
if ($absent.Count -gt 0) {
    Write-Error ("open-pr cannot run -- missing repo-owned configuration in the repo root ($repoRoot):`n  " + ($absent -join "`n  ") + "`n`nThese files are repo-specific and belong in the consumer's repo root:`n  scripts\repo-config.ps1      -- Get-RepoName / Get-RepoBlobUrl / Get-LintScript`n  scripts\lib\branch-info.ps1  -- the repo-owned branch-prefix table`n`nCreate them (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward.")
    exit 1
}

# Repo-owned config + shared branch lib from the repo root (single source). Deliberately from
# $repoRoot and not $PSScriptRoot: from the plugin mirror, $PSScriptRoot points to the plugin
# cache, while repo-config/branch-info always live in the consumer's repo root.
. (Join-Path $repoRoot 'scripts\repo-config.ps1')
. (Join-Path $repoRoot 'scripts\lib\branch-info.ps1')
$repo = Get-RepoName

# Pre-flight (#86): an unfilled scaffold (repo-config still at VUL-IN) would otherwise only fail
# further down with an unclear gh error. Stop here with a clear pointer.
if ($repo -match 'VUL-IN' -or (Get-LintScript) -match 'VUL-IN') {
    Write-Error "open-pr cannot run -- scripts\repo-config.ps1 still contains VUL-IN placeholders. Fill in Get-RepoName and Get-LintScript with this repo's values and run again."
    exit 1
}

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq 'main') { Write-Error "You are on main; a PR is created from a branch."; exit 1 }

# Lint gate: catch invalid manifests/frontmatter/dead links before they land on main via a PR.
# The lint script is repo-specific (via repo-config); errors block (exit code 1). -SkipLint
# deliberately skips the gate.
if (-not $SkipLint) {
    $lintPath = Join-Path $repoRoot (Get-LintScript)
    if (Test-Path $lintPath) {
        Write-Host "lint gate: integrity check for the PR..." -ForegroundColor Cyan
        & powershell -NoProfile -ExecutionPolicy Bypass -File $lintPath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "lint gate found errors - branch not pushed, no PR opened. Fix the errors, or run with -SkipLint to skip the gate."
            exit 1
        }
    } else {
        Write-Warning "lint script not found at '$lintPath' - lint gate skipped."
    }
}

# Test gate: all suites, exactly as CI -- a red suite should already block here, not only at the
# PR (a lesson from PR #54). -SkipTests is the deliberate escape valve.
if (-not $SkipTests) {
    $testsDir = Join-Path $repoRoot 'scripts\tests'
    if (Test-Path $testsDir) {
        Write-Host "test gate: running all test suites for the PR..." -ForegroundColor Cyan
        $testFailed = $false
        $suites = @(Get-ChildItem -Path $testsDir -Filter '*.tests.ps1' -File)
        if ($suites.Count -eq 0) {
            Write-Warning "no *.tests.ps1 suites found in scripts/tests - test gate had nothing to run."
        }
        $suites | ForEach-Object {
            Write-Host "== $($_.Name) ==" -ForegroundColor Cyan
            & powershell -NoProfile -ExecutionPolicy Bypass -File $_.FullName
            if ($LASTEXITCODE -ne 0) { $testFailed = $true }
        }
        if ($testFailed) {
            Write-Error "test gate found failing suites - branch not pushed, no PR opened. Fix the tests, or run with -SkipTests to skip the gate."
            exit 1
        }
    } else {
        Write-Warning "scripts/tests not found - test gate skipped."
    }
}

# git push writes its 'remote:' progress to stderr. Under ErrorActionPreference=Stop, PowerShell
# 5.1 promotes those stderr lines to a TERMINATING NativeCommandError -- the script would then die
# on the push before the exit-code check below runs, even though git itself gave exit 0 (the same
# class of pitfall as #96/#97: never rely on stderr-as-error, always on $LASTEXITCODE).
# So the push runs with EAP=Continue, capturing the full output, immediately recording the exit
# code, and only then judging.
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $pushOutput = & git push -u origin $branch 2>&1
    $pushCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prevEap
}
$pushOutput | ForEach-Object { Write-Host $_ }
if ($pushCode -ne 0) { Write-Error "git push failed."; exit 1 }

$info = Get-BranchInfo -Branch $branch
if ($info.IsKnown) {
    $label = $info.Label
} else {
    $label = 'question'
    Write-Warning "Unknown branch prefix '$($info.Prefix)' - label 'question' set; classify the PR manually."
}

if (-not $Body) {
    $templatePath = Join-Path $repoRoot ".github\pull_request_template.md"
    if (Test-Path $templatePath) {
        $templateLines = Get-Content -Path $templatePath -Encoding UTF8

        # Description from the changelog entry file <SafeName>.md: everything after the compact
        # ###-heading line ("### title - type - date"). This file always exists on the branch.
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

# Body via a temp file: --body $Body would let PowerShell 5.1 mangle embedded quotes on native
# commands, causing gh to read the body as separate arguments.
$bodyFile = Join-Path ([System.IO.Path]::GetTempPath()) "open-pr-body-$PID.md"
[System.IO.File]::WriteAllText($bodyFile, $Body, (New-Object System.Text.UTF8Encoding $false))
$prevEap = $ErrorActionPreference
try {
    # gh writes some of its progress/URL to stderr; under EAP=Stop, PS 5.1 would promote that to a
    # terminating error before the $LASTEXITCODE check (the same pitfall as the push above, #107).
    # Run under Continue, capture the output, and only then judge on the exit code.
    $ErrorActionPreference = 'Continue'
    $createOut = & gh pr create --base main --head $branch --title $Title --body-file $bodyFile --label $label --repo $repo 2>&1
    $createCode = $LASTEXITCODE
    $createOut | ForEach-Object { Write-Host $_ }
    if ($createCode -ne 0) { Write-Error "Creating the PR failed (is gh logged in?)."; exit 1 }
} finally {
    $ErrorActionPreference = $prevEap
    Remove-Item -Path $bodyFile -Force -ErrorAction SilentlyContinue
}
Write-Host "PR created for '$branch'." -ForegroundColor Green
