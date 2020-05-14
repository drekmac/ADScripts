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
StaleComputerCleanup.ps1 -disable 180 -delete 365 -file "C:\temp\stale.csv" -log "C:\temp\stale.log" -whatif
Doesn't actually disable or delete anything, just checks.
.EXAMPLE
StaleComputerCleanup.ps1 -disable 180 -delete 365 -file "C:\temp\stale.csv" -log "C:\temp\stale.log" -confirm
Skips the confirmation to delete computers. USE WITH CAUTION!
#>
<#
Changelog
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
    HelpMessage = "Pipe results to CSV file at this location (optional)")]
    [ValidatePattern('.csv$')]
    [string]$file,

    [Parameter(Mandatory = $true,
    HelpMessage = "Log file location")]
    [ValidatePattern('.log$')]
    [string]$log
)
if ($Delete -le $Disable){
    Throw "$($Delete) is not a valid entry. -Delete must be greater than -Disable"
}

##########-modules-##########
import-module activedirectory
filter timestamp {"$(Get-Date -Format G): $_"}

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
        [string]$file
    )
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
    $Time = (Get-Date).Adddays(-($Days))
    $hash_lastLogonTimestamp = @{Name="LastLogonTimeStamp";Expression={([datetime]::FromFileTime($_.LastLogonTimeStamp))}}
    $stale = Get-ADComputer -Filter {LastLogonTimeStamp -lt $Time} -Properties $properties | select-object Name,Enabled,$hash_LastLogonTimeStamp,PasswordLastSet,Modified,Created,Operatingsystem,Description,Location,IPv4Address,DistinguishedName,SID,LastLogonDate | Sort-Object -Property LastLogonDate
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
                "Tried to disable $Name but failed at some point. Error- $FailedItem - $ErrorMessage" | timestamp | Out-File $log -Append
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
                "Tried to remove $Name from AD but failed at some point. $FailedItem - $ErrorMessage" | timestamp | Out-File $log -Append
                }
            
        }else {
            "Tried to remove $name from AD but it was enabled, make sure it's really not in use and run again." | timestamp | Out-File $log -Append
        }
    }
}

##########-variables-##########
$DeleteDate = (Get-Date).Adddays(-($Delete))

##########-do work-##########
$Stale = Get-StaleComputers -days $Disable -file $file
$StaleDelete = $Stale | Where-Object LastLogonTimestamp -lt $DeleteDate
$Stalecount = $Stale.Count
$DeleteCount = $StaleDelete.Count
if(!$whatif){
    if (!$confirm) {
        Write-Host "WARNING: $Stalecount computers are about to be disabled and $DeleteCount computers are about to be deleted (if they are disabled)." -ForegroundColor Yellow -BackgroundColor Red
        $goahead = Read-Host -Prompt 'Type "confirm" if you are sure you want to do this'
    }    
    if ($confirm -or $goahead -eq 'confirm'){
        "These are still commented out, edit the script and uncomment the Disable-Computers and Remove-Computers lines."
        #Disable-Computers -list $stale -log $log
        #Remove-Computers -list $StaleDelete -log $log
    }

} else{
    $Stalecount = $Stale.Count
    $DeleteCount = $StaleDelete.Count
    "Whatif - $Stalecount would have been disabled and $deletecount would have been deleted."
}