Import-Module NameIT
$oct = 1

Measure-Command { 1..250| ForEach-Object {

    $name = Invoke-Generate "APS-???-####"
    $ip = "10.10.15.$oct"
    $oct++
        Add-DnsServerResourceRecordA -ZoneName "test.local" -CreatePtr -Name $name -Verbose -IPv4Address $ip

    }
}

