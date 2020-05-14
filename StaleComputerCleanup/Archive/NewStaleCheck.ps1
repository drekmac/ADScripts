import-module activedirectory
$outputfile = "c:\temp\stalecomputers.csv"
# Dates
$DaysInactive = 365 
$time = (Get-Date).Adddays(-($DaysInactive)) 
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

$stale = Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} -Properties $properties | select-object Name,Enabled,LastLogonDate,PasswordLastSet,Modified,Created,Operatingsystem,Description,Location,IPv4Address,DistinguishedName | Sort-Object -Property LastLogonDate
#$stale += Get-ADComputer -Filter * -Properties $properties | Where-Object {$_.LastLogonDate -eq $null -and $_.PasswordLastSet -lt $time} | select-object Name,Enabled,LastLogonDate,PasswordLastSet,Modified,Created,Operatingsystem,Description,Location,IPv4Address,DistinguishedName | Sort-Object -Property PasswordLastSet


$stale | Export-Csv $outputfile -NoTypeInformation