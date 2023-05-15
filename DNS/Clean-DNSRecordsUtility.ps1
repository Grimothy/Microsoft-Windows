
$LogPath = "$env:SystemDrive\DNS_CleanUp_Util\logs\$(get-date -Format MM-dd-yyyy-hh-mm-ss)__log.txt"
$host.UI.RawUI.BackgroundColor = "black" 
Start-Transcript -Path $LogPath  -Append -Force
#$ErrorActionPreference = 'SilentlyContinue'

#Install required Powershell Module
if(-not (Get-Module PSMenu -ListAvailable)){
    Write-Host -ForegroundColor Magenta "PSMenu module not installed. Performing installation now..."
    Install-Module PSMenu -Scope CurrentUser -Force
    }

    function Remove-DynamicDNSRecord{
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$True,HelpMessage="Please enter a name for the job and report generated by this script")]
        [string] $JobReportName, # Name for the job and report generated by this script
        [string] $Path = "$env:SystemDrive\DNS_CleanUp_Util\DNS Record Removal Jobs DYNAMIC\$JobReportName", #location where DNS remove records and reports are stored. 
        [Parameter(Mandatory=$true)]
        [int] $days, # Used to located records older than the value specified
        [Parameter(Mandatory=$true,HelpMessage="With Caution specifies whether or not to prompt the user for the deletion of EACH AND EVERY DNS RECORD")]
        [ValidateSet('Yes','No')] # Specifies whether or not to prompt the user for the deletion of EACH AND EVERY DNS RECORD
        [string] $WithCaution
    )

    $ZoneSelect = Get-DnsServerZone | Out-GridView -PassThru -Title "Select the DNS Zone to Clean"
    $ZoneName = $ZoneSelect.ZoneName
    Write-Host -ForegroundColor Green "The DNS Zone $ZoneName has been selected"
    Start-Sleep -Seconds 2

    Write-Host -ForegroundColor Cyan "Creating directories for deleted records"
    Start-Sleep -Seconds 2
    New-Item -ItemType Directory -Path $Path
    
    "{0},{1},{2},{3},{4},{5},{6}" -F "HostName","RecordType","Type","TimeStamp","TimeToLive","RecordData","ZoneName" | Add-Content -Path "$Path\$(get-date -Format MM-dd-yyyy)__records.csv"
    Write-Host -ForegroundColor Green "Looking for DNS Records older than"$(Get-Date).AddDays(-$days)
    Start-Sleep -Seconds 5
    $recordsfound = Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType A | Where-Object {$_.timestamp -le $(Get-Date).AddDays(-$days)} | Out-GridView -PassThru
    $TotalItems=$recordsfound.count
    $CurrentItem = 0
    #$ErrorActionPreference = 'SilentlyContinue'
    If ($WithCaution -like "Yes") {
        Write-Host -ForegroundColor Yellow "With Caution option has been selected. You will be prompted to confirm every DNS record"
        $hit = 0
        Write-Host -ForegroundColor Yellow "Continuing with the deletion of DNS records"
        foreach ($i in $recordsfound) 
        {
            Write-Progress -Activity "Removing the Selected DNS A Records and PTR Records" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
            "{0},{1},{2},{3},{4},{5},{6}" -F $i.HostName, $i.RecordType, $i.Type,$i.TimeStamp,$i.TimeToLive,$i.RecordData.IPv4Address.IPAddressToString,$ZoneName |Add-Content -Path "$Path\$(get-date -Format MM-dd-yyyy)__records.csv"
            Write-Host -ForegroundColor Cyan $i.hostname will be deleted
            Write-Host -ForegroundColor Yellow "Deleting DNS record "$i.hostname" with IP Adress "$i.RecordData.IPv4Address.IPAddressToString
            Write-Host -ForegroundColor Cyan "=============================================="
            Remove-DnsServerResourceRecord -ZoneName $ZoneName -RRType A -Name $i.HostName -force
            $ReverseZones = Get-DnsServerZone | Where-Object {$_.IsReverseLookupZone -eq $true}
            $ReverseZonename = $ReverseZones.ZoneName
            foreach ($RZone in $ReverseZonename)
                {
                    $hostname = $i.hostname
                    $FQDNOPT2 = $i.HostName+"."+$zonename+"."
                    if ($(get-DnsServerResourceRecord -ZoneName $RZone -RRType Ptr).recorddata.ptrdomainname  -like "$FQDNOPT2" )
                    {
                        Write-Host -ForegroundColor Green "Found $FQDNOPT2 in $rzone!"
                        Start-Sleep -Seconds .25
                        $PrtRecord = Get-DnsServerResourceRecord -ZoneName $RZone | Where-Object {$_.recorddata.ptrdomainname -like "$FQDNOPT2"}
                        Remove-DnsServerResourceRecord -ZoneName $RZone -Name $PrtRecord.HostName -RRType Ptr -Force -Verbose
                        Write-Host ""
                        $hit++
                    }    
                }
            $CurrentItem++
            $PercentComplete = [int](($CurrentItem / $TotalItems) * 100)
        } 
        Write-Progress -Completed -Activity "Removing the Selected DNS A Records and PTR Records"
        Write-Host -ForegroundColor Green       "  Record Removal Report   "
        Write-Host -ForegroundColor Green       "=========================="
        Write-Host -ForegroundColor Yellow      "A records removed: "$($RecordsFound).count""
        Write-Host -ForegroundColor Magenta     "PRT records removed: "$hit""
        Pause
        Write-Host -ForegroundColor Green "Task Completed Returning to main menu"
        Start-Sleep -Seconds 2
        mainmenu   
    } else {
        $hit = 0
        Write-Host -ForegroundColor Yellow "Continuing with the deletion of DNS records"
        foreach ($i in $recordsfound) 
        {
            Write-Progress -Activity "Removing the Selected DNS A Records and PTR Records" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
            "{0},{1},{2},{3},{4},{5},{6}" -F $i.HostName, $i.RecordType, $i.Type,$i.TimeStamp,$i.TimeToLive,$i.RecordData.IPv4Address.IPAddressToString,$ZoneName |Add-Content -Path "$Path\$(get-date -Format MM-dd-yyyy)__records.csv"
            Write-Host -ForegroundColor Cyan $i.hostname will be deleted
            Write-Host -ForegroundColor Cyan "=============================================="
            Write-Host -ForegroundColor Yellow "Deleting DNS record "$i.hostname" with IP Adress "$i.RecordData.IPv4Address.IPAddressToString
            Remove-DnsServerResourceRecord -ZoneName $ZoneName -RRType A -Name $i.HostName -force
            $ReverseZones = Get-DnsServerZone | Where-Object {$_.IsReverseLookupZone -eq $true}
            $ReverseZonename = $ReverseZones.ZoneName
            foreach ($RZone in $ReverseZonename)
            {
                $hostname = $i.hostname
                $FQDNOPT2 = $i.HostName+"."+$zonename+"."               
                if ($(get-DnsServerResourceRecord -ZoneName $RZone -RRType Ptr).recorddata.ptrdomainname  -like "$FQDNOPT2" )
                {
                    Write-Host -ForegroundColor Green "Found $FQDNOPT2 in $rzone!"
                    Start-Sleep -Seconds .25
                    $PrtRecord = Get-DnsServerResourceRecord -ZoneName $RZone | Where-Object {$_.recorddata.ptrdomainname -like "$FQDNOPT2"}
                    Remove-DnsServerResourceRecord -ZoneName $RZone -Name $PrtRecord.HostName -RRType Ptr -Force -Verbose 
                    Write-Host ""
                    $hit++    
                }    
            }
            $CurrentItem++
            $PercentComplete = [int](($CurrentItem / $TotalItems) * 100)
        } 
        Write-Progress -Completed -Activity "Removing the Selected DNS A Records and PTR Records"
        Write-Host -ForegroundColor Green    "  Record Removal Report   "
        Write-Host -ForegroundColor Green   "=========================="
        Write-Host -ForegroundColor Yellow      "A records removed: "$($RecordsFound).count""
        Write-Host -ForegroundColor Magenta     "PRT records removed: "$hit""
        Pause
        Write-Host -ForegroundColor Green "Task Completed Returning to main menu"
        Start-Sleep -Seconds 2
        mainmenu
    }
}

