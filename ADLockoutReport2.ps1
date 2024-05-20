$LockOutID = 4740
$Results = @()

$servers = @('wm01-addc-i01.accuratebackground.int', 'wm01-addc-i02.accuratebackground.int')

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
        $Results += New-object psobject -Property $Properties
    }
}

$Results | Select-Object UserName, CallerComputer, TimeStamp | Export-csv -Path .\lockoutreport.csv -NoTypeInformation
