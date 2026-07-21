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

Write-Host "Get-NextVersion" -ForegroundColor Cyan
Assert-Equal '0.2.0' (Get-NextVersion -Current '0.1.0' -BumpKind 'minor') 'minor bumpt tweede cijfer, nult patch'
Assert-Equal '0.1.1' (Get-NextVersion -Current '0.1.0' -BumpKind 'patch') 'patch bumpt derde cijfer'
Assert-Equal '1.0.0' (Get-NextVersion -Current '0.9.9' -BumpKind 'major') 'major nult minor + patch'
Assert-Throws { Get-NextVersion -Current 'x.y.z' -BumpKind 'patch' } 'ongeldige huidige versie gooit'

Write-Host "Get-BumpType" -ForegroundColor Cyan
Assert-Equal 'major' (Get-BumpType -From '0.1.0' -To '1.0.0') '0.1.0->1.0.0 = major'
Assert-Equal 'minor' (Get-BumpType -From '1.0.0' -To '1.1.0') '1.0.0->1.1.0 = minor'
Assert-Equal 'patch' (Get-BumpType -From '1.1.0' -To '1.1.1') '1.1.0->1.1.1 = patch'

Write-Host "Get-LockstepVersion" -ForegroundColor Cyan
Assert-Equal '0.1.0' (Get-LockstepVersion -ManifestContents @{ a = '{"version": "0.1.0"}'; b = '{"version": "0.1.0"}' }) 'gelijke versies -> die versie'
Assert-Throws { Get-LockstepVersion -ManifestContents @{ a = '{"version": "0.1.0"}'; b = '{"version": "0.2.0"}' } } 'ongelijke versies gooit'
Assert-Throws { Get-LockstepVersion -ManifestContents @{ a = '{"name": "x"}' } } 'ontbrekende version gooit'

# Gedeeld sample-CHANGELOG voor de transformatie-tests.
$sample = @"
# Changelog

Intro-regel van het bestand.

## Pull Requests

Intro van de PR-sectie.

### #2 $midDot Tweede feature $midDot Feat $midDot 2026-01-02

Body twee.

