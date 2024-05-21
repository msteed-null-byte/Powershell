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

#>

function Get-ADUserInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Username,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$Server,

        [Switch]$Unlock,
        [Switch]$Disable,
        [Switch]$Enable
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

    $user = Get-ADUser -Server $Server -Identity $Username

    if ($user) {
        if ($Unlock -and $user.LockedOut) {
            $choice = Read-Host "User '$Username' is locked out. Do you want to unlock the account? (Y/N)"
            if ($choice -eq 'Y' -or $choice -eq 'y') {
                try {
                    Unlock-ADAccount -Identity $Username -Server $Server
                    Write-Output "User '$Username' has been unlocked."
                } catch {
                    Write-Output "Failed to unlock the user account: $_"
                }
            } else {
                Write-Output "User '$Username' remains locked."
            }
        } elseif ($Disable) {
            if (-not $user.Enabled) {
                Write-Output "User '$Username' is already disabled."
            } else {
                try {
                    Disable-ADAccount -Identity $Username -Server $Server
                    Write-Output "User '$Username' has been disabled."
                } catch {
                    Write-Output "Failed to disable the user account: $_"
                }
            }
        } elseif ($Enable) {
            if ($user.Enabled) {
                Write-Output "User '$Username' is already enabled."
            } else {
                try {
                    Enable-ADAccount -Identity $Username -Server $Server
                    Write-Output "User '$Username' has been enabled."
                } catch {
                    Write-Output "Failed to enable the user account: $_"
                }
            }
        } else {
            Get-ADUser -Server $Server -Identity $Username -Properties * |
                Select-Object -Property $properties
        }
    } else {
        Write-Output "User '$Username' not found."
    }
}

Export-ModuleMember -Function 'Get-ADUserInfo'
