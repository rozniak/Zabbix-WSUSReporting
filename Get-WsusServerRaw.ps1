<#
    .SYNOPSIS
    This function is for loading the Microsoft.UpdateServices.Administration library
    and retrieving the update server installed on the local machine.

    .DESCRIPTION
    This will load the Microsoft.UpdateServices.Administration library from the Global
    Assembly Cache (MSIL_GAC), and retrieve the update server installed on the local
    machine.

    .EXAMPLE
    Get-WsusServerRaw

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

# Load WSUS Administration library
#
$assemblies = Get-ChildItem -Path "C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Microsoft.UpdateServices.Administration" | Get-ChildItem;
$dllTarget = $assemblies[0].FullName;

[void][Reflection.Assembly]::LoadFrom($dllTarget);

# Function definition
#
Function Get-WsusServerRaw()
{
    return [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
}