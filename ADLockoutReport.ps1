$LockOutID = 4740
$Results = @()

$servers = @('wm01-addc-i01.accuratebackground.int', 'wm01-addc-i02.accuratebackground.int')

foreach ($server in $servers) {
    $events = Get-WinEvent -ComputerName $server -FilterXPath "*[System[(EventID=$LockOutID)]]" -MaxEvents 1000 -AsJob

    # Wait for the background job to finish
    $events | Wait-Job | Receive-Job | ForEach-Object {
        $properties = @{
            UserName = $_.Properties[0].Value
            CallerComputer = $_.Properties[1].Value
            TimeStamp = $_.TimeCreated
        }
        $Results += New-object psobject -Property $Properties
    }
}

$Results | Select-Object UserName, CallerComputer, TimeStamp | Export-csv -Path .\lockoutreport.csv -NoTypeInformation
