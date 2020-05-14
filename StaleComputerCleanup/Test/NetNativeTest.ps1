Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$ctype = [System.DirectoryServices.AccountManagement.ContextType]::Domain
$context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, "smrcy.com", "DC=smrcy,DC=com"
#$compObject = [System.DirectoryServices.AccountManagement.ComputerPrincipal]::FindByIdentity($context,$env:COMPUTERNAME)
$search = [System.DirectoryServices.AccountManagement.ComputerPrincipal]::FindByPasswordSetTime($Context,[System.DateTime]::UtcNow.AddDays(-180),4)
#$search | Select-Object Name,LastPasswordSet,LastLogon | export-csv c:\temp\180.csv -notype
$array = @()
foreach($member in $search){
    $up = $member.GetUnderlyingObject()
    $operatingSystem = $up.properties['operatingSystem']
    #$member.name + ' - ' + $operatingSystem
    if($Operatingsystem -like 'Windows XP*' -or $Operatingsystem -like 'Windows Vista*' -or $Operatingsystem -like 'Windows 7*' -or $Operatingsystem -like 'Windows 8*' -or $Operatingsystem -like 'Windows 10*'){
        $info = New-Object PSObject -Property @{
            'Name' = $member.name
            'LastPasswordSet' = $member.LastPasswordSet
            'LastLogon' = $member.LastLogon
            'LastLogonTimeStamp' = ($up.properties['LastLogonTimeStamp'] | Out-String) -replace "`n|`r|`t|`v"
            'Enabled' = $member.Enabled
            'OS' = ($operatingSystem | Out-String) -replace "`n|`r|`t|`v"
            'OS_Ver' = ($up.properties['operatingSystemVersion'] | Out-String) -replace "`n|`r|`t|`v" 
            'WhenCreated' = ($up.properties['whenCreated'] | Out-String) -replace "`n|`r|`t|`v"
            'WhenChanged' = ($up.properties['whenChanged'] | Out-String) -replace "`n|`r|`t|`v"
            'Description' = $member.Description
            'DN' = $member.DistinguishedName
            'SID' = $member.SID
        }
        $array += $info
    }
    
}
$array | Export-Csv 'c:\temp\netnativeAD.csv' -NoTypeInformation
#$entry = [System.DirectoryServices.DirectoryEntry]::Get_Properties($member.GetUnderlyingObject())