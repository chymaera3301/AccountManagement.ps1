<#--------------------------------------------------------------------------
|Gather terminated emplpoyee details, then disable and moved to Disabled OU|
--------------------------------------------------------------------------#>
param($empLU,$eA10,$email,$ext,$DID,$Groups,$jobTitle,$NAMEfull,$office,$OU)
    $empLU = Get-ADUser -Filter {employeeID -eq "%empID%"} -Properties *
        $eA10 = $empLU.extensionAttribute10
        $email = $empLU.userPrincipalName
        $ext = $empLU.extensionAttribute13
        $desc = $empLU.description
        $DID = $empLU.ipPhone
        $Groups = Get-ADPrincipalGroupMembership $empLU | Where-Object {$_.Name -ne '*******'}
        $jobTitle = $empLU.title
        $mngrID = $empLU.extensionAttribute6
        $NAMEfull = $empLU.Name
        $office = $empLU.physicalDeliveryOfficeName
    $OU = "*******"

IF($Groups){                                                         #Remove Local AD Global Groups, IF they exist
    Remove-ADPrincipalGroupMembership $empLU -MemberOf $Groups -Confirm:$false
}
Set-ADUser $empLU -clear `
    extensionAttribute3,
    extensionAttribute5,
    extensionAttribute6,
    extensionAttribute7,
    extensionAttribute8,
    extensionAttribute12,
    extensionAttribute13,
    extensionAttribute14,
    extensionAttribute15,
    facsimileTelephoneNumber,
    homePhone,
    ipPhone,
    l,
    legacyExchangeDN,
    manager,
    mail,
    mailNickname,
    MsExchMailboxGuid,
    MsExchRecipientDisplayType,
    MsExchRecipientTypeDetails,
    physicalDeliveryOfficeName,
    proxyAddresses,
    telephoneNumber

Set-ADUser $empLU -replace @{
    description = "Terminated '%termDate%'"
    extensionAttribute9 = 'Termed'
}

#Delay to ensure attributes synce with Entra ID (Azure AD)
IF($office -eq '*******'){
    Start-Sleep -Seconds 600
}

Start-Sleep -Seconds 60
Disable-ADAccount $empLU
$empLU | Move-ADObject -TargetPath $OU

<#--------------------------------------------------------------------------------------------------------------------------------------------
|Create JSON array that will be parsed by Power Automate Desktop for passing data to an email for Help Desk and users in generated email list|
--------------------------------------------------------------------------------------------------------------------------------------------#>
$JSON = [pscustomobject]@{
    initials = $eA10
    email = $email
    ext = $ext
    desc = $desc
    DID = $DID
    jobTitle = $jobTitle
    mngrID = "$mngrID@*******"
}
$JSON | ConvertTo-Json -Compress | Write-Output
