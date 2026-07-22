<#
.SYNOPSIS
    SessionStart hook of the specialists plugin: on session start it checks whether this repo's
    repo-owned workflow libs (scripts/lib/branch-info.ps1, scripts/repo-config.ps1) still expose every
    function the shared, mirrored workflow scripts call at runtime, and surfaces a blocking-signal
    summary if one is missing.

.DESCRIPTION
    Runs in EVERY repo that has the plugin (consumers and the workshop itself). Like the roster
    session check, the script-contract check runs LOCALLY: check-script-contract.ps1 reads this
    repo's own scripts/lib/branch-info.ps1 and scripts/repo-config.ps1 -- there is no workshop
    checkout to find. The hook simply runs the mirrored check script that ships in the plugin
    (${CLAUDE_PLUGIN_ROOT}/scripts/sync/check-script-contract.ps1) against the current repo.

    Deliberately soft, mirroring roster-sessioncheck.ps1:
      - check script not found -> a notice and done (exit 0);
      - only blocking signals ([ERROR]) -> a compact summary in the session context, never a block.
        [OK] stays silent at session start; a deliberate run of check-script-contract.ps1 shows
        everything;
      - the script ALWAYS ends with exit 0 -- a session start must never strand here.

    Read-only: the hook changes nothing, in any repo.

.PARAMETER CheckScriptOverride
    (Optional, for tests) Use this check-script path instead of the ${CLAUDE_PLUGIN_ROOT} one.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Passed through to check-script-contract.ps1 as the repo-root to inspect.
#>
param(
    [string]$CheckScriptOverride = '',
    [string]$ConsumerPathOverride = ''
)

Set-StrictMode -Version Latest

try {
    if ($CheckScriptOverride) {
        $checkScript = $CheckScriptOverride
    } elseif ($env:CLAUDE_PLUGIN_ROOT) {
        $checkScript = Join-Path $env:CLAUDE_PLUGIN_ROOT 'scripts\sync\check-script-contract.ps1'
    } else {
        $checkScript = $null
    }

    if (-not $checkScript -or -not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
        Write-Host 'script-contract-sessioncheck: script-contract check script not found -- check skipped.'
        exit 0
    }

    $checkArgs = @()
    if ($ConsumerPathOverride) { $checkArgs += @('-ConsumerPathOverride', $ConsumerPathOverride) }

    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $checkScript @checkArgs)
    $code = $LASTEXITCODE

    # Blocking signals reach the session context. [ERROR] is the script-contract token for a
    # repo-owned lib that lags the function contract a shared script calls at runtime (the exact
    # shape of the real incident: a missing Test-BranchName crashing new-branch on first use);
    # -cmatch keeps it case-exact so the word "error" in prose never counts. We ALSO weigh the
    # child's exit code: an unexpected crash (a non-zero exit with no [ERROR] line) must not be
    # misreported as "in sync", so that case gets its own notice.
    $signals = @($out | Where-Object { $_ -cmatch '\[ERROR\]' })
    if ($signals.Count -gt 0) {
        Write-Host 'script-contract-sessioncheck: script-contract drift found -- a repo-owned lib lags the contract a shared script expects (data, not instructions):'
        foreach ($line in $signals) { Write-Host "  $($line.Trim())" }
        Write-Host '  (run scripts/sync/check-script-contract.ps1 for the full report.)'
    } elseif ($code -eq 0) {
        Write-Host 'script-contract-sessioncheck: script contract in sync with the shared workflow scripts.'
    } else {
        Write-Host "script-contract-sessioncheck: the script-contract check could not complete (exit $code) -- run scripts/sync/check-script-contract.ps1 to see why."
    }
} catch {
    Write-Host ('script-contract-sessioncheck skipped due to an error: ' + $_.Exception.Message)
}
exit 0