function Remove-STATICDNSRecord{
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$True,HelpMessage="Please enter a name for the job and report generated by this script")]
        [string] $JobReportName, # Name for the job and report generated by this script
        [string] $Path = "$env:SystemDrive\DNS_CleanUp_Util\DNS Record Removal Jobs DYNAMIC\$JobReportName", #location where DNS remove records and reports are stored. 
        [Parameter(Mandatory=$true)]
        [int] $days, # Used to located records older than the value specified
        [Parameter(Mandatory=$true,HelpMessage="With Caution specifies whether or not to prompt the user for the deletion of EACH AND EVERY DNS RECORD")]
        [ValidateSet('Yes','No')] # Specifies whether or not to prompt the user for the deletion of EACH AND EVERY DNS RECORD
        [string] $WithCaution
    )

    $ZoneSelect = Get-DnsServerZone | Out-GridView -PassThru -Title "Select the DNS Zone to Clean"
    $ZoneName = $ZoneSelect.ZoneName
    Write-Host -ForegroundColor Green "The DNS Zone $ZoneName has been selected"
    Start-Sleep -Seconds 2

    Write-Host -ForegroundColor Cyan "Creating directories for deleted records"
    Start-Sleep -Seconds 2
    New-Item -ItemType Directory -Path $Path
    
    "{0},{1},{2},{3},{4},{5},{6}" -F "HostName","RecordType","Type","TimeStamp","TimeToLive","RecordData","ZoneName" | Add-Content -Path "$Path\$(get-date -Format MM-dd-yyyy)__records.csv"
    Write-Host -ForegroundColor Green "Looking for DNS Records older than"$(Get-Date).AddDays(-$days)
    Start-Sleep -Seconds 5
    $recordsfound = Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType A | Where-Object {$_.timestamp -le $(Get-Date).AddDays(-$days)} | Out-GridView -PassThru
    $TotalItems=$recordsfound.count
    $CurrentItem = 0
    #$ErrorActionPreference = 'SilentlyContinue'
    If ($WithCaution -like "Yes") {
        Write-Host -ForegroundColor Yellow "With Caution option has been selected. You will be prompted to confirm every DNS record"
        $hit = 0
        Write-Host -ForegroundColor Yellow "Continuing with the deletion of DNS records"
        foreach ($i in $recordsfound) 
        {
            Write-Progress -Activity "Removing the Selected DNS A Records and PTR Records" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
            "{0},{1},{2},{3},{4},{5},{6}" -F $i.HostName, $i.RecordType, $i.Type,$i.TimeStamp,$i.TimeToLive,$i.RecordData.IPv4Address.IPAddressToString,$ZoneName |Add-Content -Path "$Path\$(get-date -Format MM-dd-yyyy)__records.csv"
            Write-Host -ForegroundColor Cyan $i.hostname will be deleted
            Write-Host -ForegroundColor Yellow "Deleting DNS record "$i.hostname" with IP Adress "$i.RecordData.IPv4Address.IPAddressToString
            Write-Host -ForegroundColor Cyan "=============================================="
            Remove-DnsServerResourceRecord -ZoneName $ZoneName -RRType A -Name $i.HostName -force
            $ReverseZones = Get-DnsServerZone | Where-Object {$_.IsReverseLookupZone -eq $true}
            $ReverseZonename = $ReverseZones.ZoneName
            foreach ($RZone in $ReverseZonename)
                {
                    $hostname = $i.hostname
                    $FQDNOPT2 = $i.HostName+"."+$zonename+"."
                    if ($(get-DnsServerResourceRecord -ZoneName $RZone -RRType Ptr).recorddata.ptrdomainname  -like "$FQDNOPT2" )
                    {
                        Write-Host -ForegroundColor Green "Found $FQDNOPT2 in $rzone!"
                        Start-Sleep -Seconds .25
                        $PrtRecord = Get-DnsServerResourceRecord -ZoneName $RZone | Where-Object {$_.recorddata.ptrdomainname -like "$FQDNOPT2"}
                        Remove-DnsServerResourceRecord -ZoneName $RZone -Name $PrtRecord.HostName -RRType Ptr -Force -Verbose
                        Write-Host ""
                        $hit++
                    }    
                }
            $CurrentItem++
            $PercentComplete = [int](($CurrentItem / $TotalItems) * 100)
        } 
        Write-Progress -Completed -Activity "Removing the Selected DNS A Records and PTR Records"
        Write-Host -ForegroundColor Green       "  Record Removal Report   "
        Write-Host -ForegroundColor Green       "=========================="
        Write-Host -ForegroundColor Yellow      "A records removed: "$($RecordsFound).count""
        Write-Host -ForegroundColor Magenta     "PRT records removed: "$hit""
        Pause
        Write-Host -ForegroundColor Green "Task Completed Returning to main menu"
        Start-Sleep -Seconds 2
        mainmenu   
    } else {
        $hit = 0
        Write-Host -ForegroundColor Yellow "Continuing with the deletion of DNS records"
        foreach ($i in $recordsfound) 
        {
            Write-Progress -Activity "Removing the Selected DNS A Records and PTR Records" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
            "{0},{1},{2},{3},{4},{5},{6}" -F $i.HostName, $i.RecordType, $i.Type,$i.TimeStamp,$i.TimeToLive,$i.RecordData.IPv4Address.IPAddressToString,$ZoneName |Add-Content -Path "$Path\$(get-date -Format MM-dd-yyyy)__records.csv"
            Write-Host -ForegroundColor Cyan $i.hostname will be deleted
            Write-Host -ForegroundColor Cyan "=============================================="
            Write-Host -ForegroundColor Yellow "Deleting DNS record "$i.hostname" with IP Adress "$i.RecordData.IPv4Address.IPAddressToString
            Remove-DnsServerResourceRecord -ZoneName $ZoneName -RRType A -Name $i.HostName -force
            $ReverseZones = Get-DnsServerZone | Where-Object {$_.IsReverseLookupZone -eq $true}
            $ReverseZonename = $ReverseZones.ZoneName
            foreach ($RZone in $ReverseZonename)
            {
                $hostname = $i.hostname
                $FQDNOPT2 = $i.HostName+"."+$zonename+"."               
                if ($(get-DnsServerResourceRecord -ZoneName $RZone -RRType Ptr).recorddata.ptrdomainname  -like "$FQDNOPT2" )
                {
                    Write-Host -ForegroundColor Green "Found $FQDNOPT2 in $rzone!"
                    Start-Sleep -Seconds .25
                    $PrtRecord = Get-DnsServerResourceRecord -ZoneName $RZone | Where-Object {$_.recorddata.ptrdomainname -like "$FQDNOPT2"}
                    Remove-DnsServerResourceRecord -ZoneName $RZone -Name $PrtRecord.HostName -RRType Ptr -Force -Verbose 
                    Write-Host ""
                    $hit++    
                }    
            }
            $CurrentItem++
            $PercentComplete = [int](($CurrentItem / $TotalItems) * 100)
        } 
        Write-Progress -Completed -Activity "Removing the Selected DNS A Records and PTR Records"
        Write-Host -ForegroundColor Green    "  Record Removal Report   "
        Write-Host -ForegroundColor Green   "=========================="
        Write-Host -ForegroundColor Yellow      "A records removed: "$($RecordsFound).count""
        Write-Host -ForegroundColor Magenta     "PRT records removed: "$hit""
        Pause
        Write-Host -ForegroundColor Green "Task Completed Returning to main menu"
        Start-Sleep -Seconds 2
        mainmenu
    }
}

