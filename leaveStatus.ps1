param($empID,$empLU,$dept,$jobTitle,$office,$userID,$leaveStatus,$time)
    $empID="%empID%"
        $empLU=Get-ADUser -Filter {employeeID -eq $empID} -Properties *
            $dept=$empLU | Select-Object -ExpandProperty department
            $jobTitle=$empLU | Select-Object -ExpandProperty title
            $office=$empLU | Select-Object -ExpandProperty physicalDeliveryOfficeName
            $userID=$empLU | Select-Object -ExpandProperty SamAccountName
    $leaveStatus="%leaveStatus%"
    $time="%EffectiveDate%"

IF($leaveStatus -eq 'Returning'){
    Set-ADUser -Identity $userID -Description $null
    $empLU | Enable-ADAccount
}elseIF($leaveStatus -eq 'On Leave'){
    Set-ADUser $empLU -add @{description="On Leave ($time)"}
    Disable-ADAccount $empLU
}

<#---------------------------------------------------------------
|Create JSON array that will be parsed by Power Automate Desktop|
---------------------------------------------------------------#>
$JSON=[pscustomobject]@{
    dept=$dept
    jobTitle=$jobTitle
    location=$office
}
$JSON | ConvertTo-Json -Compress | Write-Output
