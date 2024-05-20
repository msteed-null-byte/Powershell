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

