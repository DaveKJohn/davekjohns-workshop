<#
.SYNOPSIS
    Integrity check for the davekjohns-workshop marketplace: validates the manifests, the
    agent-def frontmatter and the internal links before a change lands via a PR on main.
.DESCRIPTION
    This repo's lint gate (invoked by scripts/release/open-pr.ps1). Read-only -- changes nothing.
    Checks the following; every finding is an error:

      1. .claude-plugin/marketplace.json: valid JSON; every plugins[].source points to an
         existing folder with a .claude-plugin/plugin.json.
      2. every <plugin>/.claude-plugin/plugin.json: valid JSON with a non-empty 'name'.
      3. every <plugin>/agents/*.md: frontmatter contains 'name:', 'id:' and 'group:'.
      3b. every <plugin>/manuals/*-manual.md: frontmatter contains 'id:' and 'group:', and the
         file name <group>-<id>-manual.md matches that frontmatter (the portable manual that the
         corresponding agent def reads in via ${CLAUDE_PLUGIN_ROOT}/manuals/).
      3c. every <plugin>/personas/*-persona.md: frontmatter contains 'id:' and 'group:', and the
         file name <group>-<id>-persona.md matches that frontmatter. Personas (orchestrator +
         main-loop specialists) DELIBERATELY have no agent def -- they run in the main loop, not
         as a subagent -- and are therefore left alone by check 6's agent-def<->manual link.
      4. dead relative links AND broken anchors in README.md, CHANGELOG.md, CLAUDE.md, every
         .claude/extensions/*.md, every <plugin>/skills/*/SKILL.md, every <plugin>/manuals/*-manual.md,
         every <plugin>/personas/*-persona.md, every releases/**/*.md, every <plugin>/RELEASE.md,
         claude-code-plugins/claude-specialists/README.md (the family README) and QUICKSTART.md, and
         every plugin's own claude-code-plugins/claude-specialists/<plugin>/CHANGELOG.md (#103).
         Checked: (a) the linked
         file exists, and (b) if the link
         has a #anchor, that anchor exists as a heading in the target file (GitHub slug rules).
         External http(s)/mailto links are skipped.
      5. every scripts/**/*.ps1 parses without error (catches syntax errors in the orchestration
         itself, which would otherwise only break at execution time).
      6. specialists-system integrity: per plugin, every '<group>-<id>' is unique across the
         agent defs, every agent def has a valid 'name:' + a corresponding manuals/<g>-<id>-manual.md
         which it also names, and conversely every manual has an agent def (no orphan manual).
      7. shared agent-def blocks: every <!-- BEGIN/END shared:NAME --> region in an agent def still
         equals its canonical source in agent-shared/<name>.md (see scripts/agents/build-agent-defs.ps1)
         -- a hand-edit inside the sentinels or a forgotten rebuild is thus caught at the gate.
      8. shared workflow scripts: every plugin mirror of a repo-agnostic script (issue #81) is
         still LF-identical to its root source -- a hand-edit in the mirror or a forgotten
         scripts/sync/build-shared-scripts.ps1 is thus caught at the gate.
      9. RELEASE.md per plugin (Model A, plugin-carried): every plugin folder has a RELEASE.md, and
         the 'vX.Y.Z' it contains equals the 'version' in that plugin's plugin.json. Only
         cut-release.ps1 changes both files together, so an ordinary feature PR can never trip this
         -- a mismatch/missing file means the card was not (re)generated.

    Exit code: 0 = no errors. 1 = at least one error (usable as a gate in open-pr.ps1).
.EXAMPLE
    ./scripts/lint/check-plugin-integrity.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$errors = New-Object System.Collections.Generic.List[string]

function Add-Error([string]$Msg) { $script:errors.Add($Msg) }

function Test-JsonFile {
    param([string]$Path)
    try {
        $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        return ($raw | ConvertFrom-Json)
    } catch {
        Add-Error "[JSON] $($Path.Replace($RepoRoot, '.')) is not valid JSON: $($_.Exception.Message)"
        return $null
    }
}

Write-Host "== check-plugin-integrity -- $RepoRoot ==" -ForegroundColor Cyan

# --- 1. marketplace.json + the plugins it references ------------------------------------------------
$marketplacePath = Join-Path $RepoRoot '.claude-plugin\marketplace.json'
if (-not (Test-Path -LiteralPath $marketplacePath)) {
    Add-Error "[marketplace] .claude-plugin/marketplace.json is missing."
} else {
    $mp = Test-JsonFile -Path $marketplacePath
    if ($mp) {
        if (-not ($mp.PSObject.Properties.Name -contains 'plugins') -or -not $mp.plugins) {
            Add-Error "[marketplace] marketplace.json has no 'plugins' list."
        } else {
            # Containment (Sean's advice): a source that points outside the repo via an absolute
            # or ..-path is always wrong -- what is registered here gets published.
            # Deliberately mirrored on Get-PluginManifestPaths in scripts/lib/release-lib.ps1 (which
            # throws; this lint collects) -- if you change the containment rule, change both.
            $rootPrefix = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') + '\'
            foreach ($p in $mp.plugins) {
                $src = $p.source
                if (-not $src) { Add-Error "[marketplace] plugin '$($p.name)' is missing a 'source'."; continue }
                $pluginDir = (Join-Path $RepoRoot ($src -replace '/', '\')).TrimEnd('\')
                $resolvedDir = $null
                try { $resolvedDir = [System.IO.Path]::GetFullPath($pluginDir) } catch {}
                if (-not $resolvedDir -or -not ($resolvedDir + '\').StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    Add-Error "[marketplace] plugin '$($p.name)': source '$src' points outside the repo."
                } elseif (-not (Test-Path -LiteralPath $pluginDir -PathType Container)) {
                    Add-Error "[marketplace] plugin '$($p.name)': source folder '$src' does not exist."
                } elseif (-not (Test-Path -LiteralPath (Join-Path $pluginDir '.claude-plugin\plugin.json'))) {
                    Add-Error "[marketplace] plugin '$($p.name)': '$src' contains no .claude-plugin/plugin.json."
                }
            }
        }
    }
}

# --- 2. every plugin.json: valid JSON with a name ----------------------------------------------------
Get-ChildItem -Path $RepoRoot -Recurse -Filter 'plugin.json' -File |
    Where-Object { $_.FullName -match '\.claude-plugin\\plugin\.json$' } | ForEach-Object {
        $pj = Test-JsonFile -Path $_.FullName
        if ($pj -and (-not ($pj.PSObject.Properties.Name -contains 'name') -or -not $pj.name)) {
            Add-Error "[plugin] $($_.FullName.Replace($RepoRoot, '.')) is missing a non-empty 'name'."
        }
    }

# --- 3. agent-def frontmatter: name/id/group ---------------------------------------------------------
Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-agent.md' -File |
    Where-Object { $_.FullName -match '\\agents\\' } | ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        foreach ($key in 'name', 'id', 'group') {
            if (-not [regex]::IsMatch($text, "(?m)^$key`:\s*\S")) {
                Add-Error "[agent-def] $rel is missing '$key`:' in the frontmatter."
            }
        }
    }

# --- 3b. manual frontmatter: id/group + file name <group>-<id>-manual.md -----------------------------
Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-manual.md' -File |
    Where-Object { $_.FullName -match '\\manuals\\' } | ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        foreach ($key in 'id', 'group') {
            if (-not [regex]::IsMatch($text, "(?m)^$key`:\s*\S")) {
                Add-Error "[manual] $rel is missing '$key`:' in the frontmatter."
            }
        }
        if ($_.BaseName -match '^(\d{2})-(\d{2})-manual$') {
            $fnG = $Matches[1]; $fnI = $Matches[2]
            $mI = [regex]::Match($text, '(?m)^id:\s*(\S+)\s*$')
            $mG = [regex]::Match($text, '(?m)^group:\s*(\S+)\s*$')
            if ($mI.Success -and $mI.Groups[1].Value.Trim() -ne $fnI) {
                Add-Error "[manual] $rel`: file-name id '$fnI' != frontmatter 'id: $($mI.Groups[1].Value.Trim())'."
            }
            if ($mG.Success -and $mG.Groups[1].Value.Trim() -ne $fnG) {
                Add-Error "[manual] $rel`: file-name group '$fnG' != frontmatter 'group: $($mG.Groups[1].Value.Trim())'."
            }
        } else {
            Add-Error "[manual] $rel`: file name does not follow the <group>-<id>-manual pattern."
        }
    }

# --- 3c. persona frontmatter: id/group + file name <group>-<id>-persona.md ----------------------------
# Personas (Chris/Derek/Rendall etc.) run in the MAIN LOOP, not as a subagent, so they deliberately
# have no agent def. They live in <plugin>/personas/ as a portable template that the bootstrap
# skill copies to a consumer's repo layer (.claude/extensions/<g>-<id>-extension.md). Check 6
# (agent-def<->manual link) therefore ignores them; here we validate their frontmatter + file name
# on their own (mirrors 3b).
Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-persona.md' -File |
    Where-Object { $_.FullName -match '\\personas\\' } | ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        foreach ($key in 'id', 'group') {
            if (-not [regex]::IsMatch($text, "(?m)^$key`:\s*\S")) {
                Add-Error "[persona] $rel is missing '$key`:' in the frontmatter."
            }
        }
        if ($_.BaseName -match '^(\d{2})-(\d{2})-persona$') {
            $fnG = $Matches[1]; $fnI = $Matches[2]
            $mI = [regex]::Match($text, '(?m)^id:\s*(\S+)\s*$')
            $mG = [regex]::Match($text, '(?m)^group:\s*(\S+)\s*$')
            if ($mI.Success -and $mI.Groups[1].Value.Trim() -ne $fnI) {
                Add-Error "[persona] $rel`: file-name id '$fnI' != frontmatter 'id: $($mI.Groups[1].Value.Trim())'."
            }
            if ($mG.Success -and $mG.Groups[1].Value.Trim() -ne $fnG) {
                Add-Error "[persona] $rel`: file-name group '$fnG' != frontmatter 'group: $($mG.Groups[1].Value.Trim())'."
            }
        } else {
            Add-Error "[persona] $rel`: file name does not follow the <group>-<id>-persona pattern."
        }
    }

# --- 4. dead relative links + broken anchors ---------------------------------------------------------
# Scanned files: README.md, CHANGELOG.md, CLAUDE.md, every .claude/extensions/*.md, every
# <plugin>/skills/*/SKILL.md, every <plugin>/manuals/*-manual.md and every releases/**/*.md. For
# every relative link it is checked (a) that the linked file exists, and (b) if the link has a
# #anchor: that anchor exists as a heading in the target file (GitHub slug rules). External
# http(s)/mailto links are skipped.

function ConvertTo-GhSlug {
    # Converts a heading text to a GitHub anchor slug.
    param([string]$Text)
    $t = [regex]::Replace($Text, '\[([^\]]*)\]\([^)]*\)', '$1')  # [text](url) -> text
    $t = $t -replace '[`*_]', ''                                  # strip inline code/emphasis markers
    $t = $t.ToLowerInvariant()
    $t = [regex]::Replace($t, '[^\p{L}\p{N} \-]', '')             # only letter/digit/space/hyphen
    $t = $t.Trim() -replace ' ', '-'
    return $t
}

function Get-HeadingSlugs {
    # Collects the anchor slugs of all headings in a markdown file (with GitHub duplicate suffixes).
    param([string]$Path)
    $slugs = New-Object System.Collections.Generic.HashSet[string]
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $slugs }
    $lines = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) -split "`r?`n"
    $counts = @{}
    $inFence = $false
    foreach ($line in $lines) {
        if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        if ($line -match '^#{1,6}\s+(.*)$') {
            $base = ConvertTo-GhSlug -Text $Matches[1]
            if (-not $base) { continue }
            if (-not $counts.ContainsKey($base)) { $counts[$base] = 0; $slug = $base }
            else { $counts[$base] = $counts[$base] + 1; $slug = "$base-$($counts[$base])" }
            [void]$slugs.Add($slug)
        }
    }
    return $slugs
}

