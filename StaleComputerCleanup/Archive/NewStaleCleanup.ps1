#editable variables
$outputfile = "c:\temp\stalecomputers.csv"
$logfile = "C:\Temp\StaleComputers.log"
$DaysToDisable = 180
$DaysToDelete = 365 
#leave alone variables
$DisableTime = (Get-Date).Adddays(-($DaysToDisable))
$DeleteTime = (Get-Date).Adddays(-($DaysToDelete))
$datestamp = Get-Date -Format MM-dd-yy
$properties = @(
'LastLogonTimestamp'
'Description'
'LastLogonDate'
'Modified'
'Location'
'IPv4Address'
'Created'
'Operatingsystem'
'PasswordLastSet'
'SID'
)
$hash_lastLogonTimestamp = @{Name="LastLogonTimeStamp";Expression={([datetime]::FromFileTime($_.LastLogonTimeStamp))}}

import-module activedirectory

$stale = Get-ADComputer -Filter {LastLogonTimeStamp -lt $DisableTime} -Properties $properties | select-object Name,Enabled,$hash_LastLogonTimeStamp,PasswordLastSet,Modified,Created,Operatingsystem,Description,Location,IPv4Address,DistinguishedName,SID,LastLogonDate | Sort-Object -Property LastLogonDate
<#Test Set
$testname = @(
    'WD1YXM22'
    'W9VHTB22'
    'WDXCPN22'
    'W9VVYX12'
)
$stale = @()
foreach ($testpc in $testname){
    $stale += Get-ADComputer  -filter { Name -eq $testpc} -Properties $properties | select-object Name,Enabled,$hash_LastLogonTimeStamp,PasswordLastSet,Modified,Created,Operatingsystem,Description,Location,IPv4Address,DistinguishedName,SID,LastLogonDate | Sort-Object -Property LastLogonDate
}
$stale
#>

foreach ($acct in $stale){
    $name = $acct.Name
    #disable section
    <#Uncomment here to disable computer objects that meet the disable search parameters
    if ($acct.Enabled) {
        Try {
            Disable-ADAccount -Identity $acct.sid
            $desc = "Disabled due to no logins for $DaysToDisable days | " + $acct.description
            Set-ADComputer -Identity $acct.sid -Description $desc
            "$datestamp - Disabled $Name" | Out-File $logfile -Append
            }
        Catch{
            "$datestamp - Tried to disable $Name but failed at some point." | Out-File $logfile -Append
            }
        
    } #>
    #delete section
    <#Uncomment here to delete computer objects that meet the deletion search parameters
    if ($acct.LastLogonTimestamp -lt $DeleteTime) {
        Try{
            Remove-ADObject -Identity $acct.DistinguishedName -Confirm:$false -ErrorAction Stop -recursive
            "$datestamp - Deleted $Name" | Out-File $logfile -Append
            }
        Catch{
            "$datestamp - Tried to delete $Name but failed at some point." | Out-File $logfile -Append
            }
    }#>
    
}

#Output list that should be disabled or deleted
$stale | Export-Csv $outputfile -NoTypeInformation