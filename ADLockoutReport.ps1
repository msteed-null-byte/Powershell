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
