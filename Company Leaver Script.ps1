# Function to validate user input
function Validate-UserInput {
    param (
        [string]$input
    )
    # Check if the input contains an asterisk
    if ($input -match "\*") {
        return $false
    }
    return $true
}

While ($true) {
    # Prompt the user to enter the user's logon name interactively
    $user = Read-Host "Enter the user's logon name (e.g., firstname.surname)"

    # Validate the user input
    if (-not (Validate-UserInput -input $user)) {
        Write-Host "Invalid input: User logon name cannot contain '*'"
        exit
    }

    # Check if the user exists in AD
    $usercheck = Get-ADUser -Filter {SamAccountName -eq $user}
    if ($usercheck) {
        Write-Host "User '$user' found in Active Directory." -ForegroundColor Green
        break
    } else {
        Write-Host "User '$user' not found in Active Directory. Please try again." -ForegroundColor Yellow
    }
}

while ($true) {
    # Prompt the user to enter the display name interactively
    $displayname = Read-Host "Enter the user's display name (e.g., Firstname Surname)"

    # Check if the display name exists in AD
    $displaycheck = Get-ADUser -Filter {DisplayName -eq $displayname}

    if ($displaycheck) {
        Write-Host "User '$displayname' found in Active Directory." -ForegroundColor Green
        break
    } else {
        Write-Host "User '$displayname' not found in Active Directory. Please try again." -ForegroundColor Yellow
    }
}
# Prompt the user to enter a note for the telephoneNotes attribute
$note = Read-Host "Enter request note (e.g., 'Ticket Number - Leaver')"

# Get the existing telephoneNotes, these notes are found under Attribute editor/info
$currentNotes = (Get-ADUser -Identity $user -Properties info).info

# Concatenate the new note with the existing notes, adding a separator if necessary
if ($currentNotes) {
    $updatedNotes = "$currentNotes; $note"
} else {
    $updatedNotes = $note
}

# Update the telephoneNotes attribute with the concatenated notes
Set-ADUser -Identity $user -Replace @{info=$updatedNotes}

# Confirmation prompt
$confirmation = Read-Host "Are you Sure You Want To Proceed with removing $($user)?"
if ($confirmation -eq 'y') {
    # Proceed
    if (Get-ADUser -Filter {samaccountname -eq $user}) {
        # Disable the user account
        Disable-ADAccount -Identity $user

        # Display the account status
        Write-Host "User is disabled. True or false."
        $userStatus = Get-ADUser -Identity $user -Properties * | Select-Object -ExpandProperty enabled
        Write-Host $userStatus

        # Inform about removing group memberships
        Write-Host "`nRemoving groups user is a member of"

        # List groups the user is a member of
        $groups = Get-ADPrincipalGroupMembership -Identity $user
        $groups | ForEach-Object { $_.Name } | ForEach-Object { Write-Host $_ }

        # Remove the user from each group
        $groups | ForEach-Object {
            Remove-ADGroupMember -Members $user -Confirm:$False -Identity $_.SID
        }

        # Add the user back to "Domain Users" group
        Add-ADGroupMember -Members $user -Identity "Domain Users"

        # Update msExchHideFromAddressLists attribute
        Set-ADUser -Identity $user -Replace @{msExchHideFromAddressLists=$true}

        # Update mailNickname attribute
        Set-ADUser -Identity $user -Replace @{mailNickname="$($user)@domain.com"}

        # Remove the manager
        Set-ADUser -Identity $user -manager $null

        # Move user to Disabled users
        # Get the DistinguishedName for a user
        $DistinguishedName = (Get-ADUser -Filter {SamAccountName -eq $user}).DistinguishedName
        Write-Host "`nDistinguishedName: $DistinguishedName"
        # ENter the OU path where the user will be moved
        Move-ADObject -Identity $DistinguishedName -TargetPath "OU=Disabled Users,OU=Users,OU=,DC=,DC="

         # Connect to exhange online and move mailbox to shared
        Write-Host "`nPlease log into your 365 Admin Account."
        Connect-ExchangeOnline
        Set-Mailbox -Identity $displayname -type Shared
        
    } else {
        Write-Host "No AD account found"
    }
    
}

Pause