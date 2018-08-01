<#
    .SYNOPSIS
    This script is used for obtaining the count of computers that have not reported
    into WSUS in the last 30 days.

    .DESCRIPTION
    This script is extremely simple as it is simply used to return a standard integer
    value that represents the count of computers that have not reported into this WSUS
    server within the last 30 days.
    
    .EXAMPLE
    Get-WsusOldComputerCount.ps1

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

$cutoffDateTime = [System.DateTime]::UtcNow.AddDays(-30)
$oldComputers = Get-WsusComputer | Where-Object { $_.LastReportedStatusTime -le $cutoffDateTime }

return $oldComputers.Length