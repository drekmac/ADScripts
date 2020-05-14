import-module activedirectory  
# Dates
$DaysInactive = 365 
$date = Get-Date -f yy-MM
$dateday = Get-Date -Format MM-dd-yy
$lastdate = (get-date).AddMonths(-1).ToString('yy-MM')
$time = (Get-Date).Adddays(-($DaysInactive)) 
$deleton = (Get-Date).AddMonths(1).ToString('MM-dd-yy')
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
)
# Set paths to files 
$filepath = "c:\temp\ADCleanup\ADStaleComputerCleanup\$date\$date-OLD.csv"
$lastpath = "c:\temp\ADCleanup\ADStaleComputerCleanup\$lastdate\$lastdate-OLD.csv"
$logpath = "c:\temp\ADCleanup\ADStaleComputerCleanup\$date\disable.log"
$removelog = "c:\temp\ADCleanup\ADStaleComputerCleanup\$lastdate\remove.log"

 
# Create Output Folder
md -force -path "E:\ADCleanup\ADStaleComputerCleanup\$date"


# Compute cutoff time

$stale = Get-ADComputer -Filter "Name -like 'itsys-dmcn*'" -Properties $properties
<#$stale = Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} -Properties $properties | 
select-object Name,Enabled,Description,LastLogonDate,Modified,Created,Location,IPv4Address,Operatingsystem,DistinguishedName,passwordlastset
$stale += Get-ADComputer -Filter * -Properties $properties | ?{$_.LastLogonDate -eq $null -and $_.PasswordLastSet -lt $time} |
select-object Name,Enabled,Description,LastLogonDate,Modified,Created,Location,IPv4Address,Operatingsystem,DistinguishedName,passwordlastset
#>
$stale | Export-Csv $filepath -NoTypeInformation
ForEach ($computer in $stale) {
    try {
        Disable-ADAccount -Identity $computer.DistinguishedName 
        $desc = "Will be deleted $deleton " + $computer.description
        Set-ADComputer -Identity $computer.DistinguishedName -Description $desc
        $dateday + " Disabled " + $computer.Name | Out-File $logpath -Append
    }
    catch{
        $dateday + " Disable failed for " + $computer.Name | Out-File $logpath -Append
    }
}
<#
#Delete Section
# BE CAREFUL!!! Completely removes accounts listed in csv file in a folder named yy-MM from the previous month
$lastmonth = Import-CSV $lastpath
foreach ($computer in $lastmonth) {
    try {        
        $compobject = Get-ADComputer -Identity $computer.DistinguishedName
        }
    catch{
        $dateday + " " + $computer.Name + " no longer exists" | Out-File $removelog -Append
        }
    if(!$compobject.Enabled) {
        try {
            Set-ADObject -Identity $compobject.DistinguishedName -ProtectedFromAccidentalDeletion:$false -PassThru | Remove-ADObject -Confirm:$false -ErrorAction stop
            $dateday + " " + $compobject.Name + " deleted" | Out-File $removelog -Append
            }
        catch {
            $dateday + " " + $compobject.Name + " failed to delete" | Out-File $removelog -Append
            }
    } else {
        $dateday + " " + $compobject.Name + " has been re-enabled since last run" | Out-File $removelog -Append
    }
}


#>

   
        




