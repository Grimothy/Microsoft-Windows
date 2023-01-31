$host.UI.RawUI.BackgroundColor = "black"
$UtilityName = "ActiveDirectoryUtility"
$BaseUtilPath = "$env:SystemDrive\$UtilityName"

$LogPath = "$BaseUtilPath\logs\$(get-date -Format MM-dd-yyyy-hh-mm-ss)__log.txt"
Start-Transcript -Path $LogPath   -Force

#Install required Powershell Module
if(-not (Get-Module PSMenu -ListAvailable)){
    Write-Host -ForegroundColor Magenta "PSMenu module not installed. Performing installation now..."
    Install-Module PSMenu -Scope CurrentUser -Force
    }

Function RDCD{
    [CmdletBinding()]
    param
    ( 
        #[Parameter(Mandatory=$True,HelpMessage="Please enter a name for the job and report generated by this script")]
        #[Parameter(Mandatory=$true)]
        #[int] $days # Used to located records older than the value specified
        [Parameter(Mandatory=$true,HelpMessage="Errors Only specifies whether or not to Display only errors reported by DCDIAG")]
        [ValidateSet('Yes','No')] # Specifies whether or not to prompt the user for the deletion of EACH AND EVERY DNS RECORD
        [string] $ErrorsOnly
    )

        
    $DomainControllers = Get-ADDomainController -Filter * | Select-Object Hostname, IPv4Address, OperatingSystem, site
    $DCObjects = Show-Menu -ItemFocusColor Green -MenuItems $DomainControllers.hostname -MultiSelect
        
    if ($ErrorsOnly -like "Yes")
    {
        foreach ($i in $DCObjects){
            Write-Host -ForegroundColor Green "Running DC Diagnostics on: "-NoNewline; 
            Write-Host -ForegroundColor Yellow "$i. "-NoNewline;
            Write-Host -ForegroundColor Green "This query will display " -NoNewline;
            Write-Host -ForegroundColor Magenta "ERRORS ONLY!!!!!"
            Start-Sleep -Seconds 2
            CMD /C dcdiag /q /S:$i
            Write-Host -ForegroundColor Green "Diagnostics complete please review"
        
        }
        pause
        BasicADHCMenu
    }else{
        foreach ($i in $DCObjects){
            Write-Host -ForegroundColor Green "Running DC Diagnostics on: "-NoNewline; 
            Write-Host -ForegroundColor Yellow "$i. "-NoNewline;
            Start-Sleep -Seconds 2
            CMD /C dcdiag /S:$i
            Write-Host -ForegroundColor Green "Diagnostics complete please review"
        
        }

    }
}
# Run Active Directory Domain Controller Diagnostics with Reporting funtion    
Function RDCDWR {
    [CmdletBinding()]
    param
    ( 
        [Parameter(Mandatory=$True,HelpMessage="Please enter a name for the job and report generated by this script")]
        [string] $JobReportName, # Name for the job and report generated by this script
        [Parameter(Mandatory=$True,HelpMessage="Please enter a name for the job and report generated by this script")]
        [string] $SubDir, # Name for the job and report generated by this script
        [string] $ReportPath = "$BaseUtilPath\$SubDir\$JobReportName", #location where DNS remove records and reports are stored. 
        [Parameter(Mandatory=$true,HelpMessage="Errors Only specifies whether or not to Display only errors reported by DCDIAG")]
        [ValidateSet('Yes','No')] # Specifies whether or not to prompt the user for the deletion of EACH AND EVERY DNS RECORD
        [string] $Reporting
    )
    Clear-Host
    Write-Host -ForegroundColor Cyan "Creating directories to store reports"
    Start-Sleep -Seconds 1
    New-Item -ItemType Directory -Path $ReportPath
    $DomainControllers = Get-ADDomainController -Filter * | Select-Object Hostname, IPv4Address, OperatingSystem, site
    $DCObjects = Show-Menu -ItemFocusColor Green -MenuItems $DomainControllers.hostname -MultiSelect
        
    if ($Reporting -like "Yes")
    {
        foreach ($i in $DCObjects){
            Write-Host -ForegroundColor Green "Creating a DC Diagnostics report for: "-NoNewline; 
            Write-Host -ForegroundColor Yellow "$i. "-NoNewline;
            Write-Host -ForegroundColor Green "This is a comprehensive query with DNS tests " -NoNewline
                
            Start-Sleep -Seconds 2
            CMD /C dcdiag/S:$i /c /v /f:"$ReportPath\$i-$(get-date -Format MM-dd-yyyy)__DCDIAG.log"
            Write-Host -ForegroundColor Green "Diagnostics complete"
    }else{
        BasicADHCMenu
         }

    }
    pause
    BasicADHCMenu
}
       
