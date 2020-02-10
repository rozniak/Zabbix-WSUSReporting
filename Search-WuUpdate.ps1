<#
    .SYNOPSIS
    This function is for searching WSUS for updates to retrieve their GUIDs.

    .DESCRIPTION
    This will search WSUS for updates whose titles contain the specified search phrase
    and returns the GUID/Title pairing.

    .EXAMPLE
    Search-WuUpdate

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

# Build file paths
#
$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition;

# Import functions
#
Import-Module "$curDir\Get-WsusServerRaw.ps1";

# Function definition
#
Function Search-WuUpdate
{
    Param (
        [Parameter(Position=0, Mandatory=$TRUE)]
        [String]
        $TitleSearch
    )

    $wuServer = Get-WsusServerRaw;

    $wuServer.SearchUpdates($titleSearch) | Foreach-Object {
        [PSCustomObject] @{
            Guid  = $_.Id.UpdateId
            Title = $_.Title
        }
    };
}