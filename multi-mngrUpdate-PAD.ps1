$JSON = '%JSONinput%'                   #List of EmpID's and  MngrID's, convert from XLSX to JSON
$data = ConvertFrom-Json $JSON          #Convert JSON to array
$list = @()                             #Create a blank Array (Occasionally would add to object from prior run)

forEach($user in $data){                #forEach row/user
    $empID = $user.empID
    $mngrID = $user.mngrID

    IF($mngrID){                                                                #Some users don't have a Manager, only runs if mngrID exists
        $empLU = Get-ADUser -Filter {employeeID -eq $empID} -Properties *       #Set Employee Object
        $mngrLU = Get-ADUser -Filter {employeeID -eq $mngrID} -Properties *     #Set Manager Object
        $eA9 = $empLU.extensionAttribute9                                       #Set Term status 

        IF($eA9 -ne 'Termed'){                                      #IF account is enabled
            Set-ADUser $empLU -Replace @{                           #Update Manager info in Employee's account
                extensionAttribute6=$mngrLU.sAMAccountName          #Update Manager's sAMAccountName/userID in Employee's account
                manager=$mngrLU.distinguishedName                   #Update Manager's distinguishedName/Path in Employee's account
            }

            $list+=[pscustomobject]@{                               #Create JSON object for each run, will be converted to CSV in Web Flow for tracking
                birthDate = $empLU.extensionAttribute1              #Set Employee sAMAccountName/birthdate
                empID = $empID                                      #Set Employee ID number
                firstName = $empLU.givenName                        #Set Employee sAMAccountName/givenName
                lastName = $empLU.sn                                #Set Employee sAMAccountName/sn
                userID = $empLU.sAMAccountName                      #Set Employee sAMAccountName/userID
                hireDate = $empLU.extensionAttribute2               #Set Employee sAMAccountName/hireDate
                title = $empLU.title                                #Set Employee sAMAccountName/jobTitle
                dept = $empLU.department                            #Set Employee sAMAccountName/dept
                newMngrID = $mngrID                                 #Set new Manager ID
                newMngr = $mngrLU.sAMAccountName                    #Set new Manager sAMAccountName/userID
                priorMngr = $empLU.extensionAttribute6              #Set prior Manager sAMAccountName/userID
                location = $empLU.physicalDeliveryOfficeName        #Set Employee Location
            }
        }
    }
    $empID = $null
    $mngrID = $null
}

$list | ConvertTo-Json -Compress | Write-Output             #Output JSON object of every account ran
