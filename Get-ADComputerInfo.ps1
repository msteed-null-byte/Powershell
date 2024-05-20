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
