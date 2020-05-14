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
V1.3    Added parameter to only select top X number of results, will pull oldest results by lastlogontimestamp first
        Also change path of CSV file to match path of Log so less parameters to mess with
V1.2    Filtered results to only include Workstation OS
V1.1    Added Searchbase to search specific OUs
V1.0    Initial product
#>
Param
(
    [Parameter(Mandatory = $true,
    HelpMessage = "How many days prior to today that a computer is considered stale enough to be disabled by its LastLogonTimeStamp" )]
    [Int]$Disable,
    [Parameter(Mandatory = $true,
    HelpMessage = "How many days prior to today that a computer is considered stale enough to be deleted by its LastLogonTimeStamp" )]
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
    HelpMessage = "OU to search, default is DC=smrcy,DC=com, or everything")]
    [string]$searchbase = 'DC=smrcy,DC=com',
    [Parameter(Mandatory = $false,
    HelpMessage = "Only work with the top X number of results, limits the total results pool that disable/delete runs from, not the individual disable/delete numbers")]
    [Int]$top = 100000
)
if ($Delete -le $Disable){
    Throw "$($Delete) is not a valid entry. -Delete must be greater than -Disable"
}
##########-modules-##########
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
##########-variables-##########
$DeleteDate = (Get-Date).Adddays(-($Delete))
$timestamp = (timestamp).replace(': ','')
$csv = $log -Replace "\.log","_$timestamp.csv"
##########-do work-##########
"Script started. Disable=$disable, Delete=$delete, Log=$log, Top=$top, Whatif=$whatif, Confirm=$confirm, Searchbase=$searchbase" | timestamp | Out-File $log -Append
$Stale = Get-StaleComputers -days $Disable -file $csv -SearchBase $searchbase -top $top
$StaleDelete = $Stale | Where-Object LastLogonTimestamp -lt $DeleteDate
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
"Script Ended. Disable=$disable, Delete=$delete, Log=$log, Top=$top, Whatif=$whatif, Confirm=$confirm, Searchbase=$searchbase" | timestamp | Out-File $log -Append