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
[void][System.Reflection.Assembly]::Load(
    "Microsoft.UpdateServices.Administration, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
);

# Function definition
#
Function Get-WsusServerRaw()
{
    return [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
}