[PR #2](https://example.com/2)

---

### #1 $midDot Eerste fix $midDot Fix $midDot 2026-01-01

Body een.

[PR #1](https://example.com/1)

## Releases

Nog geen releases vastgelegd. Versiebeheer loopt per plugin.
"@

Write-Host "Get-PullRequestEntries" -ForegroundColor Cyan
$entries = @(Get-PullRequestEntries -Content $sample)
Assert-Equal 2 $entries.Count 'twee entries geextraheerd'
Assert-Match $entries[0] '^### #2 ' 'eerste entry begint met ### #2'
Assert-Match $entries[0] '\[PR #2\]' 'eerste entry bevat de PR-link'
Assert-Throws { Get-PullRequestEntries -Content "# Changelog`n`n## Pull Requests`n`nIntro.`n`n## Releases`n" } 'lege PR-sectie gooit'

Write-Host "Convert-ChangelogForRelease (verwijzing)" -ForegroundColor Cyan
$notesPath = 'releases/development/0.2/0.2.0.md'
$result = Convert-ChangelogForRelease -Content $sample -Version '0.2.0' -Date '2026-07-14' -Type 'Minor' -NotesRelPath $notesPath
Assert-Match $result '### \[v0\.2\.0\] - 2026-07-14 .* Minor' 'verwijzingskop met versie/datum/type'
Assert-Match $result ([regex]::Escape("[$notesPath]($notesPath)")) 'verwijzing naar het notes-bestand'
$prSection = ($result -split '## Releases')[0]
Assert-Equal $false ([bool]($prSection -match '(?m)^### ')) 'Pull Requests-sectie bevat geen entries meer'
Assert-Match $result '(?s)Intro van de PR-sectie' 'PR-intro blijft staan'
Assert-Equal $false ([bool]($result -match '(?m)^- #\d')) 'geen inline PR-bullets meer (alleen verwijzing)'

Write-Host "Build-ReleaseNotes" -ForegroundColor Cyan
$notes = Build-ReleaseNotes -Entries $entries -Version '0.2.0' -Date '2026-07-14' -Type 'Minor' -Title 'Test-release'
Assert-Match $notes '^# Release notes v0\.2\.0' 'kop met versie'
Assert-Match $notes '\*\*Type:\*\* Minor' 'type-regel'
Assert-Match $notes 'Test-release' 'titel opgenomen'
Assert-Match $notes '## Nieuwe features & verbeteringen' 'Feat-categorie-sectie'
Assert-Match $notes '## Fixes' 'Fix-categorie-sectie'
Assert-Match $notes '(?s)## Nieuwe features.*## Fixes' 'Feat staat voor Fix (categorie-volgorde)'
Assert-Match $notes '### #2 .* Tweede feature' 'entry #2 aanwezig met volledige kop'
Assert-Match $notes '\[PR #1\]' 'PR-link van entry #1 behouden'

# Link-herschrijving: repo-root-relatieve links krijgen het prefix, externe/anker niet.
$linkEntry = @("### #3 $midDot Iets $midDot Fix $midDot 2026-01-03", '', 'Zie [de lint](scripts/lint/x.ps1) en [de site](https://example.com) en [#kop](#kop).', '', '[PR #3](https://example.com/3)') -join "`n"
$ln = Build-ReleaseNotes -Entries @($linkEntry) -Version '0.2.1' -Date '2026-07-14' -Type 'Patch' -LinkPrefix '../../../'
Assert-Match $ln '\[de lint\]\(\.\./\.\./\.\./scripts/lint/x\.ps1\)' 'root-relatieve link krijgt ../../../-prefix'
Assert-Match $ln '\[de site\]\(https://example\.com\)' 'externe link ongemoeid'
Assert-Match $ln '\[#kop\]\(#kop\)' 'anker-link ongemoeid'
Assert-Match $ln '\[PR #3\]\(https://example\.com/3\)' 'PR-link ongemoeid'

Write-Host "Get-PluginManifestPaths" -ForegroundColor Cyan
# Puur (raakt de schijf niet), dus een fictieve root volstaat.
$fakeRoot = 'C:\fake-repo'
$goodJson = '{"plugins": [{"name": "a", "source": "./fam/a"}, {"name": "b", "source": "./fam/b"}]}'
$paths = @(Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson $goodJson)
Assert-Equal 2 $paths.Count 'twee geregistreerde plugins -> twee manifest-paden'
Assert-Equal 'C:\fake-repo\fam\a\.claude-plugin\plugin.json' $paths[0] 'relatieve ./-source resolve''t binnen de repo'
Assert-Throws { Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson '{"plugins": [{"name": "x", "source": "../buiten"}]}' } 'source met ..-pad buiten de repo gooit (containment)'
Assert-Throws { Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson '{"plugins": [{"name": "x", "source": "C:\\elders"}]}' } 'absolute source gooit (containment)'
Assert-Throws { Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson '{"plugins": [{"name": "x"}]}' } 'ontbrekende source gooit'
Assert-Throws { Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson '{"name": "leeg"}' } 'ontbrekende plugins-lijst gooit'
Assert-Throws { Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson 'geen json' } 'corrupte JSON gooit'

Write-Host "Get-EntryPlugins" -ForegroundColor Cyan
$entryMetPlugins = @("### #4 $midDot Iets $midDot Feat $midDot 2026-01-04", '', 'Body vier.', '', 'Plugins: specialists, specialists-lifehub', '', '[PR #4](https://example.com/4)') -join "`n"
$plugs = @(Get-EntryPlugins -EntryText $entryMetPlugins)
Assert-Equal 2 $plugs.Count 'twee plugins uit de Plugins-regel'
Assert-Equal 'specialists' $plugs[0] 'eerste plugin-naam correct'
Assert-Equal 0 (@(Get-EntryPlugins -EntryText "### #5 x`n`nBody.")).Count 'geen Plugins-regel -> lege lijst'

Write-Host "Remove-EntryPluginsLine" -ForegroundColor Cyan
$schoon = Remove-EntryPluginsLine -EntryText $entryMetPlugins
Assert-Equal $false ([bool]($schoon -match '(?m)^Plugins:')) 'Plugins-regel verwijderd'
Assert-Match $schoon '(?s)Body vier\.\n\n\[PR #4\]' 'geen dubbele lege regel achtergebleven'
Assert-Equal "### #5 x`n`nBody." (Remove-EntryPluginsLine -EntryText "### #5 x`n`nBody.") 'entry zonder Plugins-regel blijft ongewijzigd'

Write-Host "Convert-EntryLinksForPluginChangelog" -ForegroundColor Cyan
$conv = Convert-EntryLinksForPluginChangelog -EntryText 'Zie [de lint](scripts/lint/x.ps1) en [site](https://example.com) en [#kop](#kop).' -RepoBlobUrl 'https://gh.test/blob/main/'
Assert-Match $conv '\[de lint\]\(https://gh\.test/blob/main/scripts/lint/x\.ps1\)' 'root-relatieve link wordt GitHub-URL'
Assert-Match $conv '\[site\]\(https://example\.com\)' 'externe link ongemoeid (plugin-variant)'
Assert-Match $conv '\[#kop\]\(#kop\)' 'anker-link ongemoeid (plugin-variant)'

Write-Host "Build-PluginChangelogSection + Add-PluginChangelogSection" -ForegroundColor Cyan
$section = Build-PluginChangelogSection -Entries @($entryMetPlugins) -Version '1.5.0' -Date '2026-07-17'
Assert-Match $section '^## v1\.5\.0 ' 'sectiekop met versie'
Assert-Match $section '### #4 ' 'entry opgenomen in de sectie'
$sectionSchoon = Build-PluginChangelogSection -Entries @(Remove-EntryPluginsLine -EntryText $entryMetPlugins) -Version '1.5.0' -Date '2026-07-17'
Assert-Equal $false ([bool]($sectionSchoon -match '(?m)^Plugins:')) 'sectie via het cut-release-pad bevat geen Plugins-regel'
$fresh = Add-PluginChangelogSection -Existing '' -Section $section -PluginName 'specialists'
Assert-Match $fresh '^# Changelog .* specialists' 'nieuwe CHANGELOG krijgt intro-header'
Assert-Match $fresh '(?s)# Changelog.*## v1\.5\.0' 'sectie staat na de intro'
$section2 = Build-PluginChangelogSection -Entries @($entryMetPlugins) -Version '1.6.0' -Date '2026-07-18'
$appended = Add-PluginChangelogSection -Existing $fresh -Section $section2 -PluginName 'specialists'
Assert-Match $appended '(?s)## v1\.6\.0.*## v1\.5\.0' 'nieuwste release staat bovenaan'
Assert-Equal 1 (@([regex]::Matches($appended, '(?m)^# Changelog')).Count) 'intro-header niet gedupliceerd'

Write-Host "Build-PluginReleaseCard" -ForegroundColor Cyan
$cardEntries = @($linkEntry)
$card = Build-PluginReleaseCard -PluginName 'specialists' -Version '1.5.0' -Date '2026-07-19' -Type 'Minor' -Title 'Test-titel' -Entries $cardEntries -RepoBlobUrl 'https://gh.test/blob/main/'
Assert-Match $card '^# Release v1\.5\.0' 'kop met versie'
Assert-Match $card '\*\*Date:\*\* 2026-07-19' 'datumregel'
Assert-Match $card '\*\*Type:\*\* Minor' 'type-regel'
Assert-Match $card 'Test-titel' 'titel opgenomen'
Assert-Match $card 'You are on this release\.' 'you-are-on-this-release-regel'
Assert-Match $card '(?s)Test-titel.*You are on this release\.' 'titel staat voor de you-are-on-this-release-regel'
Assert-Match $card '(?m)^## v1\.5\.0 ' 'sectiekop uit Build-PluginChangelogSection (met entries)'
Assert-Match $card '### #3 .* Iets' 'entry-fragment opgenomen in de body'
Assert-Match $card '\[de lint\]\(https://gh\.test/blob/main/scripts/lint/x\.ps1\)' 'root-relatieve link in de body herschreven zoals Convert-EntryLinksForPluginChangelog doet'
Assert-Match $card '\[de site\]\(https://example\.com\)' 'externe link in de body blijft ongemoeid'
$card2 = Build-PluginReleaseCard -PluginName 'specialists' -Version '1.5.0' -Date '2026-07-19' -Type 'Minor' -Entries @() -RepoBlobUrl 'https://gh.test/blob/main/'
Assert-Match $card2 "No changes to this plugin in this release $([char]0x2014) see the full notes\." 'lege-entries-tak: exact het no-changes-blok'
Assert-Equal $false ([bool]($card2 -match '(?m)^## v')) 'lege-entries-tak: geen sectiekop'
Assert-Match $card2 '\*\*Type:\*\* Minor' 'lege-entries-tak: kop blijft wel intact'
Assert-Match $card '\[releases/development/1\.5/1\.5\.0\.md\]\(https://gh\.test/blob/main/releases/development/1\.5/1\.5\.0\.md\)' 'footer: blob-URL naar de volledige release-notes'
Assert-Match $card '\[CHANGELOG\.md\]\(CHANGELOG\.md\)' 'footer: map-relatieve link naar CHANGELOG.md'
Assert-Match $card2 '\[releases/development/1\.5/1\.5\.0\.md\]\(https://gh\.test/blob/main/releases/development/1\.5/1\.5\.0\.md\)' 'lege-entries-tak: footer-links blijven kloppen'

$cardNoTitle = Build-PluginReleaseCard -PluginName 'specialists' -Version '2.0.0' -Date '2026-07-19' -Type 'Major' -Entries @()
Assert-Match $cardNoTitle '(?s)\*\*Type:\*\* Major\n\nYou are on this release\.' 'zonder -Title precies een lege regel (geen extra) voor you-are-on-this-release'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAALT: $($script:fail) fout, $($script:pass) goed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: alle $($script:pass) asserts geslaagd." -ForegroundColor Green
exit 0
