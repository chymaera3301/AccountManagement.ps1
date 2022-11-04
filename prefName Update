param($pName, $prefName, $sn, $lastName, $displayName)
    $empID='%employeeID%'
    $pName='%preferredName%'
        $prefName=$pName.substring(0,1).toupper()+$pName.substring(1).tolower()
    $sn='%lastName%'
        $lastName=$sn.substring(0,1).toupper()+$sn.substring(1).tolower()
            $displayName="$prefName $lastName"

Get-ADUser -Filter {employeeID -eq $empID} | Set-ADUser -replace @{displayName=$displayName;givenName=$prefName}
