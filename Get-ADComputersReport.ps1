<#
.SYNOPSIS
    Retrieves information about systems from Active Directory and exports it to a Excel file.

.DESCRIPTION
    This script queries Active Directory for list of all computers objects and compiles information about each one
    and exports the collected information to a Excel file.

.NOTES
    Author: Michael Steed
    Date: 2020-01-07
    Version: 3.0
    Last Updated: 2024-12-12

    This script provides a convenient way to collect system information from Active Directory and store it in a Excel file.
#>   

# Input and output file paths
$outputFile = ".\ADComputerInfo.xlsx"

# OS Version Maps
$winOSVersionMap = @{
    "6000"  = "Windows Vista (RTM)"
    "6001"  = "Windows Vista SP1"
    "6002"  = "Windows Vista SP2"
    "7600"  = "Windows 7 (RTM)"
    "7601"  = "Windows 7 SP1"
    "9200"  = "Windows 8"
    "9600"  = "Windows 8.1"
    "10240" = "Windows 10 1507 (RTM)"
    "10586" = "Windows 10 1511 (November Update)"
    "14393" = "Windows 10 1607 (Anniversary Update)"
    "15063" = "Windows 10 1703 (Creators Update)"
    "16299" = "Windows 10 1709 (Fall Creators Update)"
    "17134" = "Windows 10 1803 (April 2018 Update)"
    "17763" = "Windows 10 1809 (October 2018 Update)" #Used for Server 2019 as well
    "18362" = "Windows 10 1903 (May 2019 Update)"
    "18363" = "Windows 10 1909 (November 2019 Update)"
    "19041" = "Windows 10 2004 (May 2020 Update)"
    "19042" = "Windows 10 20H2 (October 2020 Update)"
    "19043" = "Windows 10 21H1 (May 2021 Update)"
    "19044" = "Windows 10 21H2 (November 2021 Update)"
    "19045" = "Windows 10 22H2 (October 2022 Update)"
    "22000" = "Windows 11 21H2 (October 2021 Update)"
    "22621" = "Windows 11 22H2 (September 2022 Update)"
    "22631" = "Windows 11 23H2 (September 2023 Update)"
        "26100" = "Windows 11 24H2 (September 2024 Update)"
    "20348" = "Windows Server 2022 (20348)"
}

$macOSVersionMap = @{
    "10" = "macOS (OS X) Pre 11" # Grouping all pre-Big Sur versions
    "11" = "macOS Big Sur"
    "11.7.10" = "macOS Big Sur 11.7.10" #(Final Big Sur Release)
    "12" = "macOS Monterey"
    "12.7.6" = "macOS Monterey 12.7.6" #(Final Monterey Release)
    "13" = "macOS Ventura"
    "13.7.2" = "macOS Ventura 13.7.2" #(Current Ventura Release)
    "14" = "macOS Sonoma"
    "14.7.2" = "macOS Sonoma 14.7.2" #(Current Sonoma Release)
    "15" = "macOS Sequoia"
    "15.2" = "macOS Sequoia 15.2" #(Current Release December 2024)

}

# Retrieve all computer objects from Active Directory
$systemNames = Get-ADComputer -Filter * -Properties Name, OperatingSystem, OperatingSystemVersion, LastLogonTimeStamp, Description, Enabled, DistinguishedName

# Initialize an array to hold the results
$results = @()

foreach ($system in $systemNames) {
    $osVersion = $system.OperatingSystemVersion
    $readableVersion = $osVersion # Initialize

    if ($osVersion) {
        $osVersionString = "$osVersion" # Ensure $osVersion is a string
        Write-Host "--------------------------------------------------"
        Write-Host "Computer Name: $($system.Name)"
        Write-Host "Raw OS Version: '$osVersionString'"
        Write-Host "Raw OS Version Type: $($osVersionString.GetType().FullName)"

        if ($system.OperatingSystem -like "*Windows 10*" -or $system.OperatingSystem -like "*Windows 11*" -or $system.OperatingSystem -like "*Windows Server*") {
            # Windows Logic (Direct Lookup with Build Number Extraction)
            $buildNumber = $osVersion -replace '.*\((\d+)\).*', '$1' # Extract Build Number
            if (-not $buildNumber) {$buildNumber = $osVersion} #If build number is not found use raw version
            if ($winOSVersionMap.ContainsKey($buildNumber)) { #Lookup by build number
                $readableVersion = $winOSVersionMap[$buildNumber]
                Write-Host "Found in Windows Map: '$readableVersion'"
                if ($buildNumber -eq "17763" -and $system.OperatingSystem -like "*Server*") {
                    $readableVersion = "Windows Server 2019 (17763)"
                } elseif ($buildNumber -eq "14393" -and $system.OperatingSystem -like "*Server*") {
                    $readableVersion = "Windows Server 2016 (14393)"
                }
            } else {
                $readableVersion = "Unknown Windows Version - Raw Version: '$osVersionString'"
                Write-Host "Not Found in Windows Map: '$readableVersion'"
            }
        } elseif ($system.OperatingSystem -like "*macOS*" -or $system.OperatingSystem -like "*OS X*") {
            $osVersion = $system.OperatingSystemVersion
            Write-Host "--------------------------------------------------"
            Write-Host "Computer Name: $($system.Name)"
            Write-Host "Raw OS Version: '$osVersion'"
            Write-Host "Raw OS Version Type: $($osVersion.GetType().FullName)"
        
            $majorVersion = $osVersion -replace "^(\d+)(\.\d+)?.*", '$1' # Extracts major version
            $readableVersion = "" #Initialize readable version
        
            if ($majorVersion -eq "10") { # Check if it's a macOS 10.x version
                $readableVersion = "macOS (OS X) Pre 11 ($osVersion)" # Display "Pre 11" with full version
                Write-Host "Found in macOS Map (Pre 11): '$readableVersion'"
            } elseif ($macOSVersionMap.ContainsKey($osVersion)) { # Check for specific version FIRST
                $readableVersion = $macOSVersionMap[$osVersion] + " ($osVersion)" # Append full version
                Write-Host "Found in macOS Map (Specific): '$readableVersion'"
            } elseif ($macOSVersionMap.ContainsKey($majorVersion)) { # Fallback to major
                $readableVersion = $macOSVersionMap[$majorVersion] + " ($osVersion)" # Append full version
                Write-Host "Found in macOS Map (Major): '$readableVersion'"
            } else {
                $readableVersion = "Unknown macOS Version (Raw: $osVersion)"
                Write-Host "Not Found in macOS Map: '$readableVersion'"
            }
            Write-Host "Readable Version is: '$readableVersion'"
            Write-Host "--------------------------------------------------"
        }

    $result = $system | Select-Object Name, Description, OperatingSystem, @{N='OperatingSystemVersion'; E={$readableVersion}}, Enabled, @{N='LastLogon'; E={[DateTime]::FromFileTime($_.LastLogonTimeStamp)}}, @{N='OU'; E={$_.DistinguishedName -replace '^.+?(?<!\\),', ''}}
    $results += $result
    }

}

try {
    Import-Module ImportExcel
    $results | Export-Excel -Path $outputFile -AutoSize
    Write-Host "Script completed. Results saved to $outputFile"
} catch {
    Write-Error "Error exporting to Excel: $($_.Exception.Message)"
    $results | Export-Csv -Path ".\ADComputerInfo.csv" -NoTypeInformation
    Write-Warning "Data saved to CSV as fallback."
}