#This script searches through the default Computers container and moves any it finds where they need to go,
#or in the OU of Shame if it can't figure it out.
Function Add-TeamsAlert {
    Param (
        [Parameter(Mandatory=$true)]
        [String]$alert
    )

    $uri= "https://outlook.office.com/webhook/c24107dc-e5d1-4bb4-b7f8-291159171d7a@d57a98e7-744d-43f9-bc91-08de1ff3710d/IncomingWebhook/ae664b2ab1ff45bfa5f04c55814ce054/0346bb91-bfa3-462c-ae57-205a05da36eb"

    $body = ConvertTo-JSON @{
        text = $alert
    }
Invoke-RestMethod -uri $uri -Method Post -body $body -ContentType 'application/json'
}

import-module activedirectory
#$logfile="E:\ADCleanup\ComputerContainerCleanup.csv"
#Compute days before delete
$DaysInactive = 7 
#$date = Get-Date -f yy-MM-dd
$time = (Get-Date).Adddays(-($DaysInactive))
$deleteon = (Get-Date).AddDays($DaysInactive)

#Where the script searches for computers
$computerOU="CN=Computers,DC=ad,DC=siu,DC=edu"
#$computerOU="OU=OU of Shame,DC=ad,DC=siu,DC=edu"
$Shame="OU=OU of Shame,DC=ad,DC=siu,DC=edu"

#Department Filters
$csv = Import-Csv '\\itsys-sccm\s$\Scripts\OSD\OUMap.csv'
$filterArray = @(
    @{
        Filter = "ACH*"
        OU = "OU=Computers,OU=ACHIEVE,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "AFFA*"
        OU = "OU=Computers,OU=AFFA,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "AFROTC*"
        OU = "OU=Computers,OU=AFROTC,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "AG*"
        OU = "OU=Computers,OU=AG,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "AROTC*"
        OU = "OU=Computers,OU=AROTC,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "AUT*"
        OU = "OU=Transportation,OU=CASA,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "AVF*"
        OU = "OU=Transportation,OU=CASA,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "AVT*"
        OU = "OU=Transportation,OU=CASA,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "TEC*"
        OU = "OU=Transportation,OU=CASA,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "COB*"
        OU = "OU=Computers,OU=COB,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "?REHN*"
        OU = "OU=Computers,OU=COB,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "AROTC*"
        OU = "OU=Computers,OU=AROTC,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "COEHS*"
        OU = "OU=COEHS,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "CCNTR*"
        OU = "OU=Computers,OU=Clinical Center,OU=COEHS,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "COLA*"
        OU = "OU=Computers,OU=COLA,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "adallyn*"
        OU = "OU=Computers,OU=COLA,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "COS*"
        OU = "OU=COS,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "Chem*"
        OU = "OU=COS,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "Math*"
        OU = "OU=COS,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "Zoo*"
        OU = "OU=COS,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "GEOL*"
        OU = "OU=COS,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "Phys*"
        OU = "OU=COS,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "PLB*"
        OU = "OU=COS,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "Micro*"
        OU = "OU=COS,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "CRC*"
        OU = "OU=Computers,OU=CRC,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "CWRL*"
        OU = "OU=Computers,OU=CWRL,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "ADM*"
        OU = "OU=EM,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "CLSS*"
        OU = "OU=EM,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "FAO*"
        OU = "OU=EM,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "CIE*"
        OU = "OU=EM,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "NSP*"
        OU = "OU=EM,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "REG*"
        OU = "OU=EM,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "TSS*"
        OU = "OU=EM,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "ENG*"
        OU = "OU=Computers,OU=COE,OU=ENG,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "FISH*"
        OU = "OU=Computers,OU=FISH,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "GRAD*"
        OU = "OU=Computers,OU=GRAD,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "HDST*"
        OU = "OU=Computers,OU=HDST,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "ICCI*"
        OU = "OU=Computers,OU=ICCI,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "AIS*"
        OU = "OU=Computers,OU=AIS,OU=IT,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "CLC*"
        OU = "OU=Computers,OU=CLC,OU=IT,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "ITDIR*"
        OU = "OU=Computers,OU=DIR OFFICE,OU=IT,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "MDV*"
        OU = "OU=Tablets,OU=MobileDawg,OU=IT,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "NWA*"
        OU = "OU=Computers,OU=NWA Support,OU=IT,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "*-REL"
        OU = "OU=Print Stations,OU=CWPS,OU=SalukiTech,OU=IT,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "IT-SIS*"
        OU = "OU=Computers,OU=SIS,OU=IT,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "TC-*"
        OU = "OU=Computers,OU=Telephone Service,OU=IT,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "ITNET*"
        OU = "OU=Computers,OU=Network Engineering,OU=Wham,OU=IT,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "LAW*"
        OU = "OU=Computers,OU=LAW,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "LIB*"
        OU = "OU=Computers,OU=LIB,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "MCMA*"
        OU = "OU=Computers,OU=MCMA,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "OSPA*"
        OU = "OU=Computers,OU=OSPA,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "PSPPI*"
        OU = "OU=Computers,OU=PSPPI,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "PVC*"
        OU = "OU=Computers,OU=Anthony,OU=PVC,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "APAP*"
        OU = "OU=Computers,OU=APAP,OU=PVC,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "CTE*"
        OU = "OU=Computers,OU=CTE,OU=PVC,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "EC-*"
        OU = "OU=Computers,OU=SIUEC,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "AS*"
        OU = "OU=Computers,OU=AS,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "BUR*"
        OU = "OU=Computers,OU=BUR,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "CEHS*"
        OU = "OU=Computers,OU=CEHS,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "DPS*"
        OU = "OU=Computers,OU=DPS,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "HR*"
        OU = "OU=Computers,OU=HR,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "HSG*"
        OU = "OU=Computers,OU=HSG,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "PC*"
        OU = "OU=Computers,OU=PC,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "PSO*"
        OU = "OU=Computers,OU=PSO,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "PSP*"
        OU = "OU=Computers,OU=PSP,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "RBE*"
        OU = "OU=Computers,OU=RBE,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "RSS*"
        OU = "OU=Computers,OU=RSS,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "SC-*"
        OU = "OU=Computers,OU=SC,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "SHS-*"
        OU = "OU=Computers,OU=SHS,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "TON-*"
        OU = "OU=Computers,OU=TON,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "UC-*"
        OU = "OU=Computers,OU=UC,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "FIN*"
        OU = "OU=Computers,OU=VCAF,OU=Administration,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "ATH*"
        OU = "OU=Computers,OU=Athletics,OU=Chancellor,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "CHANC*"
        OU = "OU=Computers,OU=Chanc,OU=Chancellor,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "OERD*"
        OU = "OU=Computers,OU=OERD,OU=Chancellor,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "DAR*"
        OU = "OU=Computers,OU=DAR System,OU=Development and Alumni Relations,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "GENC*"
        OU = "OU=Computers,OU=GENC,OU=Presidents Office,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "PRES*"
        OU = "OU=Computers,OU=Pres,OU=Presidents Office,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "NAT*"
        OU = "OU=Computers,OU=Nurse Aid Testing Center,OU=OERD,OU=Chancellor,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "CLP-*"
        OU = "OU=Computers,OU=CLP,OU=SalukiTech,OU=IT,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "SH-*"
        OU = "OU=Computers,OU=Service Center,OU=SalukiTech,OU=IT,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    @{
        Filter = "UCS-*"
        OU = "OU=Computers,OU=UCS,OU=EM,OU=Academic Affairs,DC=ad,DC=siu,DC=edu"
        }
    )

