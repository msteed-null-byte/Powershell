<#
.SYNOPSIS
    This script retrieves information about Active Directory users and their security groups. It also provides functionality to add, remove, and clone security groups, with the ability to search for groups if the exact name is not known.

.DESCRIPTION
    The Get-ADUserGroupInfo function retrieves information about Active Directory users, including their security groups. It also allows adding, removing, and cloning security groups for the user, with an option to search for groups.

.PARAMETER Username
    Specifies the username of the Active Directory user to retrieve information for.

.PARAMETER Server
    Specifies the Active Directory server to connect to. Default is '{SERVERNAME}'. Please make sure you update to your default AD Domain Controller Server name.

.PARAMETER AddGroup
    Specifies the security group to add to the user. Allows partial names for searching.

.PARAMETER RemoveGroup
    Specifies the security group to remove from the user.

.PARAMETER CloneGroups
    Specifies the username of another user whose groups will be cloned to the target user.

.EXAMPLE
    Get-ADUserGroupInfo -Username "JohnDoe" -AddGroup "HR"
    Searches for and adds a group with a name containing "HR" to the user "JohnDoe".

.EXAMPLE
    Get-ADUserGroupInfo -Username "JaneDoe" -RemoveGroup "Finance_Security"
    Removes the "Finance_Security" group from the user "JaneDoe".

.EXAMPLE
    Get-ADUserGroupInfo -Username "JohnDoe" -CloneGroups "TemplateUser"
    Clones the group memberships of "TemplateUser" to "JohnDoe".

.NOTES
    Version: 1.0
    Last Updated: 06/10/2024
    Author: Michael Steed
    Contact: msteed@null-byte.xyz
#>

function Get-ADUserGroupInfo {
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
        [ValidateNotNullOrEmpty()]
        [String]$AddGroup,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$RemoveGroup,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$CloneGroups
    )

    # Retrieve AD user properties
    $user = Get-ADUser -Server $Server -Identity $Username -Properties MemberOf

    if (-not $user) {
        Write-Output "User '$Username' not found."
        return
    }

    # Retrieve current groups
    $currentGroups = $user.MemberOf | ForEach-Object { (Get-ADGroup -Identity $_).Name }

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
        Write-Host (" " * $padding) $title (" " * ($padding - 2)) -NoNewline -BackgroundColor DarkBlue -ForegroundColor White
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
        'Description'
    )

    Show-UserInformation -Server $Server -Username $Username -properties $properties

    # Display current groups
    Write-Host "Groups:" -ForegroundColor White
    $currentGroups | ForEach-Object { Write-Host $_ -ForegroundColor White }
    Write-host " "

    function Get-GroupName {
        param (
            [string]$PartialName,
            [string]$Server
        )
        $groups = Get-ADGroup -Filter "Name -like '*$PartialName*'" -Server $Server | Select-Object -ExpandProperty Name
        if ($groups.Count -eq 1) {
            return $groups[0]
        } elseif ($groups.Count -gt 1) {
            Write-Host "Multiple groups found matching '$PartialName':" -ForegroundColor Yellow
            $groups | ForEach-Object { Write-Host $_ -ForegroundColor White }
            $selectedGroup = Read-Host "Please enter the exact name of the group you want to add"
            return $selectedGroup
        } else {
            Write-Output "No groups found matching '$PartialName'."
            return $null
        }
    }

    # Add user to specified group
    if ($AddGroup) {
        $groupToAdd = Get-GroupName -PartialName $AddGroup -Server $Server
        if ($groupToAdd) {
            try {
                Add-ADGroupMember -Identity $groupToAdd -Members $Username -Server $Server
                Write-Output "User '$Username' has been added to the group '$groupToAdd'."
            } catch {
                Write-Output "Failed to add user to group '$groupToAdd': $_"
            }
        }
    }

    # Remove user from specified group
    if ($RemoveGroup) {
        try {
            Remove-ADGroupMember -Identity $RemoveGroup -Members $Username -Server $Server
            Write-Output "User '$Username' has been removed from the group '$RemoveGroup'."
        } catch {
            Write-Output "Failed to remove user from group '$RemoveGroup': $_"
        }
    }

    # Clone groups from another user
    if ($CloneGroups) {
        $templateUser = Get-ADUser -Server $Server -Identity $CloneGroups -Properties MemberOf
        if ($templateUser) {
            $templateGroups = $templateUser.MemberOf | ForEach-Object { (Get-ADGroup -Identity $_).Name }
            foreach ($group in $templateGroups) {
                if (-not $currentGroups -contains $group) {
                    try {
                        Add-ADGroupMember -Identity $group -Members $Username -Server $Server
                        Write-Output "User '$Username' has been added to the group '$group' from '$CloneGroups'."
                    } catch {
                        Write-Output "Failed to add user to group '$group' from '$CloneGroups': $_"
                    }
                }
            }
        } else {
            Write-Output "Template user '$CloneGroups' not found."
        }
    }
}

Export-ModuleMember -Function 'Get-ADUserGroupInfo'