function Get-DNSRecordReportDYNAMIC{
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$True,HelpMessage="Please enter a name for the job and report generated by this script")]
        [string] $JobReportName, # Name for the job and report generated by this script
        [string] $Path = "$env:SystemDrive\DNS_CleanUp_Util\DNS Record Report Jobs DYNAMIC\$JobReportName", #location where DNS remove records and reports are stored. 
        [Parameter(Mandatory=$true)]
        [int] $days # Used to located records older than the value specified
    )
    $ZoneSelect = Get-DnsServerZone | Out-GridView  -PassThru -Title "Select the DNS Zone to generate a report from"
    $ZoneName = $ZoneSelect.ZoneName
    if ($ZoneName.count -gt 1) 
    {
        Write-Host -ForegroundColor red "!!You have selected more than one DNS Zone to generate a report from. You must only select 1 DNS Zone!!"
        Pause
        Get-DNSRecordReportDYNAMIC
    }else{
        Write-Host -ForegroundColor Green "The DNS Zone $ZoneName has been selected"
        Start-Sleep -Seconds 2
        Write-Host -ForegroundColor Cyan "Creating directories to store reports"
        Start-Sleep -Seconds 2
        New-Item -ItemType Directory -Path $Path

        "{0},{1},{2},{3},{4},{5},{6}" -F "HostName","RecordType","Type","TimeStamp","TimeToLive","RecordData","ZoneName" |Add-Content -Path "$Path\$(get-date -Format MM-dd-yyyy)__records.csv"
        Write-Host -ForegroundColor Green "Looking for DNS Records older than"$(Get-Date).AddDays(-$days)
        Start-Sleep -Seconds 5
        $recordsfound = Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType A | Where-Object {$_.timestamp -le $(Get-Date).AddDays(-$days)}
        ForEach ($i in $recordsfound) 
        {
            "{0},{1},{2},{3},{4},{5},{6}" -F $i.HostName, $i.RecordType, $i.Type,$i.TimeStamp,$i.TimeToLive,$i.RecordData.IPv4Address.IPAddressToString,$ZoneName |Add-Content -Path "$Path\$(get-date -Format MM-dd-yyyy)__records.csv" 
        } 
        Write-Host -ForegroundColor Magenta "Report has found:" $($recordsfound).count "DNS records based on your search"
        Write-Host -ForegroundColor Yellow "For a list of the records, please review the latest log located at:" $Path\$(get-date -Format MM-dd-yyyy)
        pause
        Write-Host -ForegroundColor Green "Task Completed Returning to main menu"
        Start-Sleep -Seconds 2
        mainmenu
    }    
}
function Get-DNSRecordReportSTATIC{
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$True,HelpMessage="Please enter a name for the job and report generated by this script")]
        [string] $JobReportName, # Name for the job and report generated by this script
        [string] $Path = "$env:SystemDrive\DNS_CleanUp_Util\DNS Record Report Jobs STATIC\$JobReportName" #location where DNS remove records and reports are stored. 
        
    )
    $ZoneSelect = Get-DnsServerZone | Out-GridView  -PassThru -Title "Select the DNS Zone to generate a report from"
    $ZoneName = $ZoneSelect.ZoneName
    if ($ZoneName.count -gt 1) 
    {
        Write-Host -ForegroundColor red "!!You have selected more than one DNS Zone to generate a report from. You must only select 1 DNS Zone!!"
        Pause
        Get-DNSRecordReportDYNAMIC
    }else{
        Write-Host -ForegroundColor Green "The DNS Zone $ZoneName has been selected"
        Start-Sleep -Seconds 2
        Write-Host -ForegroundColor Cyan "Creating directories to store reports"
        Start-Sleep -Seconds 2
        New-Item -ItemType Directory -Path $Path

        "{0},{1},{2},{3},{4},{5},{6}" -F "HostName","RecordType","Type","TimeStamp","TimeToLive","RecordData","ZoneName" |Add-Content -Path "$Path\$(get-date -Format MM-dd-yyyy)__records.csv"
        Start-Sleep -Seconds 5
        $recordsfound = Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType A | Where-Object {$null -eq $_.timestamp}
        ForEach ($i in $recordsfound) 
        {
            "{0},{1},{2},{3},{4},{5},{6}" -F $i.HostName, $i.RecordType, $i.Type,$i.TimeStamp,$i.TimeToLive,$i.RecordData.IPv4Address.IPAddressToString,$ZoneName |Add-Content -Path "$Path\$(get-date -Format MM-dd-yyyy)__records.csv" 
        } 
        Write-Host -ForegroundColor Magenta "Report has found:" $($recordsfound).count "DNS records based on your search"
        Write-Host -ForegroundColor Yellow "For a list of the records, please review the latest log located at:" $Path\$(get-date -Format MM-dd-yyyy)
        pause
        Write-Host -ForegroundColor Green "Task Completed Returning to main menu"
        Start-Sleep -Seconds 2
        mainmenu
    }    
}
function Redo-DNSRecord{
     
#location where DNS Record Removals are stored by default
      $path = "$env:SystemDrive\DNS_CleanUp_Util\DNS Record Removal Jobs" 
#Selection of the Zone file
    $ZoneSelect = Get-DnsServerZone | Out-GridView -PassThru -Title "Select the DNS Zone to generate a report from"
    $ZoneName = $ZoneSelect.ZoneName
    Write-Host -ForegroundColor Green "The DNS Zone $ZoneName has been selected"
    Start-Sleep -Seconds 2
#Create a Dialog box to select the file for restoration
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $path
    #$OpenFileDialog.filter = "CSV (*.CSV)| *.CSV"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
#Import the CSV and run a loop to add the DNS entries and data back to the the DNS Zone
    Import-Csv -Path $OpenFileDialog.FileName | ForEach-Object {
        
        if ($ZoneName -notlike $_.ZoneName )
        {
            Write-Host -ForegroundColor Red "!!The Record you are trying to restore was not previously configured for this zone!!"
            Write-Host -ForegroundColor Yellow  "!!Please review the records you are attempting to restore and make note of the zone name column!!"
            Write-Host -ForegroundColor Cyan "Records for the restore can be located in the following directory: " $OpenFileDialog.filename
        }else{
            write-host -ForegroundColor Green "Performing a restore for DNS A Record: " $_.hostname
            Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name $_.hostname -IPv4Address $_.recorddata -CreatePtr -AgeRecord -Verbose
        }   
    }
    pause
    Write-Host -ForegroundColor Green "Task Completed Returning to main mainmenu"
    Start-Sleep -Seconds 2
    mainmenu    
}

