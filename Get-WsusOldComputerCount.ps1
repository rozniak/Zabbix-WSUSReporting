<#
    .SYNOPSIS
    This script is used for obtaining the count of computers that have not reported
    into WSUS in the last 30 days.

    .DESCRIPTION
    This script is extremely simple as it is simply used to return a standard integer
    value that represents the count of computers that have not reported into this WSUS
    server within the last 30 days.

    .PARAMETER ZabbixIP
    The IP address of the Zabbix server/proxy to send the value to.
    
    .PARAMETER ComputerName
    The hostname that should be reported to Zabbix, in case the hostname you set up in
    Zabbix isn't exactly the same as this computer's name.
    
    .EXAMPLE
    Get-WsusOldComputerCount.ps1 -ZabbixIP 10.0.0.240

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

Param (
    [Parameter(Position=0, Mandatory=$TRUE)]
    [ValidatePattern("^(\d+\.){3}\d+$")]
    [String]
    $ZabbixIP,
    [Parameter(Position=1, Mandatory=$FALSE)]
    [ValidatePattern(".+")]
    [String]
    $ComputerName = $env:COMPUTERNAME
)

$cutoffDateTime = [System.DateTime]::UtcNow.AddDays(-30)
$oldComputers = Get-WsusComputer | Where-Object { $_.LastReportedStatusTime -le $cutoffDateTime }

# Push value to Zabbix
#
& ($env:ProgramFiles + "\Zabbix Agent\bin\win64\zabbix_sender.exe") ("-z", $ZabbixIP, "-p", "10051", "-s", $ComputerName, "-k", "wsus.oldcomputers", "-o", $oldComputers.Length)