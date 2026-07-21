<#
.SYNOPSIS
    Gedeelde helper voor de verbatim-gedeelde blokken in de agent-defs (build + lint).
.DESCRIPTION
    Sommige bullets onder **Grenzen** zijn woord-voor-woord identiek over veel agent-defs (bv. de
    inbound-regel: 19/19). Om ze op EEN plek te onderhouden i.p.v. in elke agent-def, staan ze als
    canonieke bron in claude-code-plugins/claude-specialists/agent-shared/<naam>.md en verschijnen ze
    in een agent-def tussen sentinel-commentaren:

        <!-- BEGIN shared:inbound-behaviour -- GENERATED, edit agent-shared/inbound-behaviour.md -->
        - **De gedeelde kern wijzig je niet lokaal.** ...(canonieke inhoud)...
        <!-- END shared:inbound-behaviour -->

    De inhoud staat echt in de agent-def (altijd-geladen, self-contained), maar wordt door
    build-agent-defs.ps1 uit de bron gevuld en door check-plugin-integrity.ps1 tegen de bron
    gecontroleerd. Hand-edit binnen de sentinels wordt zo als drift gevangen.

    Puur ASCII (repo-conventie voor .ps1). Deze lib wijzigt niets; hij levert alleen de expansie op.
#>

Set-StrictMode -Version Latest

function Get-AgentSharedDir {
    param([string]$RepoRoot)
    return (Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\agent-shared')
}

function Get-SharedBlockText {
    # Canonieke inhoud van een gedeeld blok (LF, zonder trailing newline), of $null als de bron mist.
    param([string]$SharedDir, [string]$Name)
    $p = Join-Path $SharedDir "$Name.md"
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return $null }
    $t = ([System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)) -replace "`r`n", "`n"
    return $t.TrimEnd("`n")
}

function Expand-AgentDefShared {
    # Vult elke <!-- BEGIN shared:NAME --> ... <!-- END shared:NAME -->-regio met de canonieke bron
    # en geeft de verwachte (ge-expandeerde) inhoud terug als string (LF). Een BEGIN zonder END of een
    # onbekend blok (ontbrekende bron) wordt als probleem gemeld en de regio blijft ongewijzigd.
    param(
        [string]$Content,
        [string]$SharedDir,
        [System.Collections.Generic.List[string]]$Problems
    )
    $lines = ($Content -replace "`r`n", "`n") -split "`n"
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        $m = [regex]::Match($line, '^\s*<!-- BEGIN shared:(?<name>[A-Za-z0-9-]+)\b')
        if (-not $m.Success) { $out.Add($line); $i++; continue }
        $name = $m.Groups['name'].Value
        $endPat = '^\s*<!-- END shared:' + [regex]::Escape($name) + '\s*-->'
        $j = $i + 1
        while ($j -lt $lines.Count -and $lines[$j] -notmatch $endPat) { $j++ }
        if ($j -ge $lines.Count) {
            if ($null -ne $Problems) { [void]$Problems.Add("BEGIN shared:$name zonder bijbehorende END-sentinel") }
            for ($k = $i; $k -lt $lines.Count; $k++) { $out.Add($lines[$k]) }
            return ($out -join "`n")
        }
        $block = Get-SharedBlockText -SharedDir $SharedDir -Name $name
        if ($null -eq $block) {
            if ($null -ne $Problems) { [void]$Problems.Add("onbekend shared-blok '$name' (bron agent-shared/$name.md ontbreekt)") }
            for ($k = $i; $k -le $j; $k++) { $out.Add($lines[$k]) }
            $i = $j + 1
            continue
        }
        $out.Add($lines[$i])                                  # BEGIN-sentinel ongewijzigd
        foreach ($bl in ($block -split "`n")) { $out.Add($bl) }
        $out.Add($lines[$j])                                  # END-sentinel ongewijzigd
        $i = $j + 1
    }
    return ($out -join "`n")
}
