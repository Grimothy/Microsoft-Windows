function LoadMenuSystem
{
	$ZoneSelect | ForEach-Object {
		"[$($ZoneSelect.IndexOf($_))] $_"
	}
	#Ask user which domain
	$Selection = Read-Host -Prompt "Enter the number for the domain you want to use" 
	(Write-Host -NoNewline "You chose domain" -ForegroundColor Yellow -BackgroundColor Black), (Write-Host -NoNewline ""$ZoneSelect[$Selection]"" -ForegroundColor Green -BackgroundColor Black), (Write-Host "Is this correct? (Y/N)" -ForegroundColor Yellow -BackgroundColor Black)
	$response = read-host
	# If user chooses "Y" then continue with script, otherwise reload menu for user to select
	if ($response -ne "Y")
	{
			LoadMenuSystem break
	}
}
LoadMenuSystem