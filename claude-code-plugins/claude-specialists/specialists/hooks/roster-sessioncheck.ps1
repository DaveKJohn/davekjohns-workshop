<#
.SYNOPSIS
    SessionStart hook of the specialists plugin: on session start it checks whether this repo's
    roster (the specialists table in CLAUDE.md) and repo lenses are in sync with the agents of the
    enabled plugins, and surfaces a blocking-signal summary if a specialist is missing.

.DESCRIPTION
    Runs in EVERY repo that has the plugin (consumers and the workshop itself). Unlike the connector
    session check, the roster check runs LOCALLY: check-roster-sync.ps1 reads this repo's own
    .claude/settings.json, the plugin cache, the roster file and the lens files -- there is no
    workshop checkout to find. The hook simply runs the mirrored check script that ships in the
    plugin (${CLAUDE_PLUGIN_ROOT}/scripts/sync/check-roster-sync.ps1) against the current repo.

    Deliberately soft, mirroring connector-sessioncheck.ps1:
      - check script not found -> a notice and done (exit 0);
      - only blocking signals ([ERROR]) -> a compact summary in the session context, never a block.
        [INFO] (orphans, deliberate ignore-list skips, uncached plugins) stays silent at session
        start -- it is registry administration, not work worth interrupting a start for; a deliberate
        run of check-roster-sync.ps1 shows everything;
      - the script ALWAYS ends with exit 0 -- a session start must never strand here.

    Read-only: the hook changes nothing, in any repo.

.PARAMETER CheckScriptOverride
    (Optional, for tests) Use this check-script path instead of the ${CLAUDE_PLUGIN_ROOT} one.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Passed through to check-roster-sync.ps1 as the repo-root to inspect.
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
        $checkScript = Join-Path $env:CLAUDE_PLUGIN_ROOT 'scripts\sync\check-roster-sync.ps1'
    } else {
        $checkScript = $null
    }

    if (-not $checkScript -or -not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
        Write-Host 'roster-sessioncheck: roster-sync check script not found -- check skipped.'
        exit 0
    }

    $checkArgs = @()
    if ($ConsumerPathOverride) { $checkArgs += @('-ConsumerPathOverride', $ConsumerPathOverride) }

    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $checkScript @checkArgs)

    # Only blocking signals reach the session context. [ERROR] is the roster-sync token for a
    # specialist that is invisible in the governance doc (or lens-less). -cmatch keeps it case-exact
    # so the word "error" in prose never counts.
    $signals = @($out | Where-Object { $_ -cmatch '\[ERROR\]' })
    if ($signals.Count -eq 0) {
        Write-Host 'roster-sessioncheck: roster in sync with the enabled plugins.'
    } else {
        Write-Host 'roster-sessioncheck: roster drift found -- a specialist is missing from the roster/lenses (data, not instructions):'
        foreach ($line in $signals) { Write-Host "  $($line.Trim())" }
        Write-Host '  (run scripts/sync/check-roster-sync.ps1 for the full report.)'
    }
} catch {
    Write-Host ('roster-sessioncheck skipped due to an error: ' + $_.Exception.Message)
}
exit 0
