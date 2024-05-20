# Set the usernames of the source and target users
$sourceUser = "sourceUsername"
$targetUser = "targetUsername"

# Get the security groups of the source user
$sourceGroups = Get-ADPrincipalGroupMembership $sourceUser | where {$_.ObjectClass -eq "group"}

# Add the source user's security groups to the target user
foreach ($group in $sourceGroups) {
    Add-ADGroupMember $group.SamAccountName $targetUser
}
