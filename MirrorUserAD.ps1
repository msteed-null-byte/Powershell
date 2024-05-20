<#
.SYNOPSIS
    Adds Active Directory security groups of a source user to a target user.

.DESCRIPTION
    This function retrieves the security groups of a specified source user and adds them to another target user.
    It can be used to replicate the group memberships from one user to another.

.PARAMETER sourceUser
    Specifies the source user whose security groups will be added to the target user.

.PARAMETER targetUser
    Specifies the target user to which the security groups of the source user will be added.

.NOTES
    Author: Michael Steed
    Date: 2029-01-07
    Version: 1.0
    Last Updated: 2024-05-20

    This function provides a convenient way to replicate group memberships from one user to another in Active Directory.

.EXAMPLE
    Add-ADGroupsToUser -sourceUser "sourceUsername" -targetUser "targetUsername"

    Adds the security groups of "sourceUsername" to "targetUsername".

.LINK
    https://example.com/documentation
#>

function Add-ADGroupsToUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$sourceUser,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$targetUser
    )

    # Get the security groups of the source user
    $sourceGroups = Get-ADPrincipalGroupMembership $sourceUser | where { $_.ObjectClass -eq "group" }

    # Add the source user's security groups to the target user
    foreach ($group in $sourceGroups) {
        Add-ADGroupMember $group.SamAccountName $targetUser
    }
}
