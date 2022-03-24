#This script will move the DHCP server scopes that are selected when the script is run.
#It does present the option to move the Server Options as well but is not a required parameter
function move-dhcpserverv4perscope {
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$true)]
        [string] $path, #location where DHCP exports and backups will be saved C:\DHCP for example
        [Parameter(Mandatory=$true)]
        [ValidateSet('Yes','No')]
        [string] $WithServerOptions
    )

    Write-Host -ForegroundColor Cyan "Creating directories for export and import"
    Start-Sleep -Seconds 2
    New-Item -ItemType Directory -Path $path
    Start-Sleep -Seconds 2
    

    $dhcpserver = Get-DhcpServerInDC | Out-GridView -Title "Select DHCP for export" -PassThru
    $scopes =  Get-DhcpServerv4Scope -ComputerName $dhcpserver.DnsName | Out-GridView -Title "Please select scopes" -PassThru
    $Sname = $dhcpserver.DnsName
    $scopes | ft -AutoSize | Out-File $path\ScopesMigrated.txt -Verbose -Force
   

    if ($WithServerOptions -like "Yes"){
        
         Write-Host -ForegroundColor Cyan "Creating additional directories"
         Start-Sleep 2
         New-Item -ItemType Directory -Path "$path\Exports\$Sname\ServerOptionsOnly" -Verbose
         New-Item -ItemType Directory -Path "$path\Exports\$Sname\ServerOptionsOnly\backup" -Verbose
         
         #export and import scope  only options
         Export-DhcpServer -ComputerName $dhcpserver.DnsName -File  "$path\Exports\$Sname\ServerOptionsOnly\$Sname.xml" -Verbose
         Import-DhcpServer -ServerConfigOnly -File "$path\Exports\$Sname\ServerOptionsOnly\$Sname.xml" -BackupPath "$path\Exports\$Sname\ServerOptionsOnly\backup"-Verbose+
      

        foreach ($scope in $scopes){
            $scope = $scope.scopeid
            Write-Host -ForegroundColor Cyan "Creating additional directories"
            Start-Sleep 2
            New-Item -ItemType Directory -Path "$path\Backup\$Sname\$scope" -Verbose
            New-Item -ItemType Directory -Path "$path\Exports\$Sname\$scope" -Verbose
         
            
            #Export and import per scope
            Set-DhcpServerv4Scope -State InActive -ScopeId $scope -Verbose -ComputerName $Sname
            Write-Host -ForegroundColor Magenta "Setting $scope on $Sname to Inactive State...."
            Start-Sleep -Seconds 4
            Export-DhcpServer -ScopeId $scope.ScopeId -ComputerName $dhcpserver.DnsName -Leases -File "$path\Exports\$Sname\$scope\$scope.xml" -Verbose
            Import-DhcpServer -ScopeId $scope -Leases -File "$path\Exports\$Sname\$scope\$scope.xml" -BackupPath "$path\Backup\$Sname\$scope\" -Verbose 
         
        }
    }else{
        
        
        foreach ($scope in $scopes){
            $scope = $scope.scopeid
            New-Item -ItemType Directory -Path "$path\Backup\$Sname\$scope" -Verbose
            New-Item -ItemType Directory -Path "$path\Exports\$Sname\$scope" -Verbose
            
            #Export and import per scope
            Set-DhcpServerv4Scope -State InActive -ScopeId $scope -Verbose -ComputerName $Sname
            Write-Host -ForegroundColor Magenta "Setting $scope on $Sname to Inactive State...."
            Start-Sleep -Seconds 4
            Export-DhcpServer -ScopeId $scope.ScopeId -ComputerName $dhcpserver.DnsName -Leases -File "$path\Exports\$Sname\$scope\$scope.xml" -Verbose
            Import-DhcpServer -ScopeId $scope -Leases -File "$path\Exports\$Sname\$scope\$scope.xml" -BackupPath "$path\Backup\$Sname\$scope\" -Verbose
        }


    }
    Write-Host -ForegroundColor Green "-------------------------------------"
    Write-Host -ForegroundColor Green "complete press any key to continue..."
    Write-Host -ForegroundColor Green "-------------------------------------"
    Read-Host

}