# Run View Active Directory Replication    
Function VDCR {
    [CmdletBinding()]
    param( 
        #[Parameter(Mandatory=$True,HelpMessage="Please enter a name for the job and report generated by this script")]
        #[string] $JobReportName, # Name for the job and report generated by this script
        #[Parameter(Mandatory=$True,HelpMessage="Please enter a name for the job and report generated by this script")]
        #[string] $SubDir, # Name for the job and report generated by this script
        #[string] $ReportPath = "$BaseUtilPath\$SubDir\$JobReportName", #location where DNS remove records and reports are stored. 
        #[Parameter(Mandatory=$true,HelpMessage="Errors Only specifies whether or not to Display only errors reported by DCDIAG")]
        #ValidateSet('Yes','No')] # Specifies whether or not to prompt the user for the deletion of EACH AND EVERY DNS RECORD
        #[string] $Reporting
    )
    Clear-Host
    #Write-Host -ForegroundColor Cyan "Creating directories to store reports"
    Start-Sleep -Seconds 1
    #New-Item -ItemType Directory -Path $ReportPath
    ##$DCObjects = Show-Menu -ItemFocusColor Green -MenuItems $DomainControllers.hostname -MultiSelect
    Write-Host -ForegroundColor Green "Running replication summary Job"
    Write-Host -ForegroundColor Yellow "The replsummary operation quickly and concisely summarizes the replication state and relative health of a forest"
    CMD /C repadmin /replsummary
    Write-Host -ForegroundColor Green "Replication summary Completed"
    pause
    BasicADHCMenu
} 
#Function perform enterprise replication push from a specific domain controller
Function PERP {

    Clear-Host
    Write-Host -ForegroundColor Green "Select the Domain controller you would like to push the replication " -NoNewline;
    Write-Host -ForegroundColor Yellow "FROM"
    Start-Sleep -Seconds 1
    $DomainControllers = Get-ADDomainController -Filter * | Select-Object Hostname, IPv4Address, OperatingSystem, site
    $DCObjects = Show-Menu -ItemFocusColor Green -MenuItems $DomainControllers.hostname 
    CMD /C repadmin /syncall $DCObjects /AdeP
    Write-Host -ForegroundColor Green "Replication Completed"
    pause
    BasicADHCMenu
} 

#Function perform enterprise replication PULL to a specific domain controller
Function PRPULL {

    Clear-Host
    Write-Host -ForegroundColor Green "Select the Domain controller you would like to PULL the repliction  " -NoNewline;
    Write-Host -ForegroundColor Yellow "TO"
    Start-Sleep -Seconds 1
    $DomainControllers = Get-ADDomainController -Filter * | Select-Object Hostname, IPv4Address, OperatingSystem, site
    $DCObjects = Show-Menu -ItemFocusColor Green -MenuItems $DomainControllers.hostname 
    CMD /C repadmin /syncall /d $DCObjects 
    Write-Host -ForegroundColor Green "Replication Completed"
    pause
    BasicADHCMenu
} 
#Function Forces the KCC on targeted domain controller(s) to immediately recalculate its inbound replication topology.
Function IKCC {

    Clear-Host
    Write-Host -ForegroundColor Green "Select the Domain controller you recalute the inbound replication topology for"
    Start-Sleep -Seconds 1
    $DomainControllers = Get-ADDomainController -Filter * | Select-Object Hostname, IPv4Address, OperatingSystem, site
    $DCObjects = Show-Menu -ItemFocusColor Green -MenuItems $DomainControllers.hostname 
    CMD /C repadmin /kcc $DCObjects 
    Write-Host -ForegroundColor Green "KCC completed"
    pause
    BasicADHCMenu
} 

