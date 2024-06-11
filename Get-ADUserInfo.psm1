<#
.SYNOPSIS
    This script retrieves information about Active Directory users and performs certain actions such as unlocking accounts, enabling/disabling accounts, and displaying group memberships.

.DESCRIPTION
    The Get-ADUserInfo function retrieves information about Active Directory users based on the provided username or employee ID. It also includes options to unlock accounts, enable/disable accounts, and display group memberships.

    .PARAMETER Username
    Specifies the username of the Active Directory user to retrieve information for.

.PARAMETER Server
    Specifies the Active Directory server to connect to. Default is '{SERVERNAME}'. Please make sure you update to your default AD Domain Controller Server name.

.PARAMETER ByID
    Indicates that the provided username is an employee ID rather than a username.

.PARAMETER Unlock
    Unlocks the user account if it is currently locked.

.PARAMETER Disable
    Disables the user account.

.PARAMETER Enable
    Enables the user account.

.PARAMETER Groups
    Displays the group memberships of the user.

.EXAMPLE
    Get-ADUserInfo -Username "ABC12" -Groups
    Displays the user information and group memberships for the user "ABC12".

.EXAMPLE
    Get-ADUserInfo -Username "12345" -ByID -Unlock
    Unlocks the user account associated with the employee ID "12345".

.NOTES
    Version: 2.0
    Last Updated: 6/10/2024
    Author: Michael Steed
    Contact: msteed@null-byte.xyz
#>

function Get-ADUserInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Username,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        #Please make sure you update {SERVERNAME} to your AD Domain Controller before using this script
        [String]$Server = '{SERVERNAME}',

        [Parameter(Mandatory = $false)]
        [switch]$ByID,

        [Switch]$Unlock,
        [Switch]$Disable,
        [Switch]$Enable,
        [Switch]$Groups
    )

    if ($ByID) {
        $Username = Get-ADUser -Server $Server -Filter "EmployeeID -eq '$Username'" | Select-Object -ExpandProperty SamAccountName
    }

    function Show-UserInformation {
        param (
            [string]$Server,
            [string]$Username,
            [array]$properties
        )

        # Retrieve AD user properties
        $userProperties = Get-ADUser -Server $Server -Identity $Username -Properties *

        # Print empty lines for spacing
        Write-Host ""

        # Calculate the maximum length of property names
        $maxPropertyNameLength = ($userProperties | ForEach-Object { $_.PSObject.Properties.Name } | Measure-Object -Maximum -Property Length).Maximum

        # Define the title
        $title = "$Server User Information"

        # Calculate the padding for centering the title
        $padding = [math]::Max(0, ([console]::WindowWidth - $title.Length) / 2)

        # Output the centered title with background color spanning the window width
        Write-Host (" " * $padding) $title (" " * ($padding - 3)) -NoNewline -BackgroundColor DarkBlue -ForegroundColor White
        Write-Host " "

        # Iterate through each property
        $userProperties | ForEach-Object {
            foreach ($property in $properties) {
                $propertyName = $property
                $propertyValue = $_.$property

                # Calculate padding for alignment
                $padding = " " * ($maxPropertyNameLength - $propertyName.Length)

                # Output property name and value with background color spanning the window width
                Write-Host -NoNewline "$propertyName$padding`: " -ForegroundColor White
                if ($propertyValue -eq $true) {
                    Write-Host $propertyValue -ForegroundColor Green
                } elseif ($propertyValue -eq $false) {
                    Write-Host $propertyValue -ForegroundColor Red
                } else {
                    Write-Host $propertyValue -ForegroundColor White
                }
            }
            Write-host " "
        }
    }

    $properties = @(
        'DisplayName',
        'SamAccountName',
        'Title',
        'Department',
        'EmployeeID',
        'Enabled',
        'PasswordExpired',
        'PasswordLastSet',
        'LockedOut',
        'Description'
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
        } elseif ($Groups) {
            #$userInfo = Get-ADUser -Server $Server -Identity $Username -Properties *
            $groupInfo = Get-ADUser -Server $Server -Identity $Username -Properties MemberOf | Select-Object -ExpandProperty MemberOf
            $groupNames = $groupInfo | ForEach-Object { (Get-ADGroup -Identity $_).Name }
            Show-UserInformation -Server $Server -Username $Username -properties $properties
            Write-Host "Groups:" -ForegroundColor White
            $groupNames | ForEach-Object { Write-Host $_ -ForegroundColor White } 
            Write-host " "
        } else {
            Show-UserInformation -Server $Server -Username $Username -properties $properties
        }
    } else {
        Write-Output "User '$Username' not found."
    }
}

Export-ModuleMember -Function 'Get-ADUserInfo'
