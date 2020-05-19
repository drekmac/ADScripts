#This script simply pulls in data from a CSV, does a Get-AdUser on it, adds someinfo to it, and outputs it to another csv.
#Pretty specific use case, but I may need to do something similar again.
$input = Import-Csv .\UserList.csv
$properties = @(
    'canonicalName'
    'Description'
    'DisplayName'
    'Created'    
    'emailaddress'    
    'LastLogonTimeStamp'
    'PasswordExpired'
    'PasswordLastSet'    
)
foreach($line in $input){
    $ad = $null
    $ad = get-aduser $line."Account Name" -Properties $properties    
    $line | Add-Member -MemberType NoteProperty -Name 'SamAccountName' -Value $ad.SamAccountName
    $line | Add-Member -MemberType NoteProperty -Name 'Enabled' -Value $ad.enabled
    $line | Add-Member -MemberType NoteProperty -Name 'CanonicalName' -Value $ad.CanonicalName
    $line | Add-Member -MemberType NoteProperty -Name 'SID' -Value $ad.SID
    $line | Add-Member -MemberType NoteProperty -Name 'Description' -Value $ad.description
    $line | Add-Member -MemberType NoteProperty -Name 'UserPrincipleName' -Value $ad.UserPrincipalName
    $line | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value $ad.DisplayName
    $line | Add-Member -MemberType NoteProperty -Name 'Created' -Value $ad.Created
    $line | Add-Member -MemberType NoteProperty -Name 'EmailAddress' -Value $ad.emailaddress
    $line | Add-Member -MemberType NoteProperty -Name 'LastLogonTimeStamp' -Value ([datetime]::FromFileTime($_.LastLogonTimeStamp))
    $line | Add-Member -MemberType NoteProperty -Name 'PasswordExpired' -Value $ad.passwordExpired
    $line | Add-Member -MemberType NoteProperty -Name 'PasswordLastSet' -Value $ad.passwordLastSet
    $line | Export-Csv .\results.csv -NoTypeInformation -Append
}