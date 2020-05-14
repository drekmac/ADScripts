# Adjustable Variables
$DaysInactive = 365 #Number of days a computer is inactive before being considered stale
$today = get-date -f yy-MM-dd
$csvpath = "c:\temp\stalecomputers_$today.csv" #Output file

#Set variables, don't adjust
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

#modules
import-module activedirectory
Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

#DoWork
$stale = Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} -Properties $properties | 
select-object Name,Enabled,LastLogonDate,PasswordLastSet,Modified,Created,Operatingsystem,Description,Location,IPv4Address,DistinguishedName
$stale += Get-ADComputer -Filter * -Properties $properties | Where-Object {$_.LastLogonDate -eq $null -and $_.PasswordLastSet -lt $time} |
select-object Name,Enabled,LastLogonDate,PasswordLastSet,Modified,Created,Operatingsystem,Description,Location,IPv4Address,DistinguishedName
Set-Location PS1:
foreach ($line in $stale)
{
    $name = $line.Name
    $CM = get-cmdevice -name $name -Fast
    if ($null -eq $cm)
    {
        $line | Add-Member -MemberType NoteProperty "Configmgr" -Value "No"
        $line | Add-Member -MemberType NoteProperty "Configmgr_LastActive" -Value "N/A"
        $line | Add-Member -MemberType NoteProperty "CM_PrimaryUser" -Value "N/A"
        $line | Add-Member -MemberType NoteProperty "CM_UserName" -Value "N/A"
        $line | Add-Member -MemberType NoteProperty "CM_LastUser" -Value "N/A"
        $line | Add-Member -MemberType NoteProperty "CM_MAC" -Value "N/A"
        $line | Add-Member -MemberType NoteProperty "CM_ID" -Value "N/A"
    }
    else 
    {
        $line | Add-Member -MemberType NoteProperty "CM" -Value "Yes"
        $line | Add-Member -MemberType NoteProperty "CM_LastActive" -Value $CM.LastActiveTime
        $line | Add-Member -MemberType NoteProperty "CM_PrimaryUser" -Value $CM.PrimaryUser
        $line | Add-Member -MemberType NoteProperty "CM_UserName" -Value $CM.UserName
        $line | Add-Member -MemberType NoteProperty "CM_LastUser" -Value $CM.LastLogonUser
        $line | Add-Member -MemberType NoteProperty "CM_MAC" -Value $CM.MACAddress
        $line | Add-Member -MemberType NoteProperty "CM_ID" -Value $CM.ResourceID

    }
}

$stale | Export-Csv $csvpath -notype