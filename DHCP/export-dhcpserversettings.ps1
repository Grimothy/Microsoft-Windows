#This script will export the DHCP Server Settings (Not to be confused with the scopes). 
#This will only move Server Settings and will ignore moving scopes)

function export-dhcpserversettings {
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$true)]
        [string] $path #location where DHCP exports and backups will be saved C:\DHCP for example
    )

    #Create Directory Structure
    Write-Host -ForegroundColor Cyan "Creating directories for export and import"
    Start-Sleep -Seconds 2
    New-Item -ItemType Directory -Path $path
    Start-Sleep -Seconds 2
    
    #Get DHCP Servers in environment
    $dhcpserver = Get-DhcpServerInDC | Out-GridView -Title "Select DHCP for export" -PassThru
    #$scopes =  Get-DhcpServerv4Scope -ComputerName $dhcpserver.DnsName | Out-GridView -Title "Please select scopes" -PassThru
    $Sname = $dhcpserver.DnsName

 
    #Create additional directories for the scope options and DHCP backup location    
    Write-Host -ForegroundColor Cyan "Creating additional directories"
    Start-Sleep 2
    New-Item -ItemType Directory -Path "$path\Exports\$Sname\ServerOptionsOnly" -Verbose
    New-Item -ItemType Directory -Path "$path\Exports\$Sname\ServerOptionsOnly\backup" -Verbose

    
    #Export and import Server options
    Export-DhcpServer -ComputerName $dhcpserver.DnsName -File  "$path\Exports\$Sname\ServerOptionsOnly\$Sname.xml" -Verbose
    Import-DhcpServer -ServerConfigOnly -File "$path\Exports\$Sname\ServerOptionsOnly\$Sname.xml" -BackupPath "$path\Exports\$Sname\ServerOptionsOnly\backup"-Verbose

    Write-Host -ForegroundColor Green "-------------------------------------"
    Write-Host -ForegroundColor Green "complete press any key to continue..."
    Write-Host -ForegroundColor Green "-------------------------------------"
    Read-Host

   
}
