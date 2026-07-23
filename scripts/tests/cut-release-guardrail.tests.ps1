<#
.SYNOPSIS
    Drift guard for cut-release.ps1's stray-entry allowlist ($reservedRootMd).

.DESCRIPTION
    cut-release.ps1 refuses to cut a release while an "unfolded changelog entry file" sits in the
    repo root. It recognises an entry by exclusion: every root *.md that is NOT in the $reservedRootMd
    allowlist is treated as an entry. That is deliberately catch-all (so an entry with an unknown
    branch prefix is never missed), but it means every PERMANENT root doc (README, CONTRIBUTING,
    SECURITY, ...) must be listed in the allowlist -- otherwise a release falsely refuses to cut the
    moment such a doc is added. That drift once blocked a real release (CONTRIBUTING.md/SECURITY.md
    were added to the root but not to the allowlist).

    This test catches that drift automatically: every TRACKED root *.md that is not a branch-prefixed
    changelog entry (feat-/fix-/docs-/chore-*.md) must appear in cut-release.ps1's $reservedRootMd.
    Reads the allowlist straight out of the script text (cut-release.ps1 runs its guardrails on load,
    so it cannot be dot-sourced) and compares it against the actual tracked root docs via git.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/cut-release-guardrail.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot       = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$CutReleasePath = Join-Path $RepoRoot 'scripts\release\cut-release.ps1'

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

Write-Host "cut-release.ps1 -- reserved-root-md allowlist covers every permanent root doc" -ForegroundColor Cyan

# 1. Parse the allowlist literal out of the script text.
$cutReleaseText = [System.IO.File]::ReadAllText($CutReleasePath, [System.Text.Encoding]::UTF8)
$m = [regex]::Match($cutReleaseText, '\$reservedRootMd\s*=\s*@\(([^)]*)\)')
Assert-True $m.Success 'found the $reservedRootMd allowlist literal in cut-release.ps1'
$allowlist = @([regex]::Matches($m.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
Assert-True ($allowlist.Count -gt 0) 'allowlist parsed to at least one entry'

# 2. Tracked root *.md files (no directory separator = repo root), excluding branch-prefixed entries.
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $tracked = @(& git -C $RepoRoot ls-files -- '*.md' 2>$null)
} finally {
    $ErrorActionPreference = $prevEap
}
$rootMd = @($tracked | Where-Object { $_ -and ($_ -notmatch '/') })
# A branch changelog entry file is named after its branch: <prefix>-<name>.md with a known prefix.
$entryPattern = '^(feat|fix|docs|chore)-.*\.md$'
$permanentDocs = @($rootMd | Where-Object { $_ -notmatch $entryPattern })
Assert-True ($permanentDocs.Count -gt 0) 'found tracked permanent root docs to check'

# 3. Every permanent root doc must be covered by the allowlist -- otherwise a release would falsely
#    flag it as an unfolded entry and refuse to cut.
$uncovered = @($permanentDocs | Where-Object { $allowlist -notcontains $_ })
Assert-True ($uncovered.Count -eq 0) "every permanent root doc is in `$reservedRootMd (uncovered: $($uncovered -join ', '))"

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
