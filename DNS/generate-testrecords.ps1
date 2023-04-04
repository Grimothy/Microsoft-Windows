Import-Module NameIT
$oct = 1

Measure-Command { 1..250| ForEach-Object {

    $name = Invoke-Generate "APC-???-####"
    $ip = "10.10.14.$oct"
    $oct++
        Add-DnsServerResourceRecordA -ZoneName "mjm.com" -CreatePtr -Name $name -Verbose -IPv4Address $ip -AgeRecord

    }
}

