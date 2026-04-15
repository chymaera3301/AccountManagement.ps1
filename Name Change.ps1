<#========================================================================================================
|Part One                                                                                                |
|-Changing only the Display Name. Does not update username and email                                     |
|-Runs during business hours and an email is sent out to the user and manager(s) containing the new login|
========================================================================================================#>

param($empID, $empLU, $dn, $emailO, $gnO, $snO, $userIDo, $Dept, $office, $OUa, $OU, $gn, $sn, $pn, $displayName, $middle, $NAMEfull)
    $empID='%empID%'
        $empLU=Get-ADUser -Filter {employeeID -eq $empID} -Properties *
            $dn = $empLU.distinguishedName
            $eA10 = $empLU.extensionAttribute10
            $emailO = $empLU.UserPrincipalName
            $gnO=$empLU.givenName
            $snO=$empLU.surName
            $userIDo=$empLU.SAMAccountName
    $Dept = "%dept%"
        $Office = Switch($Dept){                          #Converts HR provided location to Admin if Home Office, for use with Dynamic rules in Entra
                '*******'{'*******'}
                '*******'{'*******'}
                '*******'{'*******'}
                default{"%variable%"}
            }
        $OUa = Switch($Dept){                             #Converts HR provided Department to what's listed in Local AD
                '*******'{'*******'}
                '*******'{'*******'}
                '*******'{'*******'}
                default{$Dept}
            }
            $OU = IF($Office -eq 'Admin'){              #Adjusted OU path for Store or Home Office
                    "$OUa*******"
                }else{
                    "$Office*******"
                }
    $gn="%NAMEfirst%"                                                                                   #ex. Johnny
        $gn=$gn.substring(0,1).toUpper()+$gn.substring(1).toLower()                                     #Ensures first initial is uppercase
            $gnScrb=$gn -replace '[^\p{L}\p{Nd}/`//-/_/!]', ''                                          #Removes special characters
    $sn="%NAMElast%"                                                                                    #ex. appleseed / apple-seed / apple seed
        $sn1,$sn2=$sn -split '[- ]' | forEach-Object{                                                   #Split IF surname contains Hyphen or Space
            $_.Substring(0,1).ToUpper()+$_.Substring(1).ToLower()                                       #Uppercase first character
        }
        Switch($sn){                                                                                    #Combine after setting first character to uppercase
            {$sn -like '* *'}{$sn = $snSplit -join '-'}                                                 #ex. Apple Seed
            {$sn -like '*-*'}{$sn = $snSplit -join ' '}                                                 #ex. Apple-Seed
            Default{$sn = $snSplit}                                                                     #ex. AppleSeed
        }
        $snScrb=$sn -replace '[^\p{L}\p{Nd}/`//-/_/!]', ''
    $middle=IF("%NAMEmiddle%"){"%NAMEmiddle%".toUpper()[0]}                                             #Grab only first initial and uppercase, if exists
        $NAMEfull=IF($middle){"$gn $middle $sn"                                                         #ex. Johnny S AppleSeed
                }else{"$gn $sn"                                                                         #ex. Johnny AppleSeed
                }
    $pn="%prefName%"                                                                                    #ex. John
        $pn=$pn.substring(0,1).toUpper()+$pn.substring(1).toLower()                                     #Ensures first initial is uppercase
            $pnScrb=$pn -replace '[^\p{L}\p{Nd}/`//-/_/!]', ''                                          #Removes special characters
                $displayName="$pn $sn"                                                                  #ex. John Apple-Seed
    $mngrID=IF("%MngrID%"){"%MngrID%"                                                                   #IF Manager Emp ID is Provided assign variable
            }elseIF($office -ne '*******'){                                                             #IF Manager Emp ID is not provided and employee is a Retail employee
                Get-ADUser -Filter "title -eq '*******'" -AND -SearchBase $OU | Select-Object -ExpandProperty employeeID
            }
        $mngrLU=Get-ADUser -Filter {employeeID -eq $mngrID} -Properties *