Function DFSRMIGSTATE {

    Clear-Host
    $DfsrMigrationState = cmd /c dfsrmig.exe /getglobalstate | Out-String
    Write-Host -ForegroundColor Cyan " State of SYSVOL: " -NoNewline;
    Write-Host -ForegroundColor Yellow $DfsrMigrationState
    if ($DfsrMigrationState -like "*Eliminated*") 
    {
        Write-Host -ForegroundColor Green "SYSVOL Migration already completed"
        Pause
        BasicADHCMenu
    }else{
        Write-Host -ForegroundColor Magenta "SYSVOL is not yet in an eliminated state and FRS may be still used!!"
        Pause
        BasicADHCMenu
    }

}

function ADDR {
    param 
    (
        [CmdletBinding()]
        [Parameter(Mandatory=$True,HelpMessage="Please enter a name for the job and report generated by this script")]
        [string] $JobReportName, # Name for the job and report generated by this script
        [Parameter(Mandatory=$True,HelpMessage="Please enter a name for the job and report generated by this script")]
        [string] $SubDir, # Name for the job and report generated by this script
        [string] $ReportPath = "$BaseUtilPath\$SubDir\$JobReportName" #location where records and reports are stored. 
    )
    
    Clear-Host
    Write-Host -ForegroundColor Cyan "Creating directories to store reports"
    Start-Sleep -Seconds 1
    New-Item -ItemType Directory -Path $ReportPath

    Write-Host -ForegroundColor Green "######################################################################"
    Write-Host -ForegroundColor Green "#                        Gathering FSMO DATA                         #"
    Write-Host -ForegroundColor Green "######################################################################"   

    #$DomainFSMO = Get-ADDomain | Format-List InfrastructureMaster, RIDMaster, PDCEmulator
    #$DomainFSMO | Add-Content
    $FSMO = cmd /c netdom query FSMO |Out-String

    New-Item -ItemType File -Path $ReportPath\fsmo.txt

    Write-Host -ForegroundColor Green "The follow machine(s) are running FSMO Roles:"
    Write-Host -ForegroundColor Cyan $FSMO
    "The follow machine(s) are running FSMO Roles:"| Add-Content -Path $ReportPath\fsmo.txt
    $FSMO | Add-Content -Path $ReportPath\fsmo.txt 

    $DfsrMigrationState = cmd /c dfsrmig.exe /getglobalstate | Out-String
    Write-Host -ForegroundColor Green "######################################################################"
    Write-Host -ForegroundColor Green "#                        Gathering SYSVOL GLOBAL STATE               #"
    Write-Host -ForegroundColor Green "######################################################################"   
    Write-Host -ForegroundColor Cyan "Determining the curreent state of SYSVOL: " -NoNewline;
    Write-Host -ForegroundColor Yellow $DfsrMigrationState
    if ($DfsrMigrationState -like "*Eliminated*") 
        {
            Write-Host -ForegroundColor Green "SYSVOL Migration already completed"
            Start-Sleep  -Seconds 3
            "SYSVOL Migration already completed" | Add-Content -Path $ReportPath\SYSVOLMigrationStatus.txt
            $DfsrMigrationState | Add-Content -Path $ReportPath\SYSVOLMigrationStatus.txt
        }else{
            Write-Host -ForegroundColor Magenta "SYSVOL is not yet in an eliminated state and FRS may be still used!!"
            Start-Sleep -Seconds 3
            "SYSVOL is not yet in an eliminated state and FRS may be still used!!" | Add-Content -Path $ReportPath\SYSVOLMigrationStatus.txt

        }


    Write-Host -ForegroundColor Green       "######################################################################"
    Write-Host -ForegroundColor Green       "#                        Gathering NTP DATA                          #"
    Write-Host -ForegroundColor Green       "######################################################################"   
    
    $PDC = $(Get-ADDomain).PDCEmulator
    Write-Host -ForegroundColor Yellow "The PDC Emulator Role is hosted on " -NoNewline;
    write-host -ForegroundColor Magenta $PDC
    $DomainControllers = Get-ADDomainController -Filter * 
   
    #$DomainControllerHostnames = $DomainControllers.hostname
    foreach ($i in $DomainControllers.hostname)
    {
        "START OF W32TM REPORT FOR $i" | Add-Content -Path $ReportPath\NTP.txt
        Write-Host -ForegroundColor Yellow "Getting W32TM status on: " -NoNewline;
        Write-Host -ForegroundColor Magenta $i
        Write-Host -ForegroundColor Green "######################################################################"
        Start-Sleep -Seconds 2
        $W32tmStatus = CMD /C w32tm /query /computer:$i /status |Out-String
        Write-Host -ForegroundColor Yellow $W32tmStatus
        "######$i STATUS######" | Add-Content -Path $ReportPath\NTP.txt  
        $W32tmStatus | Add-Content -Path $ReportPath\NTP.txt 
        
        Write-Host -ForegroundColor Yellow "Getting W32TM CONFIGURATION on: " -NoNewline;
        Write-Host -ForegroundColor Magenta $i
        Write-Host -ForegroundColor Green "######################################################################" 
        Start-Sleep -Seconds 2
        $W32tmConfiguration = CMD /C w32tm /query /computer:$i /CONFIGURATION |Out-String
        Write-Host -ForegroundColor Green  $W32tmConfiguration      
        "######$i CONFIGURATION######" | Add-Content -Path $ReportPath\NTP.txt  
        $W32tmConfiguration| Add-Content -Path $ReportPath\NTP.txt 
        
        Write-Host -ForegroundColor Yellow "Getting W32TM SOURCE CONFIGURATION on: " -NoNewline;
        Write-Host -ForegroundColor Magenta $i
        Write-Host -ForegroundColor Green "######################################################################" 
        Start-Sleep -Seconds 2
        $W32tmConfiguration = CMD /C w32tm /query /computer:$i /Source |Out-String
        Write-Host -ForegroundColor Green  $W32tmConfiguration      
        "######$i SOURCE_CONFIGURATION######" | Add-Content  -Path $ReportPath\NTP.txt  
        $W32tmConfiguration| Add-Content -Path $ReportPath\NTP.txt 


        Write-Host -ForegroundColor Yellow "Getting W32TM PEERS on: " -NoNewline;
        Write-Host -ForegroundColor Magenta $i
        Write-Host -ForegroundColor Green "######################################################################" 
        Start-Sleep -Seconds 2
        $W32tmConfiguration = CMD /C w32tm /query /computer:$i /peers |Out-String
        Write-Host -ForegroundColor Green  $W32tmConfiguration      
        "######$i PEERS######" | Add-Content -Path $ReportPath\NTP.txt  
        $W32tmConfiguration| Add-Content -Path $ReportPath\NTP.txt 
          

    }
    write-host -ForegroundColor Green       "######################################################################"
    write-host -ForegroundColor Magenta     "#                 NTP Related discovery completed                    #"
    write-host -ForegroundColor Green       "######################################################################" 
    

    Write-Host -ForegroundColor Green       "######################################################################"
    Write-Host -ForegroundColor Green       "#           Getting Domain Controller Replication Health             #"
    Write-Host -ForegroundColor Green       "######################################################################" 

    Write-Host -ForegroundColor Green "Running replication summary Job"
    Write-Host -ForegroundColor Yellow "The replsummary operation quickly and concisely summarizes the replication state and relative health of a forest"
    CMD /C repadmin /replsummary | Add-Content -Path $ReportPath\Replication.txt 
    CMD /C repadmin /showrepl | Add-Content -Path $ReportPath\Replication.txt 
    Write-Host -ForegroundColor Green "Replication summary Completed"

    write-host -ForegroundColor Green       "######################################################################"
    write-host -ForegroundColor Magenta     "#             Replication Health Related discovery completed         #"
    write-host -ForegroundColor Green       "######################################################################"
    

    Write-Host -ForegroundColor Green       "############################################################################"
    Write-Host -ForegroundColor Green       "#                  Compiling Domain Controller Data                        #"
    Write-Host -ForegroundColor Magenta     "# This taks will capture the following details for each domain controller: #"
    Write-Host -ForegroundColor Cyan        "# 1. Comprehensive DC Diagnostics                                          #"
    Write-Host -ForegroundColor Cyan        "# 2. Network Configuration                                                 #"
    Write-Host -ForegroundColor Cyan        "# 3. Installed Roles and Features                                          #"
    Write-Host -ForegroundColor Cyan        "# 4. List of Installed Applications                                        #"
    Write-Host -ForegroundColor Cyan        "# 5. List of DNS Forwarders                                                #"
    Write-Host -ForegroundColor Green       "############################################################################" 

    foreach ($i in $DomainControllers.hostname)
    {
        Start-Sleep -Seconds 5
        "Start of Comprehensive DC Diagnostics" | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        Write-Host -ForegroundColor Green "Start of Comprehensive DC Diagnostics on " -NoNewline;
        Write-Host -ForegroundColor Yellow $i
        "#######$i DCIAG START########" | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        CMD /C dcdiag/S:$i /c /v /f:"$ReportPath\$i-DomainControllerDiscoveryData.log"
        "#######$i DCIAG COMPLETE#####" | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        
        Write-Host -ForegroundColor Green "Starting collection of network configuration details on " -NoNewline;
        Write-Host -ForegroundColor Yellow $i
        "#######$i NETWORK COLLECTION START########" | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        Enter-PSSession -ComputerName $i 
        $NETCollection = Get-NetIPAddress | Out-String
        Write-Host -ForegroundColor Yellow $NETCollection
        $NETCollection | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        "#######$i NETWORK COLLECTION COMPLETE########" | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        
        Write-Host -ForegroundColor Green "Starting collection of installed Roles and Features on " -NoNewline;
        Write-Host -ForegroundColor Yellow $i
        "#######$i INSTALLED ROLES AND FEATURES START########" | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        $InstalledRolesAndFeatures = Get-WindowsFeature | Where-Object {$_.installstate -eq "Installed"} | Out-String
        Write-Host -ForegroundColor Yellow $InstalledRolesAndFeatures
        $InstalledRolesAndFeatures | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        "#######$i INSTALLED ROLES AND FEATURES COMPLETE########" | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"

        Write-Host -ForegroundColor Green "Starting collection of installed software on " -NoNewline;
        Write-Host -ForegroundColor Yellow $i
        "#######$i INSTALLED APPLICATIONS START########" | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        $InstalledSoftware = Get-InstalledSoftware | Out-String
        Write-Host -ForegroundColor Yellow $InstalledSoftware
        $InstalledSoftware |  Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        "#######$i INSTALLED APPLICATIONS COMPLETE########" | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        " " | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"


        Write-Host -ForegroundColor Green "Starting collection of DNS Forwarders on " -NoNewline;
        Write-Host -ForegroundColor Yellow $i
        "#######$i DNS FORWARDERS START########" | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        $DNSForwarders = Get-DnsServerForwarder | Out-String
        Write-Host -ForegroundColor Yellow $DNSForwarders 
        $DNSForwarders | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        "#######$i DNS FORWARDERS COMPLETE########" | Add-Content -Path "$ReportPath\$i-DomainControllerDiscoveryData.log"
        Exit-PSSession


    }  
    
    
    write-host -ForegroundColor Green       "######################################################################"
    write-host -ForegroundColor Magenta     "#             Domain Controller Data Compilation Completed           #"
    write-host -ForegroundColor Green       "######################################################################"
    Copy-Item -Path $LogPath -Destination $ReportPath -Force -Verbose

    $compress = @{
        Path = $ReportPath
        CompressionLevel = "Fastest"
        DestinationPath = "$ReportPath.zip"
      }
      Compress-Archive @compress -Verbose

    Pause
    BasicADHCMenu
}   
function Get-InstalledSoftware {
    <#
	.SYNOPSIS
		Retrieves a list of all software installed on a Windows computer.
	.EXAMPLE
		PS> Get-InstalledSoftware
		
		This example retrieves all software installed on the local computer.
	.PARAMETER ComputerName
		If querying a remote computer, use the computer name here.
	
	.PARAMETER Name
		The software title you'd like to limit the query to.
	
	.PARAMETER Guid
		The software GUID you'e like to limit the query to
	#>
    [CmdletBinding()]
    param (
		
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName = $env:COMPUTERNAME,
		
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
		
        [Parameter()]
        [guid]$Guid
    )
    process {
        try {
            $scriptBlock = {
                $args[0].GetEnumerator() | ForEach-Object { New-Variable -Name $_.Key -Value $_.Value }
				
                $UninstallKeys = @(
                    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
                    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
                )
                New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS | Out-Null
                $UninstallKeys += Get-ChildItem HKU: | where { $_.Name -match 'S-\d-\d+-(\d+-){1,14}\d+$' } | foreach {
                    "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall"
                }
                if (-not $UninstallKeys) {
                    Write-Warning -Message 'No software registry keys found'
                } else {
                    foreach ($UninstallKey in $UninstallKeys) {
                        $friendlyNames = @{
                            'DisplayName'    = 'Name'
                            'DisplayVersion' = 'Version'
                        }
                        Write-Verbose -Message "Checking uninstall key [$($UninstallKey)]"
                        if ($Name) {
                            $WhereBlock = { $_.GetValue('DisplayName') -like "$Name*" }
                        } elseif ($GUID) {
                            $WhereBlock = { $_.PsChildName -eq $Guid.Guid }
                        } else {
                            $WhereBlock = { $_.GetValue('DisplayName') }
                        }
                        $SwKeys = Get-ChildItem -Path $UninstallKey -ErrorAction SilentlyContinue | Where-Object $WhereBlock
                        if (-not $SwKeys) {
                            Write-Verbose -Message "No software keys in uninstall key $UninstallKey"
                        } else {
                            foreach ($SwKey in $SwKeys) {
                                $output = @{ }
                                foreach ($ValName in $SwKey.GetValueNames()) {
                                    if ($ValName -ne 'Version') {
                                        $output.InstallLocation = ''
                                        if ($ValName -eq 'InstallLocation' -and 
                                            ($SwKey.GetValue($ValName)) -and 
                                            (@('C:', 'C:\Windows', 'C:\Windows\System32', 'C:\Windows\SysWOW64') -notcontains $SwKey.GetValue($ValName).TrimEnd('\'))) {
                                            $output.InstallLocation = $SwKey.GetValue($ValName).TrimEnd('\')
                                        }
                                        [string]$ValData = $SwKey.GetValue($ValName)
                                        if ($friendlyNames[$ValName]) {
                                            $output[$friendlyNames[$ValName]] = $ValData.Trim() ## Some registry values have trailing spaces.
                                        } else {
                                            $output[$ValName] = $ValData.Trim() ## Some registry values trailing spaces
                                        }
                                    }
                                }
                                $output.GUID = ''
                                if ($SwKey.PSChildName -match '\b[A-F0-9]{8}(?:-[A-F0-9]{4}){3}-[A-F0-9]{12}\b') {
                                    $output.GUID = $SwKey.PSChildName
                                }
                                New-Object -TypeName PSObject -Prop $output
                            }
                        }
                    }
                }
            }
			
            if ($ComputerName -eq $env:COMPUTERNAME) {
                & $scriptBlock $PSBoundParameters
            } else {
                Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ArgumentList $PSBoundParameters
            }
        } catch {
            Write-Error -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
        }
    }
}

Function ADDMENU {
    Clear-Host
    $MenuTitle = "Active Directory Discovery"
    Write-Host -ForegroundColor Green "================$MenuTitle================"
    $item = Show-Menu  -ItemFocusColor Green -ReturnIndex -MenuItems @(
        "Run Domain Controller Diagnostics",
        $(Get-MenuSeparator),
        "Quit"
    )

    If ($item -eq 0)
    { 
        Write-Host -ForegroundColor Green "Run Domain Controller Diagnostics"
        Start-Sleep -seconds 1
        
        BasicADHCMenu
        
    }
    
}
function BasicADHCMenu {
    Clear-Host
    $MTBasicADHCMenu = "Basic Active Directory Health Checks"
    Write-Host -ForegroundColor Green "================$MTBasicADHCMenu================"
    $item = Show-Menu  -ItemFocusColor Green -ReturnIndex -MenuItems @(
        "Run Domain Controller Diagnostics",
        "Run Domain Controller Diagnostics -- Show Errors Only",
        "Generate Domain Controller Diagnostics Report",
        "View Domain Controller Replication",
        "Perform an Enterprise Replication Push",
        "Perform a Replication Pull", # Create Sub menu
        "Initiate KCC",
        "Get SYSVOL Migration State"
        "Return to main menu", # Create Sub menu
        $(Get-MenuSeparator),
        "Quit"
    )
    If ($item -eq 0)
    { 
        Write-Host -ForegroundColor Green "Run Domain Controller Diagnostics"
        Start-Sleep -seconds 1
        RDCD -ErrorsOnly No
        BasicADHCMenu
        
    }
    if ($item -eq 1)
    {
        Write-Host -ForegroundColor Green "Run Domain Controller Diagnostics -- Show Errors Only" 
        Start-Sleep -seconds 1
        RDCD -ErrorsOnly Yes
        BasicADHCMenu
    }
    if ($item -eq 2)
    {
        Write-Host -ForegroundColor Green "Generate Domain Controller Diagnostics Report"  
        Start-Sleep -seconds 1
        RDCDWR -Reporting Yes -SubDir "RDCDW_Reports"
    }
    if ($item -eq 3)
    {
        Write-Host -ForegroundColor Green "View Domain Controller Replication"  
        Start-Sleep -seconds 1
        VDCR
    }
    if ($item -eq 4)
    {
        Write-Host -ForegroundColor Green "Perform an Enterprise Replication Push"  
        Start-Sleep -seconds 1
        PERP
    }
    if ($item -eq 5)
    {
        Write-Host -ForegroundColor Green "Perform a Replication Pull"  
        Start-Sleep -seconds 1
        PRPULL
    }
    if ($item -eq 6)
    {
        Write-Host -ForegroundColor Green "Initiate KCC"  
        Start-Sleep -seconds 1
        IKCC
    }
    if ($item -eq 7)
    {
        Write-Host -ForegroundColor Green "Getting Sysvol Migration State..."
        Start-Sleep -seconds 1
        HomeMenu
        DFSRMIGSTATE
    }
    if ($item -eq 8)
    {
        Write-Host -ForegroundColor Green "Returning to main menu"  
        Start-Sleep -seconds 1
        HomeMenu

    }
    if ($item -eq 9)
    {
        Write-Host -ForegroundColor Green "Quiting application"  
        Start-Sleep -seconds 1
    }
}

Function HomeMenu {
    Clear-Host
    Write-Host -ForegroundColor Green "================Active Directory Utility================" 
    
        $item = Show-Menu -ReturnIndex  -ItemFocusColor Green -MenuItems @(
            "Basic Active Directory Health Checks",
            "Active Directory Discovery",
            "Network time utilities",
            $(Get-MenuSeparator),
            "Quit"
        )

        If ($item -eq 0)
        { 
            Write-Host -ForegroundColor Green "Domain Controller Discovery Report has been selected"
            Start-Sleep -seconds 1
            BasicADHCMenu
        
        }
        if ($item -eq 1)
        {
            Write-Host -ForegroundColor Green "Active Directory Discovery Actions has been selected" 
            Start-Sleep -Seconds 1
            #ADDMENU
            ADDR -SubDir "Active_Directory_Discovery_Reports"
        }
        if ($item -eq 2)
        {
            Write-Host -ForegroundColor Green "Quiting application"  
        }
     
    
}

HomeMenu