$linkFiles = @()
foreach ($root in 'README.md', 'CHANGELOG.md', 'CLAUDE.md') {
    $p = Join-Path $RepoRoot $root
    if (Test-Path -LiteralPath $p) { $linkFiles += $p }
}
# The specialists handbook lives next to the lenses (at family level) -- validate its links too.
$handbook = Join-Path $RepoRoot '.claude\plugins\claude-specialists\README.md'
if (Test-Path -LiteralPath $handbook) { $linkFiles += $handbook }
# The family README + QUICKSTART.md of the specialists family (claude-code-plugins/claude-specialists/)
# and every plugin's own CHANGELOG.md (the consumer-facing card that cut-release.ps1 updates)
# did not yet belong to the scan set -- added (#103).
foreach ($familyDoc in 'README.md', 'QUICKSTART.md') {
    $p = Join-Path $RepoRoot "claude-code-plugins\claude-specialists\$familyDoc"
    if (Test-Path -LiteralPath $p) { $linkFiles += $p }
}
$linkFiles += (Get-ChildItem -Path (Join-Path $RepoRoot 'claude-code-plugins\claude-specialists') -Recurse -Filter 'CHANGELOG.md' -File |
    Where-Object { $_.FullName -notmatch '\\connectors\\' } |
    Select-Object -ExpandProperty FullName)