Set-ADUser $empLU -replace @{
    displayName=$displayName;
    givenName=$pn;
    middleName=$middle;
    sn=$sn
}
Rename-ADObject -Identity $dn -NewName $NAMEfull
$empLU = Get-ADUser -Filter {employeeID -eq $empID} -Properties *

<#-------------------------------------------------------------------------------------
|Generate multiple possible userID's, in case provided userID is not valid or provided|
-------------------------------------------------------------------------------------#>
$userIDs = @()                                                  #Set/Clear Array. Ordered from least to most preferred
IF($sn2){
    $userIDs += $pnScrb+'.'+$middle+'.'+($sn1[0]+$sn2[0])       #ex. John.S.AS
    $userIDs += $pnScrb+'.'+($sn1[0]+$sn2[0])                   #ex. John.AS
}else{
    $userIDs += $pnScrb+'.'+$middle+'.'+$snScrb[0]              #ex. John.S.A
    $userIDs += $pnScrb+'.'+$snScrb[0]                          #ex. John.A
}
$userIDs += $pnScrb[0]+'.'+$middle+'.'+$snScrb                  #ex. J.S.AppleSeed
$userIDs += $pnScrb[0]+'.'+$snScrb                              #ex. J.AppleSeed
$userIDs += $pnScrb+'.'+$middle+'.'+$snScrb                     #ex. John.S.AppleSeed
IF($userID){
    $userIDs += $userID                                         #ex. John.AppleSeed
}else{
    $userIDs += $pnScrb+'.'+$snScrb                             #ex. John.AppleSeed
    $hrNum = 1
}
forEach($user in $userIDs){
    $user = $user -replace '\.\.', '.'                          #Replace double dots ".." with a single dot "."
    $proxyCheck = "*$user*"
    $proxy = Get-ADUser -Filter {proxyAddresses -like $proxyCheck} -Properties *
        $adLU1 = $proxy.employeeID
        $adLU2 = $proxy.enabled
        $adLU3 = $proxy.SamAccountName
    IF($user.length -le 20){
        $hrNum = Switch($hrNum){                    #Provided UserID/Email check
            1{1}                                    #UserID/Email not provided
            2{2}                                    #Exceeds 20 characters
            3{3}                                    #Duplicate process
            4{4}                                    #UserID/Email already in use
            default{0}                              #No issues
        }
        IF($adLU2){
            IF($adLU1 -eq $empID -AND $user -eq $adLU3 -AND $hrNum -eq 0){          #Provided UserID in use by active account, sharing Emp ID (Same User)
                $userID = $empLU.SAMAccountName                                     #Set variable, SAMAccountName - Duplicate Process
                $email = $empLU.userPrincipalName                                   #Set variable, Email|mail|UPN - Duplicate Process
                $hrNum = 3
            }elseIF($adLU1 -ne $empID -AND $user -eq $adLU3 -AND $hrNum -eq 0){     #Provided UserID in use by active account, not sharing Emp ID (Different User)
                $hrNum = 4
                $hrFail = $adLU1                                                    #Grab employeeID of active user, added to conflict notice
            }
        }else{
            $userID = $user                                                         #Set variable, SAMAccountName
            $email = "$userID@*******"                                              #Set variable, Email|mail|UPN
        }
    }elseIF($user.length -gt 20 -AND $user -eq $adLU3 -AND $hrNum -eq 0){
        $hrNum = 2
    }
}
<#-------------------------------------------------------------------------
|Gather emails for BackOffice employees and Store/Home Office Dept Manager|
-------------------------------------------------------------------------#>
$deptMgrs = @(                                                      #Create array of standard job titles to gather emails for
    '*******',
    '*******',
    '*******',
    '*******',
    '*******'
)
$deptMgrs += Switch($dept){                                         #Add additional titles to array based on the employee's department
                'Clothing'{'*******'}
                'Hardside'{'*******'}
                'Machine Shop'{'*******'}
                'Shop'{'*******'}
                'Sporting Goods'{'*******','*******'}
            }
