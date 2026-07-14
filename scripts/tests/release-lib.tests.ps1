<#
.SYNOPSIS
    Regressietests voor scripts/lib/release-lib.ps1 (de pure release-helpers).

.DESCRIPTION
    Dependency-vrij: geen Pester nodig, alleen PowerShell. Dot-source't de lib en draait een reeks
    asserts. Exit-code 0 als alles slaagt, 1 bij de eerste faal -- zo bruikbaar in een CI-poort.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/release-lib.tests.ps1

    Puur ASCII (repo-conventie voor .ps1). Verwachte niet-ASCII output-tekens (middot, em-dash) worden
    via [char]0x.. gebouwd, net als in de lib zelf.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         verwacht: '$Expected'`n         kreeg:    '$Actual'" -ForegroundColor Red
    }
}

function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name (patroon '$Pattern' niet gevonden)" -ForegroundColor Red
    }
}

function Assert-Throws {
    param([scriptblock]$Block, [string]$Name)
    try { & $Block; $script:fail++; Write-Host "  [FAIL] $Name (verwachtte een exception)" -ForegroundColor Red }
    catch { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
}

$midDot = [char]0x00B7
$emDash = [char]0x2014

Write-Host "Get-NextVersion" -ForegroundColor Cyan
Assert-Equal '0.2.0' (Get-NextVersion -Current '0.1.0' -BumpKind 'minor') 'minor bumpt tweede cijfer, nult patch'
Assert-Equal '0.1.1' (Get-NextVersion -Current '0.1.0' -BumpKind 'patch') 'patch bumpt derde cijfer'
Assert-Equal '1.0.0' (Get-NextVersion -Current '0.9.9' -BumpKind 'major') 'major nult minor + patch'
Assert-Throws { Get-NextVersion -Current 'x.y.z' -BumpKind 'patch' } 'ongeldige huidige versie gooit'

Write-Host "Get-LockstepVersion" -ForegroundColor Cyan
Assert-Equal '0.1.0' (Get-LockstepVersion -ManifestContents @{ a = '{"version": "0.1.0"}'; b = '{"version": "0.1.0"}' }) 'gelijke versies -> die versie'
Assert-Throws { Get-LockstepVersion -ManifestContents @{ a = '{"version": "0.1.0"}'; b = '{"version": "0.2.0"}' } } 'ongelijke versies gooit'
Assert-Throws { Get-LockstepVersion -ManifestContents @{ a = '{"name": "x"}' } } 'ontbrekende version gooit'

Write-Host "Convert-ChangelogForRelease" -ForegroundColor Cyan
$sample = @"
# Changelog

Intro-regel van het bestand.

## Pull Requests

Intro van de PR-sectie.

### #2 $midDot Tweede $midDot Feat $midDot 2026-01-02

Body twee.

[PR #2](https://example.com/2)

---

### #1 $midDot Eerste $midDot Docs $midDot 2026-01-01

Body een.

[PR #1](https://example.com/1)

## Releases

Nog geen releases vastgelegd. Versiebeheer loopt per plugin.
"@

$result = Convert-ChangelogForRelease -Content $sample -Version '0.2.0' -Date '2026-07-14'
Assert-Match $result "### v0\.2\.0 $([regex]::Escape($midDot)) 2026-07-14" 'versieblok-kop met versie en datum'
Assert-Match $result '2 pull requests in deze release' 'telt beide PRs, meervoud'
Assert-Match $result '- #2 .* Tweede .* \[PR #2\]' 'bullet voor PR #2 met link'
Assert-Match $result '- #1 .* Eerste .* \[PR #1\]' 'bullet voor PR #1 met link'
Assert-Match $result 'De vastgelegde versies van de marketplace' 'placeholder-intro vervangen'
# Pull-Requests-sectie is geleegd: geen ### -entries meer tussen de twee kopjes.
$prSection = ($result -split '## Releases')[0]
Assert-Equal $false ([bool]($prSection -match '(?m)^### ')) 'Pull Requests-sectie bevat geen entries meer'
Assert-Match $result '(?s)Intro van de PR-sectie' 'PR-intro blijft staan'

# Randgevallen.
Assert-Throws { Convert-ChangelogForRelease -Content $result -Version '0.3.0' -Date '2026-07-14' } 'lege PR-sectie -> niets te releasen gooit'
Assert-Throws { Convert-ChangelogForRelease -Content "# Changelog`n`n## Releases`n" -Version '0.2.0' -Date '2026-07-14' } 'ontbrekende Pull Requests-sectie gooit'

# Enkelvoud bij precies 1 PR.
$one = @"
## Pull Requests

Intro.

### #1 $midDot Enige $midDot Feat $midDot 2026-01-01

Body.

[PR #1](https://example.com/1)

## Releases

Nog geen releases vastgelegd.
"@
$r1 = Convert-ChangelogForRelease -Content $one -Version '1.0.0' -Date '2026-07-14'
Assert-Match $r1 '1 pull request in deze release' 'enkelvoud bij 1 PR'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAALT: $($script:fail) fout, $($script:pass) goed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: alle $($script:pass) asserts geslaagd." -ForegroundColor Green
exit 0
