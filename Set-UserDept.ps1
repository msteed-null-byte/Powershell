# Import the Active Directory module
Import-Module ActiveDirectory

# Set the path to the CSV file
$CSVFile = "C:\path\to\users.csv"  # Replace with the path to your CSV file

# Set the new department name
$NewDepartment = "Finance"  # Replace with the new department name

# Import users from the CSV file
$Users = Import-Csv -Path $CSVFile

# Iterate through each user
foreach ($User in $Users) {
    # Get the username from the CSV
    $Username = $User.Username

    # Get the user from Active Directory
    $ADUser = Get-ADUser -Identity $Username -ErrorAction SilentlyContinue

    if ($ADUser -ne $null) {
        # Set the new department
        $ADUser.Department = $NewDepartment

        # Save the changes to Active Directory
        Set-ADUser -Instance $ADUser

        Write-Host "Department for user $Username has been updated to $NewDepartment."
    } else {
        Write-Host "User $Username not found in Active Directory."
    }
}
