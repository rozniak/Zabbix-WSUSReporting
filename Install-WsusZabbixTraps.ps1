﻿<#
    .SYNOPSIS
    This script is used for installing the PowerShell scripts used for providing Zabbix
    traps into the task scheduler on the local machine.

    .DESCRIPTION
    This script first queries for the IP of the Zabbix Server or Proxy that is then
    embedded as part of the parameters used in the scheduled task actions. The tasks are
    scheduled to run hourly into order to provide data to Zabbix via traps.
    
    .EXAMPLE
    Install-WsusZabbixTraps.ps1

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

Param (
    [Parameter(Position=0, Mandatory=$TRUE)]
    [ValidatePattern("^(\d+\.){3}\d+$")]
    [String]
    $ZabbixIP
)

$globalTrigger = New-ScheduledTaskTrigger -Daily -At 8am

# Set up content size scheduled task
#
$contentSizeAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ('-NoProfile -NoLogo -File "' + $env:ProgramFiles + '\Zabbix Agent\WSUSREPORTS\Get-WsusContentSize.ps1" -ZabbixIP ' + $ZabbixIP)

$contentSizeTask = Register-ScheduledTask -TaskName "Calculate WSUSContent Size (Zabbix Trap)" -Trigger $globalTrigger -Action $contentSizeAction

$contentSizeTask.Triggers[0].Repetition.Interval = "PT1H"
$contentSizeTask | Set-ScheduledTask

# Set up updates scheduled tasks
#
$filterCombos = (
    ("Approved", "Any"),
    ("Approved", "Failed"),
    ("Any", "Any"),
    ("Unapproved", "Any"),
    ("Unapproved", "Needed")
)

foreach ($filter in $filterCombos)
{
    $updateAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ('-NoProfile -NoLogo -File "' + $env:ProgramFiles + '\Zabbix Agent\WSUSREPORTS\Get-WsusUpdateCount.ps1" -UpdateApproval ' + $filter[0] + " -UpdateStatus " + $filter[1] + " -ZabbixIP " + $ZabbixIP)

    $updateAction = Register-ScheduledTask -TaskName ("Count WSUS Updates of Filter '" + $filter[0] + ", " + $filter[1] + "' (Zabbix Trap)") -Trigger $globalTrigger -Action $updateAction

    $updateAction.Triggers[0].Repetition.Interval = "PT1H"
    $updateAction | Set-ScheduledTask
}

# Set up old computer count scheduled task
#
$oldComputersAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ('-NoProfile -NoLogo -File "' + $env:ProgramFiles + '\Zabbix Agent\WSUSREPORTS\Get-WsusOldComputerCount.ps1" -ZabbixIP ' + $ZabbixIP)

$oldComputersTask = Register-ScheduledTask -TaskName "Count Old Computers in WSUS (Zabbix Trap)" -Trigger $globalTrigger -Action $oldComputersAction

$oldComputersTask.Triggers[0].Repetition.Interval = "PT1H"
$oldComputersTask | Set-ScheduledTask