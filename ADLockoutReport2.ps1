param (
    [string[]]$servers = @('server1.example.com', 'server2.example.com')
)

$LockOutID = 4740
$Results = @()

foreach ($server in $servers) {
    $events = Get-WinEvent -ComputerName $server -FilterHashtable @{
        LogName = 'Security'
        ID = $LockOutID
    }

    foreach ($event in $events) {
        $properties = @{
            UserName = $event.Properties[0].Value
            CallerComputer = $event.Properties[1].Value
            TimeStamp = $event.TimeCreated
        }
        $Results += New-Object psobject -Property $properties
    }
}

$Results | Select-Object UserName, CallerComputer, TimeStamp | Export-Csv -Path .\lockoutreport.csv -NoTypeInformation
