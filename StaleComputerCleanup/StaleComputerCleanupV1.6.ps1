<#
.SYNOPSIS
Finds, disables, and/or deletes stale computer accounts from Active Directory
.DESCRIPTION
Finds, disables, and/or deletes stale computer accounts from Active Directory. Use -Whatif to just get information without disabling or deleting and use -Confirm if you are running the script automatically as it bypasses the confirmation to disable/delete. -File is where a CSV of the results will be saved and -Log is where disables and deletes will be logged.
.EXAMPLE
StaleComputerCleanup.ps1 -disable 180 -delete 365 -file "C:\temp\stale.csv" -log "C:\temp\stale.log"
Disables computers that have not logged in within the last 180 days and exports a csv to stale.csv, deletes computers that have not
logged in within the last 365 days, and logs everything in stale.log.
.EXAMPLE
StaleComputerCleanup.ps1 -disable 180 -delete 365 -file "C:\temp\stale.csv" -log "C:\temp\stale.log" -searchbase "OU=MercyNonManaged,DC=smrcy,DC=com"
Same as above, but searches within specific OU rather than entire domain.
.EXAMPLE
StaleComputerCleanup.ps1 -disable 180 -delete 365 -file "C:\temp\stale.csv" -log "C:\temp\stale.log" -whatif
Doesn't actually disable or delete anything, just checks.
.EXAMPLE
StaleComputerCleanup.ps1 -disable 180 -delete 365 -file "C:\temp\stale.csv" -log "C:\temp\stale.log" -confirm
Skips the confirmation to delete computers. USE WITH CAUTION!
#>
<#
Changelog
V1.6    Added ConfigMgr removal
V1.5    Removed "Top" and changed to work with SIU
V1.4    Change add passwordLastSet comparison for computers that may not be logged into but are still active
V1.3    Added parameter to only select top X number of results, will pull oldest results by PasswordLastSet first
        Also change path of CSV file to match path of Log so less parameters to mess with
V1.2    Filtered results to only include Workstation OS
V1.1    Added Searchbase to search specific OUs
V1.0    Initial product
#>
Param
(
    [Parameter(Mandatory = $true,
    HelpMessage = "How many days prior to today that a computer is considered stale enough to be disabled by its PasswordLastSet" )]
    [Int]$Disable,
    [Parameter(Mandatory = $true,
    HelpMessage = "How many days prior to today that a computer is considered stale enough to be deleted by its PasswordLastSet" )]
    [Int]$Delete,
    [Parameter(Mandatory = $false,
    HelpMessage = "Just check results without disabling or deleting anything")]
    [switch] $whatif,
    [Parameter(Mandatory = $false,
    HelpMessage = "Bypasses the confirmation pause when disabling and deleting USE WITH CAUTION!")]
    [switch] $confirm,
    [Parameter(Mandatory = $true,
    HelpMessage = "Log file location")]
    [ValidatePattern('.log$')]
    [string]$log,
    [Parameter(Mandatory = $false,
    HelpMessage = "OU to search, default is everything in current computer domain")]
    [string]$searchbase
)
if ($Delete -le $Disable){
    Throw "$($Delete) is not a valid entry. -Delete must be greater than -Disable"
}
if(!($searchbase)){
    $searchbase = (get-addomain).DistinguishedName
}
$CMSiteCode = "PS2"
$path = Get-Location
##########-modules-##########
import-module activedirectory
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
if ($null -eq $searchbase){
    $searchbase = (get-addomain).DistinguishedName
}
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
        HelpMessage = "How many days prior to today that a computer is considered stale by its PasswordLastSet" )]
        [Int]$Days,
        [Parameter(Mandatory = $false,
        HelpMessage = "Pipe results to CSV file at this location (optional)")]
        [string]$file,
        [Parameter(Mandatory = $false,
        HelpMessage = "OU to search, default is DC=smrcy,DC=com, or everything")]
        [string]$searchbase = 'DC=ad,DC=siu,DC=edu'
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
    $filter = {(LastLogonTimeStamp -lt $Time -and PasswordLastSet -lt $Time) -or (LastLogonTimeStamp -notlike '*' -and PasswordLastSet -lt $time)}#-and (Operatingsystem -like 'Windows XP*' -or Operatingsystem -like 'Windows Vista*' -or Operatingsystem -like 'Windows 7*' -or Operatingsystem -like 'Windows 8*' -or Operatingsystem -like 'Windows 10*' -or Operatingsystem -like 'Windows 2000 Pro*')}
    $Time = (Get-Date).Adddays(-($Days))
    $stale = Get-ADComputer -Filter $filter -SearchBase $searchbase -Properties PasswordLastSet | Sort-Object -Property PasswordLastSet
    $all = @()
    foreach($object in $stale){
        $fulldata = Get-ADComputer -Identity $object.SID -Properties LastLogonTImeStamp,Name,Enabled,Passwordlastset,modified,created,operatingsystem,description,location,ipv4address,distinguishedname,sid,lastlogondate | select-object $select
        $all += $fulldata
    }
    if ($null -ne $file){
        $all | Export-Csv $file -NoTypeInformation
    }
    return $all
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
            Set-Location "$($CMSiteCode):"
            Try{
                Remove-CMDevice -Name $name -Force -ErrorAction Stop
                "Removed $Name from ConfigMgr" | timestamp | Out-File $log -Append
            }
            Catch{
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                "Tried to remove $Name from SCCM but failed. $FailedItem - $ErrorMessage" | timestamp | Out-File $log -Append
            }
            Set-Location $path
        }else {
            "Tried to remove $name from AD but it was enabled, make sure it's really not in use and run again." | timestamp | Out-File $log -Append
        }
    }
}
##########-variables-##########
$DeleteDate = (Get-Date).Adddays(-($Delete))
$timestamp = (timestamp).replace(': ','')
$csv = $log -Replace "\.log","_$timestamp.csv"
##########-do work-##########
"Script started. Disable=$disable, Delete=$delete, Log=$log, Whatif=$whatif, Confirm=$confirm, Searchbase=$searchbase" | timestamp | Out-File $log -Append
$Stale = Get-StaleComputers -days $Disable -file $csv -SearchBase $searchbase 
$StaleDelete = $Stale | Where-Object PasswordLastSet -lt $DeleteDate
$Stalecount = ($Stale | Where-Object Enabled -EQ 'True').Count
$DeleteCount = ($StaleDelete | Where-Object Enabled -NE 'True').Count
if(!$whatif){
    if (!$confirm) {
        Write-Host "WARNING: $StaleCount computers are about to be disabled and $DeleteCount computers are about to be deleted (if they are disabled)." -ForegroundColor Yellow -BackgroundColor Red
        $goahead = Read-Host -Prompt 'Type "confirm" if you are sure you want to do this'
    }    
    if ($confirm -or $goahead -eq 'confirm'){
        Remove-Computers -list $StaleDelete -log $log
        Disable-Computers -list $stale -log $log
       
    }
} else{
    "Whatif - $StaleCount would have been disabled and $deletecount would have been deleted."
}
"Script Ended. Disable=$disable, Delete=$delete, Log=$log, Whatif=$whatif, Confirm=$confirm, Searchbase=$searchbase" | timestamp | Out-File $log -Append