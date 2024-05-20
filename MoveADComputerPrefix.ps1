<#
.SYNOPSIS
    Moves computer objects within Active Directory to appropriate organizational units (OUs) based on their name prefix.

.DESCRIPTION
    This script identifies computers in Active Directory that do not have an operating system like "*Server*"
    and moves them to designated organizational units (OUs) based on predefined name prefixes.
    The script requires credentials to perform operations on AD objects.

.PARAMETER Identity
    The identity of the computer object to be moved.

.PARAMETER Target
    The target path for the computer object (optional).

.PARAMETER Credential
    The credentials used to perform Active Directory operations.

.EXAMPLE
    .\MoveADComputerPrefix.ps1 -Identity 'SomeComputer' -Credential (Get-Credential)

.NOTES
    Author: Michael Steed
    Date: 2020-01-07
    Version: 1.0
    Last Updated: 2024-05-20

    This script is intended to manage computer objects within Active Directory by moving them to appropriate organizational units (OUs) based on their name prefix.
#>




function MoveADComputerPrefix {
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Identity,
        
        [Parameter(Mandatory=$false, Position=1)]
        [string] $Target,
        
        [Parameter(Mandatory=$true)]
        [pscredential] $Credential
    )

    $ouMapping = @{
        "ABCITY1" = "OU=City1,OU=Region1,OU=Country1,OU=Computers,OU=Company,DC=example,DC=com"
        "ABCITY2" = "OU=City2,OU=Region2,OU=Country2,OU=Computers,OU=Company,DC=example,DC=com"
    }

    try {
        $inScopeComputers = Get-ADComputer -Filter {
            OperatingSystem -notLike "*Server*" -and (
                Name -like "ABCITY1-*" -or
                Name -like "ABCITY2-*"
            )
        } -Server "dc.example.com" -Credential $Credential -SearchBase "CN=Computers,DC=example,DC=com","OU=Computers - Imaged,DC=example,DC=com"

        $inScopeComputers | ForEach-Object {
            $prefix = ($_.Name -split '-')[0]
            if ($ouMapping.ContainsKey($prefix)) {
                $ouPath = $ouMapping[$prefix]
                Write-Output "$($_.Name) computer moved to $ouPath"
                Move-ADObject -Identity $_.DistinguishedName -TargetPath $ouPath -Credential $Credential
            } else {
                Write-Output "$($_.Name) computer not moved"
                Move-ADObject -Identity $_.DistinguishedName -TargetPath "OU=City1,OU=Region1,OU=Country1,OU=Bitlocker - Computers,OU=Company,DC=example,DC=com" -Credential $Credential
            }
        }
    } catch {
        Write-Error "An error occurred: $_"
    }
}
