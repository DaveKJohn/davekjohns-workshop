<#
.SYNOPSIS
    Gedeelde branch-conventies voor de workflow-scripts (single source of truth).

.DESCRIPTION
    Dot-source dit bestand vanuit een script in scripts/release/:

        . (Join-Path $PSScriptRoot '..\lib\branch-info.ps1')

    Levert Get-BranchPrefix en Get-BranchInfo. De prefix-tabel bepaalt zowel het GitHub-label van de
    PR als het changelog-entry-type, en volgt de standaard GitHub-labels:
    Enhancement -> label 'enhancement', Bug -> 'bug', Documentation -> 'documentation'.
    Wijzigt de tabel? Dan hier ook - en nergens anders: alle scripts lezen deze ene tabel.

    Geen Set-StrictMode hier: dot-sourcen zou de strict-mode van het aanroepende script
    veranderen en daar losse code kunnen breken.
#>

# prefix -> GitHub-label (PR) + branch-type (changelog-entry).
# Let op: een release loopt NIET via een branch/PR (cut-release.ps1 commit rechtstreeks op main),
# dus er is bewust geen 'release'-prefix hier.
$script:BranchPrefixTable = @{
    feat  = @{ Label = 'enhancement';   Type = 'Feat' }
    fix   = @{ Label = 'bug';           Type = 'Fix' }
    docs  = @{ Label = 'documentation'; Type = 'Docs' }
    chore = @{ Label = 'documentation'; Type = 'Chore' }
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
