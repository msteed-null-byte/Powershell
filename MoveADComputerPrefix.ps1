function BitLockerMoveADComputer {
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Identity,
        
        [Parameter(Mandatory=$false, Position=1)]
        [string] $Target
    )

    $ouMapping = @{
        "ABTH-*" = "OU=Thane,OU=India,OU=International,OU=Bitlocker - Computers,OU=Accurate Background,DC=accuratebackground,DC=int"
        "ABHYD-*" = "OU=Hyderabad,OU=India,OU=International,OU=Bitlocker - Computers,OU=Accurate Background,DC=accuratebackground,DC=int"
        "ABIRV-*" = "OU=Irvine,OU=Domestic,OU=Bitlocker - Computers,OU=Accurate Background,DC=accuratebackground,DC=int"
        "ABWIN-*" = "OU=Winchester,OU=Domestic,OU=Bitlocker - Computers,OU=Accurate Background,DC=accuratebackground,DC=int"
        "ABREM-*" = "OU=Rolling Meadows,OU=Domestic,OU=Bitlocker - Computers,OU=Accurate Background,DC=accuratebackground,DC=int"
    }

    $inScopeComputers = Get-ADComputer -Filter {
        OperatingSystem -notLike "*Server*" -and (
            $_.Name -like "ABTH-*" -or
            $_.Name -like "ABHYD-*" -or
            $_.Name -like "ABIRV-*" -or
            $_.Name -like "ABWIN-*" -or
            $_.Name -like "ABREM-*"
        )
    } -Server "domaincontroller.accuratebackground.int" -Credential $credential -SearchBase "CN=Computers,DC=accuratebackground,DC=int","OU=Computers - Imaged,DC=accuratebackground,DC=int"

    $inScopeComputers | ForEach-Object {
        if ($ouMapping.ContainsKey($_.Name)) {
            $ouPath = $ouMapping[$_.Name]
            Write-Output "$($_.Name) computer moved to $ouPath"
            Move-ADObject -Identity $_.DistinguishedName -TargetPath $ouPath -Credential $credential
        } else {
            Write-Output "$($_.Name) computer not moved"
            Move-ADObject -Identity $_.DistinguishedName -TargetPath "OU=Thane,OU=India,OU=International,OU=Bitlocker - Computers,OU=Accurate Background,DC=accuratebackground,DC=int" -Credential $credential
        }
    }
}