function Redo-DNSRecordFromCSV{
     
    #location where DNS Record Removals are stored by default
    $path = "$env:SystemDrive\DNS_CleanUp_Util\DNS Record Removal Jobs" 
    #Selection of the Zone file
    $ZoneSelect = Get-DnsServerZone | Out-GridView -PassThru -Title "Select the DNS Zone to generate a report from"
    $ZoneName = $ZoneSelect.ZoneName
    Write-Host -ForegroundColor Green "The DNS Zone $ZoneName has been selected"        Start-Sleep -Seconds 2
    #Create a Dialog box to select the file for restoration
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $path
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
    #Import the CSV and run a loop to add the DNS entries and data back to the the DNS Zone
    Import-Csv -Path $OpenFileDialog.FileName |Out-GridView -PassThru -Title "Please select DNS entries to restore" | ForEach-Object 
    {
        if ($ZoneName -notlike $_.ZoneName )
        {
            Write-Host -ForegroundColor Red "!!The Record you are trying to restore was not previously configured for this zone!!"
            Write-Host -ForegroundColor Yellow  "!!Please review the records you are attempting to restore and make note of the zone name column!!"
            Write-Host -ForegroundColor Cyan "Records for the restore can be located in the following directory: " $OpenFileDialog.filename
            }else{
                write-host -ForegroundColor Green "Performing a restore for DNS A Record: " $_.hostname
                Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name $_.hostname -IPv4Address $_.recorddata -CreatePtr -AgeRecord -Verbose
            }   
    }
    pause
    Write-Host -ForegroundColor Green "Task Completed Returning to main mainmenu"
    Start-Sleep -Seconds 2
    mainmenu    
}


