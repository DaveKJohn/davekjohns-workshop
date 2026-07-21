<#
.SYNOPSIS
    Gedeelde branch-conventies voor de workflow-scripts (single source of truth).

.DESCRIPTION
    Dot-source dit bestand vanuit een script in scripts/release/:

        . (Join-Path $PSScriptRoot '..\lib\branch-info.ps1')

    Levert Get-BranchPrefix, Get-BranchInfo en Get-BranchTypes. De prefix-tabel bepaalt zowel het
    GitHub-label van de PR als het changelog-entry-type, en volgt de standaard GitHub-labels:
    Enhancement -> label 'enhancement', Bug -> 'bug', Documentation -> 'documentation'.
    Wijzigt de tabel? Dan hier ook - en nergens anders: alle scripts lezen deze ene tabel.

    De branch-typen (Feat/Fix/Docs/Chore) zijn hier de enige bron. release-lib.ps1 leest ze via
    Get-BranchTypes voor de release-notes-groepering, zodat de lijst niet op twee plekken drift
    (voorheen dupliceerde release-lib.ps1 diezelfde typen als $catOrder).

    Geen Set-StrictMode hier: dot-sourcen zou de strict-mode van het aanroepende script
    veranderen en daar losse code kunnen breken.
#>

# De canonieke branch-typen, in de volgorde waarin ze in de release-notes verschijnen. Enige bron:
# elke Type-waarde in de tabel hieronder is lid van deze lijst, en release-lib.ps1 leest hem via
# Get-BranchTypes. Voeg je een type toe, dan hier -- en nergens anders.
$script:BranchTypeOrder = @('Feat', 'Fix', 'Docs', 'Chore')

# prefix -> GitHub-label (PR) + branch-type (changelog-entry).
# Let op: een release loopt NIET via een branch/PR (cut-release.ps1 commit rechtstreeks op main),
# dus er is bewust geen 'release'-prefix hier.
$script:BranchPrefixTable = @{
    feat  = @{ Label = 'enhancement';   Type = 'Feat' }
    fix   = @{ Label = 'bug';           Type = 'Fix' }
    docs  = @{ Label = 'documentation'; Type = 'Docs' }
    chore = @{ Label = 'documentation'; Type = 'Chore' }
}

function Get-BranchTypes {
    # De canonieke branch-typen in release-notes-volgorde (SSOT voor release-lib.ps1).
    return $script:BranchTypeOrder
}

function Get-BranchPrefix {
    param([Parameter(Mandatory = $true)][string]$Branch)
    # 'feat/naam' -> 'feat'; zonder slash geldt het stuk voor het eerste koppelteken
    if ($Branch -match '/') { return ($Branch -split '/')[0] }
    return ($Branch -split '-')[0]
}

function Get-BranchInfo {
    param([Parameter(Mandatory = $true)][string]$Branch)
    $prefix = Get-BranchPrefix -Branch $Branch
    $known  = $script:BranchPrefixTable.ContainsKey($prefix)
    [pscustomobject]@{
        Branch   = $Branch
        Prefix   = $prefix
        IsKnown  = $known
        Label    = $(if ($known) { $script:BranchPrefixTable[$prefix].Label } else { $null })
        Type     = $(if ($known) { $script:BranchPrefixTable[$prefix].Type } else { $null })
        # Dezelfde naam wordt gebruikt voor het changelog-entry-bestand <SafeName>.md in de repo-root.
        SafeName = $Branch -replace '/', '-'
    }
}

function Test-BranchName {
    <#
        Additieve SSOT-helper (naast Get-BranchInfo) voor scripts die een branch-naam moeten
        VALIDEREN voor ze hem gebruiken (bv. new-branch.ps1), i.p.v. de hard-reject-regels inline
        te herhalen. Raakt Get-BranchInfo/Get-BranchTypes/de prefix-tabel niet aan.

        Hard-rejects (IsValid = $false, Reason gevuld):
          - lege/whitespace-only naam
          - naam gelijk aan 'main'
          - naam bevat de substring 'final' (case-insensitief, dus ook 'finalize'/'refinalization' --
            Derek's harde regel, bewust breed)

        Onbekend prefix is GEEN hard-reject (IsValid blijft $true); de aanroeper leest IsKnown en
        beslist zelf of/hoe een soft-warn nodig is, consistent met new-changelog-entry/open-pr die
        bij een onbekend prefix ook terugvallen (Chore/'question') i.p.v. te blokkeren.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Branch)

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        return [pscustomobject]@{ IsValid = $false; Reason = "Branch-naam mag niet leeg zijn."; IsKnown = $false }
    }
    if ($Branch -eq 'main') {
        return [pscustomobject]@{ IsValid = $false; Reason = "Branch-naam mag niet 'main' zijn."; IsKnown = $false }
    }
    if ($Branch -match 'final') {
        return [pscustomobject]@{ IsValid = $false; Reason = "Branch-naam mag het token 'final' niet bevatten."; IsKnown = $false }
    }

    $info = Get-BranchInfo -Branch $Branch
    [pscustomobject]@{ IsValid = $true; Reason = $null; IsKnown = $info.IsKnown }
}
