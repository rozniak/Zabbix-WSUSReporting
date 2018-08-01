<#
    .SYNOPSIS
    This script is used for obtaining the size of the WSUS content directory in GB.

    .DESCRIPTION
    This script is extremely simple as it is simply used to return a standard integer
    value that represents the size of the WSUS content directory in GB, rounded to
    two decimal places.
    
    .EXAMPLE
    Get-WsusContentSize.ps1

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

# Find where WSUS content directory is located
#
$wsusProps = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Update Services\Server\Setup"
$contentDir = $wsusProps.ContentDir

# Get the sum of all child files' size
#
$sizeProp = Get-ChildItem -Path $contentDir -Recurse | Measure-Object -Property Length -Sum | Select Sum
$sizeInGB = $sizeProp.Sum / 1024 / 1024 / 1024
$roundedGB = [Math]::Round($sizeInGB, 2)

return $roundedGB