function Remove-DynamicDNSRecordFromCSV
{
    #location where DNS Record Removals are stored by default
    $path = "$env:SystemDrive\DNS_CleanUp_Util\DNS Record Report Jobs DYNAMIC\$JobReportName" 
    #Selection of the Zone file
    $ZoneSelect = Get-DnsServerZone | Out-GridView -PassThru -Title "Select the DNS Zone to generate a report from"
    $ZoneName = $ZoneSelect.ZoneName
    Write-Host -ForegroundColor Green "The DNS Zone $ZoneName has been selected"
    Start-Sleep -Seconds 2
    #Create a Dialog box to select the file for restoration
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $path
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
    #Import the CSV and run a loop to add the DNS entries and data back to the the DNS Zone
    $List = Import-Csv -Path $OpenFileDialog.FileName -header 'hostname'
    $TotalItems=$List.Count
    $CurrentItem = 0
    Import-Csv -Path $OpenFileDialog.FileName | ForEach-Object 
    {
        Write-Progress -Activity "Removing the Selected DNS A Records and PTR Records" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete 
        if ($ZoneName -notlike $_.ZoneName )
        {
            Write-Host -ForegroundColor Red "!!The Record you are trying to remove was not previously configured for this zone!!"
            Write-Host -ForegroundColor Yellow  "!!Please review the records you are attempting to remove and make note of the zone name column!!"
            Write-Host -ForegroundColor Cyan "Records for the remove can be located in the following directory: " $OpenFileDialog.filename
        }else{
            write-host -ForegroundColor Green "Performing a remove for DNS A Record: " $_.hostname
            remove-DnsServerResourceRecord -RRType 'A' -ZoneName $ZoneName -Name $_.hostname -RecordData $_.recorddata -Force
            write-host -ForegroundColor Magenta "Performing recursion to Reverse lookup zones.... please be patient"
            $ReverseZones = Get-DnsServerZone | Where-Object {$_.IsReverseLookupZone -eq $true}
            $ReverseZonename = $ReverseZones.ZoneName
            foreach ($i in $ReverseZonename)
            {
                Write-Host -ForegroundColor DarkMagenta "Looking in Zone $i for "$_.hostname" "
                remove-DnsServerResourceRecord -RRTyp Ptr -ZoneName $i -Name $_.hostname -Force -verbose
                remove-DnsServerResourceRecord -RRTyp Ptr -ZoneName $i -Name $_.hostname"."$ZoneName -Force -verbose
            }
            $CurrentItem++
            $PercentComplete = [int](($CurrentItem / $TotalItems) * 100)    
            }       
    }
    pause
    Write-Host -ForegroundColor Green "Task Completed Returning to main menu"
    Start-Sleep -Seconds 2
    Write-Progress -Completed -Activity "Removing the Selected DNS A Records and PTR Records"
    mainmenu  
}
    