# The repo lenses live on the plugin path (.claude/plugins/claude-specialists/specialists/, the
# standard) or on the legacy path (.claude/extensions/) -- scan both, wherever they are.
foreach ($extDir in @(
    (Join-Path $RepoRoot '.claude\plugins\claude-specialists\specialists'),
    (Join-Path $RepoRoot '.claude\extensions'))) {
    if (Test-Path -LiteralPath $extDir) {
        $linkFiles += (Get-ChildItem -Path $extDir -Filter '*.md' -File | Select-Object -ExpandProperty FullName)
    }
}
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter 'SKILL.md' -File |
    Where-Object { $_.FullName -match '\\skills\\' } | Select-Object -ExpandProperty FullName)
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-manual.md' -File |
    Where-Object { $_.FullName -match '\\manuals\\' } | Select-Object -ExpandProperty FullName)
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-persona.md' -File |
    Where-Object { $_.FullName -match '\\personas\\' } | Select-Object -ExpandProperty FullName)
$releasesDir = Join-Path $RepoRoot 'releases'
if (Test-Path -LiteralPath $releasesDir) {
    $linkFiles += (Get-ChildItem -Path $releasesDir -Recurse -Filter '*.md' -File | Select-Object -ExpandProperty FullName)
}
# Every plugin-carried RELEASE.md card (check 9) links to the full notes and its own
# CHANGELOG.md -- those links need to be validated too.
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter 'RELEASE.md' -File |
    Select-Object -ExpandProperty FullName)

