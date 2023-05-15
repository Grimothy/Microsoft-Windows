# Import the Active Directory module
Import-Module ActiveDirectory

# Retrieve a list of enabled users with email addresses
$EnabledUsers = Get-ADUser -Filter {Enabled -eq $true -and EmailAddress -notlike "healthmailbox*"} -Properties Name, PasswordLastSet, SamAccountName, EmailAddress

# Display the list of enabled users with email addresses
$EnabledUsers | Select-Object Name, PasswordLastSet, SamAccountName, EmailAddress

