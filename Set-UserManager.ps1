<#
.SYNOPSIS
    Updates the manager attribute of users in Active Directory using information from a CSV file.

.DESCRIPTION
    This script imports user information from a CSV file, retrieves each user from Active Directory,
    and updates their manager attribute based on the information provided in the CSV file.

.NOTES
    Author: Michael Steed
    Date: 2020-01-07
    Version: 1.0
    Last Updated: 2024-05-20

    This script provides a convenient way to update user attributes in Active Directory using CSV data.

.PARAMETER CSVFile
    Specifies the path to the CSV file containing user information.

.LINK
    https://example.com/documentation
#>

# Import the Active Directory module
Import-Module ActiveDirectory

# Define the CSV file path and delimiter
$userlist = Import-Csv "C:\path\to\users.csv"

# Loop through the list of users
foreach ($user in $userlist) {
    # Get the current user
    $currentUser = Get-ADUser -Identity $user.SamAccountName

    # Get the new manager
    $newManager = Get-ADUser -Identity $user.Manager

    # Set the user's manager
    Set-ADUser -Identity $currentUser -Manager $newManager