$linkRegex = [regex]'\[(?:[^\]]*)\]\(([^)]+)\)'
$slugCache = @{}
foreach ($lf in $linkFiles) {
    $content = [System.IO.File]::ReadAllText($lf, [System.Text.Encoding]::UTF8)
    # Exclude code: fenced (```...```) and inline (`...`). Link-like text inside code is
    # illustration, not a real link -- otherwise e.g. a `[..](#anchor)` example would get validated.
    $scan = [regex]::Replace($content, '(?s)```.*?```', '')
    $scan = [regex]::Replace($scan, '`[^`]*`', '')
    # Persona templates are destined for .claude/extensions/ of a consuming repo; their relative
    # links need to resolve THERE, not at the source location in the plugin. So validate them as if
    # the file were already at that destination (this repo mirrors the consumer layout).
    if ($lf -match '\\personas\\.*-persona\.md$') {
        $dir = Join-Path $RepoRoot '.claude\extensions'
    } else {
        $dir = Split-Path -Parent $lf
    }
    $rel = $lf.Replace($RepoRoot, '.')
    foreach ($m in $linkRegex.Matches($scan)) {
        $target = $m.Groups[1].Value.Trim()
        if ($target -match '^(https?:|mailto:)') { continue }

        $parts = $target -split '#', 2
        $pathPart = $parts[0]
        $anchor = if ($parts.Count -gt 1) { $parts[1] } else { $null }

        # Determine target file: empty pathPart = this same file (pure #anchor).
        if (-not $pathPart) {
            $targetFile = $lf
        } else {
            $resolved = Join-Path $dir ($pathPart -replace '/', '\')
            if (-not (Test-Path -LiteralPath $resolved)) {
                Add-Error "[link] $rel -> dead link '$target' (expected file does not exist)."
                continue
            }
            $targetFile = $resolved
        }

        # Anchor validation: only meaningful for an existing .md target file.
        if ($anchor -and $targetFile -match '\.md$' -and (Test-Path -LiteralPath $targetFile -PathType Leaf)) {
            $full = (Resolve-Path -LiteralPath $targetFile).Path
            if (-not $slugCache.ContainsKey($full)) { $slugCache[$full] = Get-HeadingSlugs -Path $full }
            if (-not $slugCache[$full].Contains($anchor)) {
                Add-Error "[anchor] $rel -> '$target' (anchor '#$anchor' does not exist as a heading in the target file)."
            }
        }
    }
}

# --- 5. PowerShell scripts must parse -----------------------------------------------------------------
# Catches syntax errors before they land on main. The pure logic of a script can be tested
# separately, but a parse error in the orchestration itself would only break at execution time --
# this check pulls that forward, to the PR gate. Scanned: scripts/**/*.ps1 AND the scripts a plugin
# carries -- <plugin>/skills/**/*.ps1 (e.g. specialists-init's bootstrap) and
# <plugin>/scripts/**/*.ps1 (the shared SSOT home, issue #81). Made unique so a path that hits both
# filters is not parsed twice.
$psScripts = @()
$psScripts += (Get-ChildItem -Path (Join-Path $RepoRoot 'scripts') -Recurse -Filter '*.ps1' -File)
$psScripts += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*.ps1' -File |
    Where-Object { $_.FullName -match '\\skills\\' -or $_.FullName -match '\\claude-code-plugins\\.+\\scripts\\' })
