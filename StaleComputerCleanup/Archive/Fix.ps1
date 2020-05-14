$stale = Import-Csv c:\temp\stalecomputers.csv
Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
Set-Location PS1:
foreach ($line in $stale)
{
    if ($line.cm = $null){
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
}