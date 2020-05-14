##########-variables you can change-##########
$Disable = 180
$Delete = 365
$log = "\\smrcy.com\repo$\FieldAccess\ScriptLogs\ADCleanup\ComputerCleanup.log"
$searchbase = 'DC=smrcy,DC=com'
$top = 500
# I keep upping the number of results to offset the number of computers that 
# cannot be disabled or deleted due to permissions -Derek
##########-modules-##########
if ((Get-WindowsFeature RSAT-AD-PowerShell).InstallState -ne 'Installed'){
    Install-WindowsFeature RSAT-AD-PowerShell
}
import-module activedirectory
filter timestamp {"$(Get-Date -Format "yyyy-MM-dd_HH.mm.ss"): $_"}
function Get-StaleComputers {
    <#
    .Synopsis
    Gets stale computer accounts from Active Directory
    .DESCRIPTION
    Gets stale computer accounts from Active Directory
    .EXAMPLE
    Get-StaleComputers -days 180 
    Returns computers to console
    .EXAMPLE
    Get-StaleComputers -days 365 -file "C:\temp\stale.csv"
    Output stale computers in CSV file
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = "How many days prior to today that a computer is considered stale by its LastLogonTimeStamp" )]
        [Int]$Days,
        [Parameter(Mandatory = $false,
        HelpMessage = "Pipe results to CSV file at this location (optional)")]
        [string]$file,
        [Parameter(Mandatory = $false,
        HelpMessage = "OU to search, default is DC=smrcy,DC=com, or everything")]
        [string]$searchbase = 'DC=smrcy,DC=com',
        [Parameter(Mandatory = $false,
        HelpMessage = "Only work with the top X number of results, limits the total results pool that disable/delete runs from, not the individual disable/delete numbers")]
        [Int]$top = 100000
    )
    $select = @(
    @{Name="LastLogonTimeStamp";Expression={([datetime]::FromFileTime($_.LastLogonTimeStamp))}}
    'Name'
    'Enabled'
    'PasswordLastSet'
    'Modified'
    'Created'
    'OperatingSystem'
    'Description'
    'Location'
    'IPv4Address'
    'DistinguishedName'
    'SID'
    'LastLogonDate'
    )
    $filter = {LastLogonTimeStamp -lt $Time -and (Operatingsystem -like 'Windows XP*' -or Operatingsystem -like 'Windows Vista*' -or Operatingsystem -like 'Windows 7*' -or Operatingsystem -like 'Windows 8*' -or Operatingsystem -like 'Windows 10*' -or Operatingsystem -like 'Windows 2000 Pro*') }
    $Time = (Get-Date).Adddays(-($Days))
    $stale = Get-ADComputer -Filter $filter -Properties * -SearchBase $searchbase | Sort-Object -Property LastLogonDate | select-object $select -First $top
    if ($null -ne $file){
        $stale | Export-Csv $file -NoTypeInformation
    }
    return $stale
}
function Disable-Computers {
    <#
    .Synopsis
    Disables an array of computer accounts from Active Directory
    .DESCRIPTION
    Disables an array of computer accounts from Active Directory
    .EXAMPLE
    Disable-StaleComputers -list $listofcomputers
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [array]$list,
        [Parameter(Mandatory = $false)]
        [string]$log
    )
    foreach($acct in $list){
        $name = $acct.Name
        if ($acct.Enabled) {
            Try {
                Disable-ADAccount -Identity $acct.sid -ErrorAction Stop
                $desc = "Disabled due to no logins for $Disable days | " + $acct.description
                Set-ADComputer -Identity $acct.sid -Description $desc
                "Disabled $Name" | timestamp | Out-File $log -Append
                }
            Catch{
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                "Tried to disable $Name but failed. Error- $FailedItem - $ErrorMessage" | timestamp | Out-File $log -Append
                }
            
        } else {
            "$name already disabled, skipping." | timestamp | Out-File $log -Append
        }
    }
}
function Remove-Computers {
    <#
    .Synopsis
    Deletes an array of computer accounts from Active Directory
    .DESCRIPTION
    Deletes an array of computer accounts from Active Directory
    .EXAMPLE
    Remove-StaleComputers -list $listofcomputers
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [array]$list,
        [Parameter(Mandatory = $false)]
        [string]$log
    )
    foreach($acct in $list){
        $name = $acct.Name
        if (!$acct.Enabled) {
            Try {
                Set-ADObject -Identity $acct.DistinguishedName -ProtectedFromAccidentalDeletion:$false
                Remove-ADObject -Identity $acct.DistinguishedName -Confirm:$false -ErrorAction Stop -recursive
                "Removed $Name from AD" | timestamp | Out-File $log -Append
                }
            Catch{
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                "Tried to remove $Name from AD but failed. $FailedItem - $ErrorMessage" | timestamp | Out-File $log -Append
                }
            
        }else {
            "Tried to remove $name from AD but it was enabled, make sure it's really not in use and run again." | timestamp | Out-File $log -Append
        }
    }
}
##########-variables you should not change-##########
$DeleteDate = (Get-Date).Adddays(-($Delete))
$timestamp = (timestamp).replace(': ','')
$csv = $log -Replace "\.log","_$timestamp.csv"
##########-do work-##########
"Script started. Disable=$disable, Delete=$delete, Log=$log, Top=$top, Confirm=$confirm, Searchbase=$searchbase" | timestamp | Out-File $log -Append
$Stale = Get-StaleComputers -days $Disable -file $csv -SearchBase $searchbase -top $top
$StaleDelete = $Stale | Where-Object LastLogonTimestamp -lt $DeleteDate
Remove-Computers -list $StaleDelete -log $log
Disable-Computers -list $stale -log $log
"Script Ended. Disable=$disable, Delete=$delete, Log=$log, Top=$top, Searchbase=$searchbase" | timestamp | Out-File $log -Append