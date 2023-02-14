function test1
{
     
    #location where DNS Record Removals are stored by default
          $path = "$env:SystemDrive\DNS_CleanUp_Util\DNS Record Report Jobs\$JobReportName" 
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
    $List = Import-Csv -Path $OpenFileDialog.FileName -header 'hostname'
    $TotalItems=$List.Count
    $CurrentItem = 0
    
        Import-Csv -Path $OpenFileDialog.FileName | ForEach-Object {
            
            if ($ZoneName -notlike $_.ZoneName )
            {
                Write-Host -ForegroundColor Red "!!The Record you are trying to remove was not previously configured for this zone!!"
                Write-Host -ForegroundColor Yellow  "!!Please review the records you are attempting to remove and make note of the zone name column!!"
                Write-Host -ForegroundColor Cyan "Records for the remove can be located in the following directory: " $OpenFileDialog.filename
            }else{
                $ErrorActionPreference = 'SilentlyContinue'
                Write-Progress -Activity "Remove the Selected DNS A Records and PTR Records" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete 
                write-host -ForegroundColor Green "Performing a remove for DNS A Record: " $_.hostname
                remove-DnsServerResourceRecord -RRType 'A' -ZoneName $ZoneName -Name $_.hostname -RecordData $_.recorddata -Force
                write-host -ForegroundColor Magenta "Performing recursion to Reverse lookup zones.... please be patient"
                $ReverseZones = Get-DnsServerZone | Where-Object {$_.IsReverseLookupZone -eq $true}
                $ReverseZonename = $ReverseZones.ZoneName
                
                foreach ($i in $ReverseZonename)
                {
                    Write-Host -ForegroundColor DarkMagenta "Looking in Zone $i for "$_.hostname" "
                    remove-DnsServerResourceRecord -RRTyp Ptr -ZoneName $i -Name $_.hostname -Force -verbose
                }
            $CurrentItem++
            $PercentComplete = [int](($CurrentItem / $TotalItems) * 100) 
            
            
              
            }
           
        }
        pause
        Write-Host -ForegroundColor Green "Task Completed Returning to main menu"
        Start-Sleep -Seconds 2
        mainmenu  
    }