IF($Office -ne 'Admin'){                                            #IF not an Admin / Home Office employee, add the gathered emails
    $backOffice = (
        $deptMgrs | ForEach-Object{
            Get-ADUser -Filter "title -eq '$_'" -SearchBase $OU | Select-Object -ExpandProperty UserPrincipalName
        }
    ) -join ';'
    IF($jobTitle -contains 'Manager'){
        $backOffice += ';' + $mngrLU.UserPrincipalName
    }
}else{                                                              #IF is an Admin / Home Office employee, only add provided manager's email
    $backOffice = $mngrLU.UserPrincipalName
}
<#---------------------------------------------------------------------------------------------------------------------------------------
|If the HR provided Username was too long or already in use, generate a note that will be emailed to HR providing generated userID/email|
---------------------------------------------------------------------------------------------------------------------------------------#>
$hrNotif = Switch($hrNUm){
    0{''}
    1{'Email not provided'}
    2{'Provided UserID exceeds 20 characters'}
    3{'Duplicate'}
    4{"Email in use by active account, $hrFail"}
}
<#--------------------------------------------------------------------------------------------------------------------------------------------
|Create JSON array that will be parsed by Power Automate Desktop for passing data to an email for Help Desk and users in generated email list|
--------------------------------------------------------------------------------------------------------------------------------------------#>
$JSON=[pscustomobject]@{
    emailN=$email
    eMGR=$backOffice
    hrNotif=$hrNotif
    hrNum=$hrNum
    prevEmail=$emailO
    prevFirstName=$gnO
    prevLastName=$snO
    prevUserID=$userIDo
    userID=$userID
    d365=$eA10
}
$JSON | ConvertTo-Json -Compress | Write-Output

<#=====================================================================================
|Part two                                                                             |
|-Updates username and set proxies                                                    |
|-Runs after business hours to prevent access hours while the employee is not working |
=====================================================================================#>

param($email,$empID,$empLU,$DID,$eA10,$ext,$mngrID,$Office,$3cx,$userIDo,$userID)
    $email='%email%'
    $empID='%empID%'
        $empLU=Get-ADUser -Filter {employeeID -eq $empID} -Properties *
            $DID=IF($Office -eq '*******'){$empLU.extensionAttribute13}
            $eA10=$empLU.extensionAttribute10
            $ext=IF($Office -eq '*******'){$empLU.ipPhone}
            $mngrID=$empLU.extensionAttribute6
            $Office=$empLU.office
                $3cx=IF($Office -eq '*******'){
                        "Update name on extension (*******) | Ext: $ext | DID: $DID"
                    }elseIF($Dept -like '*******' -OR $Dept -eq '*******' -OR $Dept -eq '*******'){
                        'Update name on extension (*******)'
                    }else{''}
            $userIDo=$empLU.SamAccountName
    $userID='%userID%'

<#---------------------------------
|Update UserID, Email, and Proxies|
---------------------------------#>
Set-ADUser $empLU -replace @{
    mail=$email;
    mailNickname=$userID;
    sAMAccountName=$userID;
    targetAddress="*******$userID@*******";
    userPrincipalName=$email
}
Set-ADUser $empLU -remove @{                                    #Remove current primary proxy
    ProxyAddresses="*******$userIDo@*******"
}
Set-ADUser $empLU -add @{                                       #Set new primary proxy, set previous as secondary
    ProxyAddresses="*******$email,*******$userIDo@*******" -split ","
}

<#---------------------------------------------------------------
|Create JSON array that will be parsed by Power Automate Desktop|
---------------------------------------------------------------#>
$JSON=[pscustomobject]@{
    eagleID=$eA10
    ext=$3cx
    mngrID=$mngrID
}
$JSON | ConvertTo-Json -Compress | Write-Output
