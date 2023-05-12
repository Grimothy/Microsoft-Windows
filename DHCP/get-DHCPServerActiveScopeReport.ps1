#$Credential = Get-Credential
#$Credential.Password | ConvertFrom-SecureString | Set-Content "C:\temp\Password.txt"

# Import the encrypted password from the file
#$EncryptedPassword = Get-Content "C:\temp\Password.txt" | ConvertTo-SecureString

# Create a credential object using the username and encrypted password
#$Credential = New-Object System.Management.Automation.PSCredential($Credential.UserName, $EncryptedPassword)

# Define the DHCP server to monitor
$dhcpServer = "$env:COMPUTERNAME"

# Define the email parameters
$smtpServer = "smtp.office365.com"
$smtpPort = 587
$smtpFrom = "cj@melillodemo.com"
$smtpTo = "Charlesjcoulter@gmail.com"

# Define the log file to store the status
$logFile = "C:\DHCP_Log.txt"

# Get the current date and the date from 2 hours ago
$currentDate = Get-Date

# Loop through all the DHCP scopes on the server
Get-DhcpServerv4Scope -ComputerName $dhcpServer | ForEach-Object {
    # Get the scope ID and status
    $scopeId = $_.ScopeId
    $scopeStatus = $_.State
    
    # Read the previous status from the log file
    $previousStatus = "Inactive"
    if (Test-Path $logFile) {
        $previousStatus = Get-Content $logFile | Select-String -Pattern "^$scopeId\s+" | ForEach-Object { $_.ToString().Split(" ")[1] }
    }
    
    # Compare the current and previous status
    if ($scopeStatus -eq "Inactive" -and $previousStatus -ne "Inactive") {
        # Send an email notification if the scope is now inactive
        $subject = "DHCP Scope $scopeId is inactive"
        $body = "The DHCP scope $scopeId is currently inactive as of $($currentDate.ToString('yyyy-MM-dd HH:mm:ss'))."
        Send-MailMessage -To $smtpTo -From $smtpFrom -Subject $subject -Body $body -SmtpServer $smtpServer -Port $smtpPort -Credential $Credential -UseSsl
    }
    
    # Write the current status to the log file
    Add-Content -Path $logFile -Value "$scopeId $scopeStatus"
}