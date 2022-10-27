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
    [string]
    $ZabbixIP,
    [Parameter(Position=1, Mandatory=$FALSE)]
    [ValidatePattern(".+")]
    [string]
    $ComputerName = $env:COMPUTERNAME
)

# Find where WSUS content directory is located
#
$wsusSettingsKey   = "HKLM:\Software\Microsoft\Update Services\Server\Setup";
$wsusSettingsProps = Get-ItemProperty -Path $wsusSettingsKey;
$wsusContentPath   = $wsusSettingsProps.ContentDir;

# Get the sum of all child files' size
#
$sizeProp  = Get-ChildItem -Path $wsusContentPath -Recurse |
                 Measure-Object -Property Length -Sum |
                 Select Sum;
$sizeInGB  = $sizeProp.Sum / 1024 / 1024 / 1024;
$roundedGB = [Math]::Round($sizeInGB, 2);

# Push value to Zabbix
#
$zabbixArgs   =
    (
        "-z",
        $ZabbixIP,
        "-p",
        "10051",
        "-s",
        $ComputerName,
        "-k",
        "wsus.contentsize",
        "-o",
        $roundedGB
    );
$zabbixSender = Get-ChildItem -Path   ($env:ProgramFiles + "\Zabbix Agent") `
                              -Filter "zabbix_sender.exe"                   `
                              -Recurse;

& $zabbixSender.FullName $zabbixArgs;