#Get all computers in Computers container
$computers= get-adcomputer -filter * -searchbase $computerOU
foreach ($computer in $computers) {
    $guido= $computer.ObjectGUID
    $name= $computer.Name
    foreach($entry in $csv){
        if($computer.Name -like ($entry.Dept + "-*")){
            Move-ADObject -Identity $guido -TargetPath $entry.OU
            $alert = "$Name moved to $OU"
            Add-TeamsAlert -alert $alert
        }
    }    
}
$computers= get-adcomputer -filter * -searchbase $computerOU
foreach ($computer in $computers) {
    $guido= $computer.ObjectGUID
    $name= $computer.Name
    foreach ($filter in $filterArray) {
        if ($Computer.Name -like $filter.Filter) {            
            $ou= $filter.OU            
            Move-ADObject -Identity $guido -TargetPath $OU
            Set-ADComputer -Identity $guido -Description "ಠ_ಠ This computer was moved from the default computers OU by a script because somebody didn't create the computer object first."
            $alert = "$Name moved to $OU"
            Add-TeamsAlert -alert $alert
        }       
    }
}
#check again for those without a corresponding filter
$leftovers = Get-ADComputer -filter * -SearchBase $computerOU
foreach ($leftover in $leftovers) {
    $guido = $leftover.ObjectGUID
    $name = $leftover.Name
    Move-ADObject -Identity $guido -TargetPath $Shame
    Set-ADComputer -Identity $guido -Description "This computer was not named according to the current naming convention standards. If you believe this is in error, please put in a ticket to Enterprise Systems."
    $alert = "$Name moved to The OU of Shame for not being named properly."
    Add-TeamsAlert -alert $alert
    }  


#disable and delete computers older than the set date and matching a particular name
$basics= @(
    'Desktop*'
    'SIU*'
    'ws*'
    'dhcp*'
    'MININT*'
    )
foreach ($basic in $basics) {
    get-adcomputer -filter {name -like $basic} -SearchBase $Shame | ForEach-Object {
        $dn = $_.DistinguishedName
        $name = $_.Name
        if($_.Enabled) {
            try{
                Disable-ADAccount $dn -confirm:$false -erroraction stop
                Set-ADComputer -Identity $_.ObjectGUID -Description "This computer account has been disabled and will be deleted on $deleteon if not re-enabled and moved. Next time make a name unique to the department."
                $alert = "Disabled $name for being way too basic. Will be deleted on $deleteon"
                Add-TeamsAlert -alert $alert
            }
            catch {
                $alert = "Disable failed for $name, it's still WAY basic but we can't do anything about it now I guess."
                Add-TeamsAlert -alert $alert
            }
        }
    }

    get-adcomputer -Filter {Created -lt $time -and Name -like $basic} -searchbase $shame | Foreach-object {
        if(!$_.Enabled) {
            try {
                Remove-adobject $dn -confirm:$false -erroraction stop
	            $alert = "Removed $name, it's in a better place now."
                Add-TeamsAlert -alert $alert
            }
            catch {
	            $alert = "Remove failed for $dn, maybe aim for the head next time."
                Add-TeamsAlert -alert $name
            }
        }
    }
}
