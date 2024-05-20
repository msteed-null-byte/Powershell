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