$psScripts = @($psScripts | Sort-Object -Property FullName -Unique)
$psScripts | ForEach-Object {
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$parseErrors) | Out-Null
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        $rel = $_.FullName.Replace($RepoRoot, '.')
        Add-Error "[parse] $rel`: $($parseErrors[0].Message)"
    }
}

# --- 6. specialists-system integrity -------------------------------------------------------------------
# This repo is the source of the specialists system, so the agent-def<->manual link must be at
# least as strict here as for a consumer. Per plugin (folder with agents/ and manuals/):
#   6a. every '<group>-<id>' is unique across all agent defs; every agent def has a valid 'name:'
#       (Claude Code call name), a corresponding manuals/<g>-<id>-manual.md in the same plugin, and
#       names that manual in its text.
#   6b. no orphan manual: every manuals/<g>-<id>-manual.md has an agents/<g>-<id>-agent.md.
# (The roster->lens link is already covered by the dead-link scan above, since that scans CLAUDE.md.)

$idOwner = @{}
Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-agent.md' -File |
    Where-Object { $_.FullName -match '\\agents\\' } | ForEach-Object {
        $rel = $_.FullName.Replace($RepoRoot, '.')
        if ($_.BaseName -notmatch '^(\d{2})-(\d{2})-agent$') {
            Add-Error "[specialist] $rel does not follow the <group>-<id>-agent.md pattern."
            return
        }
        $g = $Matches[1]; $id = $Matches[2]; $key = "$g-$id"
        if ($idOwner.ContainsKey($key)) {
            Add-Error "[specialist] ${rel}: duplicate id '$key' (already claimed by $($idOwner[$key]))."
        } else {
            $idOwner[$key] = $rel
        }

        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $nm = [regex]::Match($text, '(?m)^name:\s*(\S+)\s*$')
        if ($nm.Success -and ($nm.Groups[1].Value.Trim() -notmatch '^[a-z0-9-]+$')) {
            Add-Error "[specialist] ${rel}: 'name: $($nm.Groups[1].Value.Trim())' must consist of lowercase letters/digits/hyphens (Claude Code call name)."
        }

        $pluginRoot = Split-Path (Split-Path $_.FullName -Parent) -Parent
        $manualBase = "$g-$id-manual"
        $manualPath = Join-Path $pluginRoot ("manuals\$manualBase.md")
        if (-not (Test-Path -LiteralPath $manualPath -PathType Leaf)) {
            Add-Error "[specialist] ${rel}: corresponding manual 'manuals/$manualBase.md' is missing in the same plugin."
        } elseif ($text -notmatch [regex]::Escape("manuals/$manualBase.md")) {
            Add-Error "[specialist] ${rel}: agent def does not name its manual 'manuals/$manualBase.md'."
        }
    }

Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-manual.md' -File |
    Where-Object { $_.FullName -match '\\manuals\\' } | ForEach-Object {
        if ($_.BaseName -match '^(\d{2})-(\d{2})-manual$') {
            $g = $Matches[1]; $id = $Matches[2]
            $pluginRoot = Split-Path (Split-Path $_.FullName -Parent) -Parent
            $agentPath = Join-Path $pluginRoot ("agents\$g-$id-agent.md")
            if (-not (Test-Path -LiteralPath $agentPath -PathType Leaf)) {
                $rel = $_.FullName.Replace($RepoRoot, '.')
                Add-Error "[specialist] ${rel}: orphan manual -- no corresponding agents/$g-$id-agent.md in the same plugin."
            }
        }
    }