function  DNSRECORDSREPORT
{
    $DomainControllers = Get-ADDomainController -Filter * | Select-Object Hostname, IPv4Address, OperatingSystem, site
    $ForwardZoneSelect = Get-DnsServerZone | Out-GridView -PassThru   -Title "Select the FORWARD DNS Zone to generate a count from"
    $ForwardZoneName = $ForwardZoneSelect.ZoneName | Select-Object -First 1
    $ReverseZoneSelect = Get-DnsServerZone | Out-GridView -PassThru  -Title "Select the REVERSE DNS Zone to generate a count from"
    $ReverseZoneName = $ReverseZoneSelect.ZoneName | Select-Object -First 1
    Write-Host "Please select the Active Directory Integrated Servers to get a DNS Resource Record count from"
    $DCObjects = Show-Menu -ItemFocusColor Green -MenuItems $DomainControllers.hostname -MultiSelect
    foreach ($i in $DCObjects)
    {
        $Arecordsfound = $(Get-DnsServerResourceRecord -RRType A -ZoneName $ForwardZoneName).Count
        $PTRrecordsfound = $(Get-DnsServerResourceRecord -RRType PTR -ZoneName $ReverseZoneName).Count
        Write-Host -ForegroundColor Green "$i has " -NoNewline;
        Write-Host -ForegroundColor Cyan $Arecordsfound -NoNewline;
        Write-Host -ForegroundColor Magenta " A records for zone $ForwardZoneName  "
        Write-Host -ForegroundColor Green "$i has " -NoNewline;
        Write-Host -ForegroundColor Cyan $PTRrecordsfound -NoNewline;
        Write-Host -ForegroundColor Yellow " Pointer records for zone $ReverseZoneName" 

    }

    Pause
    mainmenu


}

