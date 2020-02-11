<#
    .SYNOPSIS
    This script is used for counting the number of computers that have installed and
    reported against a particular update in WSUS.

    .DESCRIPTION
    This script will search for an update by its title in order to retrieve information
    about its installation status reported by computers in WSUS.

    .PARAMETER Guid
    The GUID of the update.

    .PARAMETER Scope
    The name of the computer group to count against, use Any for all computers.

    .PARAMETER UpdateStatus
    The status of the update, based on the UpdateInstallationState enumeration.
    
    .EXAMPLE
    Get-WsusUpdateInstallationStatus.ps1 -Guid c139f586-b22d-4e85-a769-47af7820a792 -Scope Any -UpdateStatus Installed

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

Param (
    [Parameter(Position=0, Mandatory=$TRUE)]
    [String]
    $Guid,
    [Parameter(Position=1, Mandatory=$TRUE)]
    [String]
    $Scope,
    [Parameter(Position=2, Mandatory=$TRUE)]
    [String]
    $UpdateStatus
)

#
# PREFACE:
#
#     Due to the fact that WSUS queries and operations take a decent chunk of time,
#     normally Zabbix polling this item would time out. For that reason, we return a
#     cached result to Zabbix immediately (if possible) and then continue on with the
#     script to generate the next value.
#

# Retrieve GUID
#
$updateGuid = New-Object -TypeName "System.Guid" -ArgumentList ($Guid)

# Build file paths
#
$curDir    = Split-Path -Parent $MyInvocation.MyCommand.Definition;
$cachePath = $curDir + "\" + $updateGuid + "-" + $UpdateStatus + ".cached";

# Build script block for background job
#
$scriptBlock = {
    Param (
        [Parameter(Position=0, Mandatory=$TRUE)]
        [Guid]
        $ptGuid,
        [Parameter(Position=1, Mandatory=$TRUE)]
        [String]
        $ptScope,
        [Parameter(Position=2, Mandatory=$TRUE)]
        [String]
        $ptUpdateStatus,
        [Parameter(Position=3, Mandatory=$TRUE)]
        [String]
        $ptCachePath,
        [Parameter(Position=4, Mandatory=$TRUE)]
        [String]
        $ptInvocationPath
    )

    Import-Module "$ptInvocationPath\Get-WsusServerRaw.ps1";

    # Get WSUS server connection instance
    #
    $wsusServer = Get-WsusServerRaw;

    # Search for the update
    #
    $updateRevisionId = New-Object -TypeName "Microsoft.UpdateServices.Administration.UpdateRevisionId" `
                                   -ArgumentList ($ptGuid, 0);
    $update           = $wsusServer.GetUpdate($updateRevisionId);

    # Retrieve scope or group for the update information
    #
    $computerScope = $NULL;

    if ($ptScope -eq "Any")
    {
        $computerScope = New-Object -TypeName "Microsoft.UpdateServices.Administration.ComputerTargetScope"
    }
    else
    {
        $searchGroups = $wsusServer.GetComputerTargetGroups() | Where-Object { $_.Name -eq $ptScope; }

        if ($searchGroups.Count -ne 1)
        {
            return;
        }
        else
        {
            $computerScope = $searchGroups[0];
        }
    }
    
    # Retrieve and count updates
    #
    $infoCollection = $update.GetUpdateInstallationInfoPerComputerTarget($computerScope);
    $statusCount    = 0;
    $totalCount     = $infoCollection.Count;

    foreach ($updateInfo in $infoCollection)
    {
        $checkState = $NULL;

        switch ($ptUpdateStatus)
        {
            "Downloaded" {
                $checkState = [Microsoft.UpdateServices.Administration.UpdateInstallationState]::Downloaded;
            }

            "Failed" {
                $checkState = [Microsoft.UpdateServices.Administration.UpdateInstallationState]::Failed;
            }

            "Installed" {
                $checkState = [Microsoft.UpdateServices.Administration.UpdateInstallationState]::Installed;
            }

            "InstalledPendingReboot" {
                $checkState = [Microsoft.UpdateServices.Administration.UpdateInstallationState]::InstalledPendingReboot;
            }

            "NotApplicable" {
                $checkState = [Microsoft.UpdateServices.Administration.UpdateInstallationState]::NotApplicable;
            }

            "NotInstalled" {
                $checkState = [Microsoft.UpdateServices.Administration.UpdateInstallationState]::NotInstalled;
            }

            "Unknown" {
                $checkState = [Microsoft.UpdateServices.Administration.UpdateInstallationState]::Unknown;
            }
        }

        if ($updateInfo.UpdateInstallationState -eq $checkState)
        {
            $statusCount++;
        }
    }

    # Write result to file
    #
    $percentageInstalled = [System.Math]::Round(($statusCount / $totalCount) * 100);

    Out-File -FilePath $ptCachePath -InputObject $percentageInstalled -Force;
};

# Start background job
#
Start-Job -ScriptBlock $scriptBlock -ArgumentList ($updateGuid, $Scope, $UpdateStatus, $cachePath, $curDir) | Out-Null;

# Check if there is a cached result we can return...
#
if (Test-Path -Path $cachePath -PathType Leaf)
{
    return Get-Content -Path $cachePath;
}
else
{
    return $NULL;
}
