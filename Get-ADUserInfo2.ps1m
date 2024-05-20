<#
.SYNOPSIS
    Retrieves and manages Active Directory user information.

.DESCRIPTION
    This function retrieves information about an Active Directory user specified by username from a given server.
    It can also perform actions such as unlocking, disabling, or enabling the user account based on specified switches.

.PARAMETER Username
    The username of the Active Directory user to retrieve information for.

.PARAMETER Server
    The server where Active Directory queries will be executed.

.PARAMETER Unlock
    Specifies whether to unlock the user account if it is locked out.

.PARAMETER Disable
    Specifies whether to disable the user account.

.PARAMETER Enable
    Specifies whether to enable the user account.

.NOTES
    Author: Michael Steed
    Date: 2020-01-07
    Version: 1.0
    Last Updated: 2024-05-20

    This function provides a convenient way to retrieve and manage Active Directory user information.

.EXAMPLE
    Get-ADUserInfo -Username "john.doe" -Server "example.com" -Unlock

    Unlocks the user account for "john.doe" on the "example.com" server.

.EXAMPLE
    Get-ADUserInfo -Username "jane.smith" -Server "example.com" -Disable

    Disables the user account for "jane.smith" on the "example.com" server.

.LINK
    https://example.com/documentation
#>

function Get-ADUserInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Username,

        [Switch]$Unlock,
        [Switch]$Disable,
        [Switch]$Enable,

        [String]$AdServer,
    )

    $properties = @(
        'Name',
        'SamAccountName',
        'PasswordExpired',
        'PasswordLastSet',
        'LockedOut',
        'Description',
        @{Name = 'OU'; Expression = {$_.DistinguishedName -replace '^.+?(?<!\\),',''}}
    )

    if ($Unlock) {
        $user = Get-ADUser -Server $AdServer $Username
        if ($user) {
            if ($user.LockedOut) {
                $user | Unlock-ADAccount
                Write-Output "User '$Username' has been unlocked."
            } else {
                Write-Output "User '$Username' is already unlocked."
            }
        } else {
            Write-Output "User '$Username' not found."
        }
    } elseif ($Disable) {
        $user = Get-ADUser -Server $AdServer $Username
        if ($user) {
            if (-not $user.Enabled) {
                Write-Output "User '$Username' is already disabled."
            } else {
                $user | Disable-ADAccount
                Write-Output "User '$Username' has been disabled."
            }
        } else {
            Write-Output "User '$Username' not found."
        }
    } elseif ($Enable) {
        $user = Get-ADUser -Server $AdServer $Username
        if ($user) {
            if ($user.Enabled) {
                Write-Output "User '$Username' is already enabled."
            } else {
                $user | Enable-ADAccount
                Write-Output "User '$Username' has been enabled."
            }
        } else {
            Write-Output "User '$Username' not found."
        }
    } else {
        Get-ADUser -Server $AdServer $Username -Properties * |
            Select-Object -Property $properties
    }
}

Export-ModuleMember -Function 'Get-ADUserInformation'
