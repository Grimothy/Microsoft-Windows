#   THIS SCRIPT WILL CHECK THE STATUS OF DHCP SCOPES RUNNING AND CHECK PREVIOUS SCOPE STATE.
#   IF A SCOPE THAT WAS PREVIOUSLY ACTIVE BECOMES INACTIVE, THE SCRIPT WILL NOTIFY ADMINS VIA EMAIL

# Define the DHCP server to monitor
$dhcpServer = "$env:COMPUTERNAME"

# Define the email parameters
$smtpServer = "relayhost.hhsnjsmtp.com"
$smtpFrom = "DHCPAlert-$env:COMPUTERNAME@hhsnj.org"
$smtpTo = "Infrastructure@hhsnj.org"

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
        Send-MailMessage -To $smtpTo -From $smtpFrom -Subject $subject -Body $body -SmtpServer $smtpServer
    }
    
    # Write the current status to the log file
    Add-Content -Path $logFile -Value "$scopeId $scopeStatus"
}

#Run Log clean up

# Read the contents of the text file
$content = Get-Content $logFile

# Select the last 20 lines
$newContent = $content | Select-Object -Last 20

# Overwrite the original file with the last 20 lines
$newContent | Set-Content $logFile
