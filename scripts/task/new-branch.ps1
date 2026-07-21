<#
.SYNOPSIS
    Creates (or idempotently reuses) a branch and immediately creates its changelog entry file.

.DESCRIPTION
    Core improvement: branch creation and changelog-entry creation used to be two separate manual
    steps (new-branch then new-changelog-entry.ps1) -- this script merges them into a single,
    idempotent call. Only git (checkout/checkout -b) + creating the entry; no push, no PR, nothing
    repo-specific.

    Validation runs via the shared SSOT helper Test-BranchName (scripts/lib/branch-info.ps1):
      - Hard reject (exit 1): empty name, name 'main', or a name that contains the substring
        'final'.
      - Soft warn (proceed): unknown branch prefix -- falls back further on 'Chore' (new-changelog-
        entry) resp. 'question' (open-pr), consistent with those scripts. Validation is deliberately
        delegated to the consumer's table, so extended prefixes (e.g. Shopify's style/, liquid/, ...)
        simply work without this script needing to know them.

.PARAMETER Name
    The branch name, form <prefix>/<short-name> (e.g. feat/new-plugin).

.PARAMETER Title
    (Optional) title for the changelog entry file, passed through to new-changelog-entry.ps1.
    Defaults to new-changelog-entry's own default ("TODO: title").

.EXAMPLE
    ./scripts/task/new-branch.ps1 -Name feat/new-plugin -Title "New domain plugin"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$Title = "TODO: title"
)

$ErrorActionPreference = 'Stop'

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# Pre-flight (#86): this script relies ONLY on scripts\lib\branch-info.ps1 in the consumer's repo
# root (no repo-config, no gh). If that is missing -- typically on a clean consumer -- stop with a
# clear pointer instead of a raw dot-source error below.
$branchInfoPath = Join-Path $repoRoot 'scripts\lib\branch-info.ps1'
if (-not (Test-Path -LiteralPath $branchInfoPath)) {
    Write-Error "new-branch cannot run -- missing repo-owned file: $branchInfoPath (Get-BranchInfo / Test-BranchName / the branch prefix table). This file is repo-specific and belongs in the consumer's repo root. Create it (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward."
    exit 1
}
. $branchInfoPath

# Validation via the shared SSOT helper -- no inline repetition of the hard-reject rules.
$check = Test-BranchName -Branch $Name
if (-not $check.IsValid) {
    Write-Error "new-branch cannot run -- invalid branch name '$Name': $($check.Reason)"
    exit 1
}
if (-not $check.IsKnown) {
    Write-Warning "Unknown branch prefix in '$Name' -- new-changelog-entry falls back to 'Chore', open-pr later to label 'question'. Classify manually if needed."
}

# Note: Test-BranchName above only catches the explicitly named hard rejects (empty/'main'/
# 'final'). Protection against e.g. backslashes, '..', or a leading hyphen in $Name does NOT rely
# on custom code here, but implicitly on git's own `check-ref-format` validation, which `git checkout
# -b` below enforces itself (with exit 128 on an invalid ref name). If you ever change the
# checkout mechanism (e.g. to `git branch` + a separate `checkout`, or to libgit2), check whether
# that implicit gate does not silently disappear.
#
# Idempotent: if the branch already exists locally, just check it out; otherwise create it.
# Deliberately `git -C $repoRoot` instead of Set-Location -- this script stays composable and does
# not mutate the caller's cwd. git sometimes writes progress/errors to stderr; under
# ErrorActionPreference=Stop, PS 5.1 would promote that to a terminating error before the graceful
# $LASTEXITCODE handling (the #107 pitfall, see also open-pr.ps1) -- so run under Continue, capture
# output, and only then judge.
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $null = & git -C $repoRoot rev-parse --verify --quiet "refs/heads/$Name" 2>&1
    $existsCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prevEap
}
$branchExists = ($existsCode -eq 0)

$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    if ($branchExists) {
        $checkoutOutput = & git -C $repoRoot checkout $Name 2>&1
    } else {
        $checkoutOutput = & git -C $repoRoot checkout -b $Name 2>&1
    }
    $checkoutCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prevEap
}
$checkoutOutput | ForEach-Object { Write-Host $_ }
if ($checkoutCode -ne 0) {
    Write-Error "git checkout of '$Name' failed."
    exit 1
}
if ($branchExists) {
    Write-Host "Branch '$Name' already existed -- checked out." -ForegroundColor Yellow
} else {
    Write-Host "Branch '$Name' created and checked out." -ForegroundColor Green
}

# Entry creation as a CHILD process: new-changelog-entry.ps1 can internally do `exit 0` (entry
# already exists) or `exit 1` (on main) -- as a child process that exit does not kill this script,
# only the child. Sibling shared script relative to $PSScriptRoot (both scripts travel together as
# a mirror pair, see scripts/lib/shared-scripts-lib.ps1). `checkout`/`checkout -b` above has already
# switched HEAD, so new-changelog-entry derives the right branch itself from HEAD.
#
# $Title as a standalone CLI argument across this native process boundary is an injection
# primitive: free text (e.g. plausibly copied from an external issue/PR title) with `"`/backslashes
# can break the child process's argv reconstruction. Therefore it is NOT passed here as
# `-Title $Title`, but via an environment variable -- environment variable values do not go through
# argv requoting, so the injection disappears. `finally` also cleans up the var on an error, so
# nothing leaks to a subsequent process in the same session.
try {
    $env:CLAUDE_NEWBRANCH_TITLE = $Title
    $entryScript = Join-Path $PSScriptRoot '..\release\new-changelog-entry.ps1'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $entryScript
    $entryCode = $LASTEXITCODE
} finally {
    Remove-Item Env:CLAUDE_NEWBRANCH_TITLE -ErrorAction SilentlyContinue
}

exit $entryCode
