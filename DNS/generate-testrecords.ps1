Import-Module NameIT
$oct = 1

Measure-Command { 1..100 | ForEach-Object {

    $name = Invoke-Generate "APC-???-####"
    $ip = "10.10.11.$oct"
    $oct++
        Add-DnsServerResourceRecordA -ZoneName "catuslab.local" -CreatePtr -Name $name -Verbose -IPv4Address $ip -AgeRecord

    }
}