# --- 7. shared agent-def blocks in sync with their source ---------------------------------------------
# Verbatim-shared bullets (e.g. the inbound rule, 19/19) are maintained in ONE place in
# agent-shared/<name>.md and filled into the agent defs between <!-- BEGIN/END shared:NAME -->
# sentinels (built via scripts/agents/build-agent-defs.ps1). Here we guard that every marked
# region still equals its source -- this catches a hand-edit inside the sentinels or a forgotten
# rebuild.
. (Join-Path $PSScriptRoot '..\lib\agent-shared-lib.ps1')
$agentSharedDir = Get-AgentSharedDir -RepoRoot $RepoRoot
Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-agent.md' -File |
    Where-Object { $_.FullName -match '\\agents\\' } | ForEach-Object {
        $raw = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        $sharedProblems = New-Object System.Collections.Generic.List[string]
        $expanded = Expand-AgentDefShared -Content $raw -SharedDir $agentSharedDir -Problems $sharedProblems
        foreach ($p in $sharedProblems) { Add-Error "[shared] ${rel}: $p" }
        if ($expanded -ne ($raw -replace "`r`n", "`n")) {
            Add-Error "[shared] ${rel}: shared block deviates from the source -- run scripts/agents/build-agent-defs.ps1."
        }
    }

# --- 8. shared workflow scripts in sync with their source ----------------------------------------------
# Repo-agnostic scripts are shared with consumers as a plugin mirror (issue #81): the root copy is
# the tested source, the plugin mirror is what a consumer runs. Here we guard that every mirror is
# still LF-identical to its source -- this catches a hand-edit in the mirror or a forgotten rebuild
# (scripts/sync/build-shared-scripts.ps1) before it lands on main via a PR.
. (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')
foreach ($pair in @(Get-SharedScriptPairs -RepoRoot $RepoRoot)) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    if ($null -eq $src) {
        Add-Error "[shared-script] source is missing: $($pair.SourceRel)."
        continue
    }
    $mirror = Get-NormalizedScriptContent -Path $pair.MirrorPath
    if ($null -eq $mirror) {
        Add-Error "[shared-script] mirror is missing: $($pair.MirrorRel) -- run scripts/sync/build-shared-scripts.ps1."
    } elseif ($src -ne $mirror) {
        Add-Error "[shared-script] $($pair.MirrorRel) deviates from $($pair.SourceRel) -- run scripts/sync/build-shared-scripts.ps1."
    }
}

