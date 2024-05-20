<#
.SYNOPSIS
    Adds Active Directory and Office 365 groups of a source user to a target user.

.DESCRIPTION
    This script contains functions to add Active Directory and Office 365 groups of a source user
    to a specified target user. The "Add-ADGroups" function adds AD security groups, while the
    "Add-O365Groups" function adds Office 365 groups.

.NOTES
    Author: Michael Steed
    Date: 2020-01-7
    Version: 1.0
    Last Updated: 2024-05-20

    This script provides a convenient way to replicate group memberships from one user to another in Active Directory and Office 365.

.LINK
    https://example.com/documentation
#>

# Function to add AD groups
function Add-ADGroups {
    param (
        [string]$sourceUser,
        [string]$targetUser
    )

    # Get the security groups of the source user
    $sourceGroups = Get-ADPrincipalGroupMembership $sourceUser | Where-Object {$_.ObjectClass -eq "group"}

    # Add the source user's security groups to the target user
    foreach ($group in $sourceGroups) {
        Add-ADGroupMember $group.SamAccountName $targetUser
    }
}

# Function to add O365 groups
function Add-O365Groups {
    param (
        [string]$sourceUserUPN,
        [string]$targetUserUPN
    )

    # Get the object ID of the source and target users
    $sourceUser = Get-AzureADUser -ObjectId $sourceUserUPN
    $targetUser = Get-AzureADUser -ObjectId $targetUserUPN

    # Get the groups that the source user is a member of
    $sourceGroups = Get-AzureADUserMembership -ObjectId $sourceUser.ObjectId | Where-Object {$_.ObjectType -eq "Group"}

    # Add the target user to each group that the source user is a member of
    foreach ($group in $sourceGroups) {
        Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $targetUser.ObjectId
    }
}

# Main script

# Set the usernames and UPNs of the source and target users
$sourceUser = "sourceADUsername"
$targetUser = "targetADUsername"
$sourceUserUPN = "sourceuser@yourdomain.com"
$targetUserUPN = "targetuser@yourdomain.com"

# Import Active Directory module
Import-Module ActiveDirectory

# Add AD groups
Add-ADGroups -sourceUser $sourceUser -targetUser $targetUser

# Connect to Azure AD
Connect-AzureAD

# Add O365 groups
Add-O365Groups -sourceUserUPN $sourceUserUPN -targetUserUPN $targetUserUPN

# Disconnect from Azure AD
Disconnect-AzureAD
