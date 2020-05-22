$csv = import-csv .\delete.csv
foreach($line in $csv){get-aduser -identity $line.Name | Move-ADObject -TargetPath 'OU=AD Only to Delete,OU=Roles,OU=IDM,DC=ad,DC=siu,DC=edu'}