# --- 9. RELEASE.md present per plugin + version match --------------------------------------------------
# Model A (plugin-carried, see CHANGELOG/#115-like inbound issue): cut-release.ps1 writes this
# card on EVERY release for EVERY plugin (lockstep version), even a plugin not touched this time.
# Because RELEASE.md and plugin.json only change together -- via cut-release.ps1 -- an ordinary
# feature PR can never trip this; only a forgotten regeneration or hand-edit gets caught.
Get-ChildItem -Path $RepoRoot -Recurse -Filter 'plugin.json' -File |
    Where-Object { $_.FullName -match '\.claude-plugin\\plugin\.json$' } | ForEach-Object {
        $pluginDir = Split-Path (Split-Path $_.FullName -Parent) -Parent
        $pluginName = Split-Path $pluginDir -Leaf
        $pj = Test-JsonFile -Path $_.FullName
        if (-not $pj) { return }
        if (-not ($pj.PSObject.Properties.Name -contains 'version') -or -not $pj.version) {
            Add-Error "[release-card] $pluginName/.claude-plugin/plugin.json is missing a non-empty 'version' -- required for the lockstep RELEASE.md card."
            return
        }
        $pjVersion = $pj.version
        $releasePath = Join-Path $pluginDir 'RELEASE.md'
        if (-not (Test-Path -LiteralPath $releasePath -PathType Leaf)) {
            Add-Error "[release-card] $pluginName is missing RELEASE.md -- run scripts/release/cut-release.ps1 (that regenerates the card for every plugin)."
            return
        }
        $releaseText = [System.IO.File]::ReadAllText($releasePath, [System.Text.Encoding]::UTF8)
        $vm = [regex]::Match($releaseText, '(?m)^#\s+Release\s+v(\d+\.\d+\.\d+)\s*$')
        if (-not $vm.Success) {
            Add-Error "[release-card] $pluginName/RELEASE.md: no '# Release vX.Y.Z' heading found -- regenerate via cut-release.ps1."
        } elseif ($vm.Groups[1].Value -ne $pjVersion) {
            Add-Error "[release-card] $pluginName/RELEASE.md carries v$($vm.Groups[1].Value), but plugin.json says v$pjVersion -- run cut-release.ps1 again."
        }
    }

# --- Report ---------------------------------------------------------------------------------------------
if ($errors.Count -eq 0) {
    Write-Host "  No findings." -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary: 0 error(s)." -ForegroundColor Cyan
    exit 0
}
foreach ($e in $errors) { Write-Host "  $e" -ForegroundColor Red }
Write-Host ""
Write-Host "Summary: $($errors.Count) error(s)." -ForegroundColor Cyan
exit 1
