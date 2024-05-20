# Install the AzureAD module if you haven't already
# Install-Module AzureAD

# Connect to Azure AD
Connect-AzureAD

# Set the User Principal Names (UPN) of the source and target users
$sourceUserUPN = "sourceuser@yourdomain.com"
$targetUserUPN = "targetuser@yourdomain.com"

# Get the object ID of the source and target users
$sourceUser = Get-AzureADUser -ObjectId $sourceUserUPN
$targetUser = Get-AzureADUser -ObjectId $targetUserUPN

# Get the groups that the source user is a member of
$sourceGroups = Get-AzureADUserMembership -ObjectId $sourceUser.ObjectId | Where-Object {$_.ObjectType -eq "Group"}

# Add the target user to each group that the source user is a member of
foreach ($group in $sourceGroups) {
    Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $targetUser.ObjectId
}

# Disconnect from Azure AD
Disconnect-AzureAD
