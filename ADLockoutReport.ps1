<#
.SYNOPSIS
    Retrieves and exports account lockout events from specified servers.

.DESCRIPTION
    This script connects to specified servers and retrieves account lockout events (Event ID 4740)
    from the Windows Event Log. It collects the relevant details (username, caller computer, and timestamp)
    and exports them to a CSV file.

.PARAMETER servers
    An array of server names to connect to and retrieve events from. Defaults to 'server1.example.com' and 'server2.example.com'.

.EXAMPLE
    .\Get-LockoutEvents.ps1 -servers 'server3.example.com', 'server4.example.com'

.NOTES
    Author: Michael Steed
    Date: 2020-01-07
    Version: 1.0
    Last Updated: 2024-05-20

    This script retrieves account lockout events from specified servers and exports the details to a CSV file.

#>




param (
    [string[]]$servers = @('server1.example.com', 'server2.example.com')
)

$LockOutID = 4740
$Results = @()

foreach ($server in $servers) {
    $events = Get-WinEvent -ComputerName $server -FilterXPath "*[System[(EventID=$LockOutID)]]" -MaxEvents 1000 -AsJob

    # Wait for the background job to finish
    $events | Wait-Job | Receive-Job | ForEach-Object {
        $properties = @{
            UserName = $_.Properties[0].Value
            CallerComputer = $_.Properties[1].Value
            TimeStamp = $_.TimeCreated
        }
        $Results += New-object psobject -Property $properties
    }
}

$Results | Select-Object UserName, CallerComputer, TimeStamp | Export-Csv -Path .\lockoutreport.csv -NoTypeInformation
