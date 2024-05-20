function BitLockerMoveADComputer {
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Identity,
        
        [Parameter(Mandatory=$false, Position=1)]
        [string] $Target,
        
        [Parameter(Mandatory=$true)]
        [pscredential] $Credential
    )

    $ouMapping = @{
        "ABCITY1" = "OU=City1,OU=Region1,OU=Country1,OU=Computers,OU=Company,DC=example,DC=com"
        "ABCITY2" = "OU=City2,OU=Region2,OU=Country2,OU=Computers,OU=Company,DC=example,DC=com"
    }

    try {
        $inScopeComputers = Get-ADComputer -Filter {
            OperatingSystem -notLike "*Server*" -and (
                Name -like "ABCITY1-*" -or
                Name -like "ABCITY2-*"
            )
        } -Server "dc.example.com" -Credential $Credential -SearchBase "CN=Computers,DC=example,DC=com","OU=Computers - Imaged,DC=example,DC=com"

        $inScopeComputers | ForEach-Object {
            $prefix = ($_.Name -split '-')[0]
            if ($ouMapping.ContainsKey($prefix)) {
                $ouPath = $ouMapping[$prefix]
                Write-Output "$($_.Name) computer moved to $ouPath"
                Move-ADObject -Identity $_.DistinguishedName -TargetPath $ouPath -Credential $Credential
            } else {
                Write-Output "$($_.Name) computer not moved"
                Move-ADObject -Identity $_.DistinguishedName -TargetPath "OU=City1,OU=Region1,OU=Country1,OU=Bitlocker - Computers,OU=Company,DC=example,DC=com" -Credential $Credential
            }
        }
    } catch {
        Write-Error "An error occurred: $_"
    }
}
