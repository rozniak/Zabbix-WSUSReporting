<#
    .SYNOPSIS
    This script is used for obtaining update counts for updates synchronized with WSUS.

    .DESCRIPTION
    This script is extremely simple as it is simply used to return a standard integer
    value that represents the count of updates matching the specified criteria.

    .PARAMETER UpdateApproval
    The approval state of updates to count. (Choices: AnyExceptDeclined,
                                                      Approved,
                                                      Declined,
                                                      Unapproved)

    .PARAMETER UpdateStatus
    The status of updates to count. (Choices: Any,
                                              Failed,
                                              FailedOrNeeded,
                                              InstalledOrNotApplicable,
                                              InstalledOrNotApplicableOrNoStatus,
                                              Needed,
                                              NoStatus)

    .PARAMETER ZabbixIP
    The IP address of the Zabbix server/proxy to send the value to.
    
    .PARAMETER ComputerName
    The hostname that should be reported to Zabbix, in case the hostname you set up in
    Zabbix isn't exactly the same as this computer's name.
    
    .EXAMPLE
    Get-WsusUpdateCount.ps1 -UpdateApproval Approved -UpdateStatus Needed -ZabbixIP 10.0.0.240

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

Param (
    [Parameter(Position=0, Mandatory=$TRUE)]
    [String]
    $UpdateApproval,
    [Parameter(Position=1, Mandatory=$TRUE)]
    [String]
    $UpdateStatus,
    [Parameter(Position=2, Mandatory=$TRUE)]
    [String]
    $ZabbixIP,
    [Parameter(Position=3, Mandatory=$FALSE)]
    [ValidatePattern(".+")]
    [String]
    $ComputerName = $env:COMPUTERNAME
)

# Load WSUS Administration library
#
$assemblies = Get-ChildItem -Path "C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Microsoft.UpdateServices.Administration" | Get-ChildItem;
$dllTarget = $assemblies[0].FullName;

[void][Reflection.Assembly]::LoadFrom($dllTarget);

# Get WSUS server connection instance
#
$wsusServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();

# Retrieve the updates
#
$scope = New-Object -TypeName Microsoft.UpdateServices.Administration.UpdateScope;

# Set up the approval scope
#
switch ($UpdateApproval)
{
    "Any" {
        $scope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::Any;
    }

    "AnyExceptDeclined" {
        $scope.ApprovedStates =
            [Microsoft.UpdateServices.Administration.ApprovedStates]::HasStaleUpdateApprovals -bor
            [Microsoft.UpdateServices.Administration.ApprovedStates]::LatestRevisionApproved -bor
            [Microsoft.UpdateServices.Administration.ApprovedStates]::NotApproved;
    }

    "Approved" {
        $scope.ApprovedStates =
            [Microsoft.UpdateServices.Administration.ApprovedStates]::HasStaleUpdateApprovals -bor
            [Microsoft.UpdateServices.Administration.ApprovedStates]::LatestRevisionApproved;
    }

    "Declined" {
        $scope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::Declined;
    }

    "Unapproved" {
        $scope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::NotApproved;
    }

    default {
        return -1;
    }
}

# Set up the installation status report scope
#
switch ($UpdateStatus)
{
    "Any" {
        $scope.IncludedInstallationStates = [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::All;
    }

    "Failed" {
        $scope.IncludedInstallationStates = [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::Failed;
    }

    "FailedOrNeeded" {
        $scope.IncludedInstallationStates =
            [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::Failed -bor
            [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::NotInstalled -bor
            [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::InstalledPendingReboot;
    }

    "InstalledOrNotApplicable" {
        $scope.IncludedInstallationStates =
            [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::Installed -bor
            [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::NotApplicable;
    }

    "InstalledOrNotApplicableOrNoStatus" {
        $scope.IncludedInstallationStates =
            [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::Installed -bor
            [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::NotApplicable -bor
            [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::Unknown;
    }

    "Needed" {
        $scope.IncludedInstallationStates =
            [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::NotInstalled -bor
            [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::InstalledPendingReboot;
        $scope.ExcludedInstallationStates =
            [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::Failed;
    }

    "NoStatus" {
        $scope.IncludedInstallationStates = [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::Unknown;
    }

    default {
        return -1;
    }
}

# Push value to Zabbix
#
$arch = [System.IntPtr]::Size * 8;

& ($env:ProgramFiles + "\Zabbix Agent\bin\win" + $arch + "\zabbix_sender.exe") ("-z", $ZabbixIP, "-p", "10051", "-s", $ComputerName, "-k", ("wsus.updates[" + $UpdateApproval + "," + $UpdateStatus + "]"), "-o", $wsusServer.GetUpdateCount($scope));