#MENUS 

function mainmenu
{
    param(
        [string]$menutitle = 'Main Menu'
    )
   
    Clear-Host
    Write-Host -Separator "================$menutitle================"
    $item = Show-Menu -ItemFocusColor Green -ReturnIndex -MenuItems @(
        "Export DNS DYNAMIC Records to CSV",
        "Export DNS STATIC Records to CSV",
        "DNS Record REMOVAL Options",
        "DNS Record RESTORATION Options",
        "Count DNS A Records"
        $(Get-MenuSeparator),
        "Quit"
    )

    if ($item -eq 0)
    {
        Write-Host -ForegroundColor Green 'Export DNS DYNAMIC Records selected'
        Start-Sleep -Seconds 1
        Get-DNSRecordReportDYNAMIC
    }
    if ($item -eq 1)
    {
        Write-Host -ForegroundColor Green 'Export DNS STATIC Records selected'
        Start-Sleep -Seconds 1
        Get-DNSRecordReportSTATIC
    }
    if ($item -eq 2)
    {
        Write-Host -ForegroundColor Green 'DNS Record REMOVAL Options Selected'
        Start-Sleep -Seconds 1
        DNSRemovalMenu
    }
    if ($item -eq 3)
    {
        Write-Host -ForegroundColor Green 'DNS Record RESTORATION Options Selected'
        Start-Sleep -Seconds 1
        DNSRestoreMenu
    }
    if ($item -eq 4)
    {
        Write-Host -ForegroundColor Green 'Count DNS A Records'
        Start-Sleep -Seconds 1
        DNSRECORDSREPORT
    }
   
      
}

