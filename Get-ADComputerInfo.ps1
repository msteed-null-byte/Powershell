<#
.SYNOPSIS
    Retrieves information about systems from Active Directory and exports it to a CSV file.

.DESCRIPTION
    This script reads a list of system names from a text file, retrieves information about each system
    from Active Directory, and exports the collected information to a CSV file.

.NOTES
    Author: Michael Steed
    Date: 2020-01-07
    Version: 1.0
    Last Updated: 2024-05-20

    This script provides a convenient way to collect system information from Active Directory and store it in a CSV file.

.PARAMETER systemListFile
    Specifies the path to the text file containing the list of system names.

.PARAMETER outputFile
    Specifies the path to the output CSV file where the collected information will be stored.

.LINK
    https://example.com/documentation
#>


# Input and output file paths
$systemListFile = "C:\path\to\system_list.txt"
$outputFile = "C:\path\to\output.csv"

# Read the list of system names from the text file
$systemNames = Get-Content -Path $systemListFile

# Initialize an array to hold the results
$results = @()

foreach ($system in $systemNames) {
    $adComputer = Get-ADComputer -Filter { Name -eq $system } -Properties Name, OperatingSystem, OperatingSystemVersion, LastLogonTimeStamp, Description, DistinguishedName -ErrorAction SilentlyContinue
    
    if ($adComputer) {
        $result = $adComputer | Select-Object Name, Description, OperatingSystem, OperatingSystemVersion, @{N='LastLogon'; E={[DateTime]::FromFileTime($_.LastLogonTimeStamp)}}, @{N='OU'; E={$_.DistinguishedName -replace '^.+?(?<!\\),', ''}}
    } else {
        $result = [PSCustomObject]@{
            Name = $system
            Description = "Computer Not Found in AD"
            OperatingSystem = $null
            OperatingSystemVersion = $null
            LastLogon = $null
            OU = $null
        }
    }
    
    $results += $result
}

# Export the results to CSV
$results | Export-Csv -Path $outputFile -NoTypeInformation

Write-Host "Script completed."
