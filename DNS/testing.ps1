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
        Import-Csv -Path $OpenFileDialog.FileName | ForEach-Object -Parallel {
            
            if ($ZoneName -notlike $_.ZoneName )
            {
                Write-Host -ForegroundColor Red "!!The Record you are trying to restore was not previously configured for this zone!!"
                Write-Host -ForegroundColor Yellow  "!!Please review the records you are attempting to restore and make note of the zone name column!!"
                Write-Host -ForegroundColor Cyan "Records for the restore can be located in the following directory: " $OpenFileDialog.filename
            }else{
                write-host -ForegroundColor Green "Performing a restore for DNS A Record: " $_.hostname
                Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name $_.hostname -IPv4Address $_.recorddata -CreatePtr -AgeRecord -Verbose
                pause
                Clear-Host
                Redo-DNSRecord
            }   
        }
        pause
        Write-Host -ForegroundColor Green "Task Completed Returning to main menu"
        Start-Sleep -Seconds 2
        Clear-Host
        pause
        Redo-DNSRecord
    }

    Redo-DNSRecord 