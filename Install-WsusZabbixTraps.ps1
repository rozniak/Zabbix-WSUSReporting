﻿<#
    .SYNOPSIS
    This script is used for installing the PowerShell scripts used for providing Zabbix
    traps into the task scheduler on the local machine.

    .DESCRIPTION
    This script first queries for the IP of the Zabbix Server or Proxy that is then
    embedded as part of the parameters used in the scheduled task actions. The tasks are
    scheduled to run hourly into order to provide data to Zabbix via traps.
    
    .PARAMETER ZabbixIP
    The IP address of the Zabbix server/proxy to send the value to.
    
    .PARAMETER ComputerName
    The hostname that should be reported to Zabbix, in case the hostname you set up in
    Zabbix isn't exactly the same as this computer's name.
    
    .EXAMPLE
    Install-WsusZabbixTraps.ps1 10.0.0.240

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
    $ComputerName = $env:COMPUTERNAME,
    [Parameter(Position=2, Mandatory=$FALSE)]
    [string]
    $ZabbixRoot   = $env:ProgramFiles + "\Zabbix Agent"
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition;

$forever  = [System.TimeSpan]::MaxValue;
$nextHour = [System.DateTime]::Now.AddHours(1);
$oneHour  = New-TimeSpan -Hours 1;

$guid            = Get-Content -Path "$scriptRoot\task-guid";
$systemPrincipal = New-ScheduledTaskPrincipal -UserID    "NT AUTHORITY\SYSTEM" `
                                              -LogonType ServiceAccount        `
                                              -RunLevel  Highest;

# Windows 10 onwards expects RepetitionDuration to be omitted to make an indefinitely
# repeating trigger, for older versions we must specify TimeSpan.MaxValue
#
$globalTrigger = $NULL;

if ((Get-WmiObject -Class Win32_OperatingSystem).Version.StartsWith("10."))
{
    $globalTrigger =
        New-ScheduledTaskTrigger -Once                         `
                                 -At                 $nextHour `
                                 -RepetitionInterval $oneHour;

}
else
{
    $globalTrigger =
        New-ScheduledTaskTrigger -Once                         `
                                 -At                 $nextHour `
                                 -RepetitionInterval $oneHour  `
                                 -RepetitionDuration $forever;
}

# Set up content size scheduled task
#
$contentSizeFilePath = "$ZabbixRoot\WSUSREPORTS\Get-WsusContentSize.ps1";
$contentSizeTitle    = "Calculate WSUSContent Size (Zabbix Trap)";

$contentSizeActionArgs =
    (
        "-NoProfile",
        "-NoLogo",
        "-File",
        "`"$contentSizeFilePath`"",
        "-ZabbixIP",
        $ZabbixIP,
        "-ComputerName",
        $ComputerName
    ) -join " ";
$contentSizeAction     = New-ScheduledTaskAction -Execute  "powershell.exe"      `
                                                 -Argument $contentSizeActionArgs;

$contentSizeTask = Register-ScheduledTask -TaskName    $contentSizeTitle  `
                                          -Trigger     $globalTrigger     `
                                          -Action      $contentSizeAction `
                                          -Principal   $systemPrincipal   `
                                          -Description $guid              `
                   | Out-Null;

# Set up updates scheduled tasks
#
$filterCombos   = (
    ( "Approved"   ,"Any"    ),
    ( "Approved"   ,"Failed" ),
    ( "Any"        ,"Any"    ),
    ( "Unapproved" ,"Any"    ),
    ( "Unapproved" ,"Needed" )
);
$updateFilePath = "$ZabbixRoot\WSUSREPORTS\Get-WsusUpdateCount.ps1";

foreach ($filter in $filterCombos)
{
    $approval = $filter[0];
    $status   = $filter[1];
    $title    = "Count WSUS Updates of Filter '$approval, $status' (Zabbix Trap)";

    $updateActionArgs =
        (
            "-NoProfile",
            "-NoLogo",
            "-File",
            "`"$updateFilePath`"",
            "-UpdateApproval",
            $approval,
            "-UpdateStatus",
            $status,
            "-ZabbixIP",
            $ZabbixIP,
            "-ComputerName",
            $ComputerName
        ) -join " ";

    $updateAction     = New-ScheduledTaskAction -Execute  "powershell.exe" `
                                                -Argument $updateActionArgs;
 
    $updateTask = Register-ScheduledTask -TaskName    $title           `
                                         -Trigger     $globalTrigger   `
                                         -Action      $updateAction    `
                                         -Principal   $systemPrincipal `
                                         -Description $guid            `
                  | Out-Null;
}

# Set up old computer count scheduled task
#
$oldComputersFilePath = "$ZabbixRoot\WSUSREPORTS\Get-WsusOldComputerCount.ps1";
$oldComputersTitle    = "Count Old Computers in WSUS (Zabbix Trap)";

$oldComputersActionArgs =
    (
        "-NoProfile",
        "-NoLogo",
        "-File",
        "`"$oldComputersFilePath`"",
        "-ZabbixIP",
        $ZabbixIP,
        "-ComputerName",
        $ComputerName
    ) -join " ";
$oldComputersAction     = New-ScheduledTaskAction -Execute  "powershell.exe"       `
                                                  -Argument $oldComputersActionArgs;

$oldComputersTask = Register-ScheduledTask -TaskName    $oldComputersTitle  `
                                           -Trigger     $globalTrigger      `
                                           -Action      $oldComputersAction `
                                           -Principal   $systemPrincipal    `
                                           -Description $guid               `
                    | Out-Null;