function DNSRemovalMenu
{
   param(
       [string]$menutitle = 'DNS Record Removal Options'
   )
    Clear-Host
    Write-Host "================$menutitle================"
    $item = Show-Menu -ItemFocusColor Green -ReturnIndex -MenuItems @(
        "Remove DYNAMIC DNS Records with Caution",
        "Remove DYNAMIC DNS Records WITHOUT Caution",
        "Remove DYNAMIC Records from a CSV",
        "Return to Main Menu"
        $(Get-MenuSeparator),
        "Quit"
    
    )
    if ($item -eq 0)
    {
        Write-Host -ForegroundColor Green 'Remove DNS Records ' -NoNewline;
        Write-Host -ForegroundColor Cyan 'with Caution ' -NoNewline;
        Write-Host -ForegroundColor Green 'selected'
        Start-Sleep -Seconds 1
        Remove-DynamicDNSRecord -WithCaution Yes
    }
    if ($item -eq 1)
    {
        Write-Host -ForegroundColor Green 'Remove DNS Records ' -NoNewline;
        Write-Host -ForegroundColor Red 'WITHOUT ' -NoNewline;
        Write-Host -ForegroundColor Green 'selected'
        Start-Sleep -Seconds 1
        Remove-DynamicDNSRecord -WithCaution No
    }
    if ($item -eq 2)
    {
        Write-Host -ForegroundColor Green 'Remove DNS Records from a CSV selected'
        Start-Sleep -Seconds 1
        Remove-DynamicDNSRecordFromCSV
    }
    if ($item -eq 3)
    {
        Write-Host -ForegroundColor Green 'Returning to main menu'
        Start-Sleep -Seconds 1
        mainmenu
    }
   
}



function DNSRestoreMenu
{
    param(
       [string]$menutitle = 'DNS Record Restoration Options'
   )
        Clear-Host
        Write-Host "================$menutitle================"
        $item = Show-Menu -ItemFocusColor Green -ReturnIndex -MenuItems @(
        'Restore Deleted DNS Entries from a previous job',
        'Restore SELECT Deleted DNS Entries from a previous job',
        "Return to Main Menu",
        $(Get-MenuSeparator),
        "Quit"
    )

    if ($item -eq 0)
    {
        Write-Host -ForegroundColor Green 'Restore Deleted DNS Entries from a previous job has been selected'
        Start-Sleep -Seconds 1
        Redo-DNSRecord
        DNSRestoreMenu
    }
    if ($item -eq 1)
    {
        Write-Host -ForegroundColor Green 'Restore SELECT Deleted DNS Entries from a previous job has been selected'
        Start-Sleep -Seconds 1
        Redo-DNSRecordFromCSV
        DNSRestoreMenu

    }
    if ($item -eq 2)
    {
        Write-Host -ForegroundColor Green 'Returning to main menu'
        Start-Sleep -Seconds 1
        mainmenu
    }
}


mainmenu
Stop-Transcript
Pause
