<#
    .SYNOPSIS
    This script is used for obtaining the size of the WSUS content directory in GB.

    .DESCRIPTION
    This script is extremely simple as it is simply used to return a standard integer
    value that represents the size of the WSUS content directory in GB, rounded to
    two decimal places.

    .PARAMETER ZabbixIP
    The IP address of the Zabbix server/proxy to send the value to.
    
    .PARAMETER ComputerName
    The hostname that should be reported to Zabbix, in case the hostname you set up in
    Zabbix isn't exactly the same as this computer's name.
    
    .EXAMPLE
    Get-WsusContentSize.ps1 -ZabbixIP 10.0.0.240

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

# Find where WSUS content directory is located
#
$wsusProps = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Update Services\Server\Setup";
$contentDir = $wsusProps.ContentDir;

# Get the sum of all child files' size
#
$sizeProp = Get-ChildItem -Path $contentDir -Recurse | Measure-Object -Property Length -Sum | Select Sum;
$sizeInGB = $sizeProp.Sum / 1024 / 1024 / 1024;
$roundedGB = [Math]::Round($sizeInGB, 2);

# Push value to Zabbix
#
$arch = [System.IntPtr]::Size * 8;

& ($env:ProgramFiles + "\Zabbix Agent\bin\win" + $arch + "\zabbix_sender.exe") ("-z", $ZabbixIP, "-p", "10051", "-s", $ComputerName, "-k", "wsus.contentsize", "-o", $roundedGB);