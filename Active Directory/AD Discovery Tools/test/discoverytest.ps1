$dc = Get-ADDomainController -Filter * 

$dc.hostname | Foreach-Object -Parallel {
  $_
}


$count = 1..5000
$count | ForEach-Object -Parallel {Write-Output "$_"}