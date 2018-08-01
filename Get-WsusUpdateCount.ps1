<#
    .SYNOPSIS
    This script is used for obtaining update counts for updates synchronized with WSUS.

    .DESCRIPTION
    This script is extremely simple as it is simply used to return a standard integer
    value that represents the count of updates matching the specified criteria.

    .PARAMETER approval
    The approval state of updates to count. (Choices: AnyExceptDeclined,
                                                      Approved,
                                                      Declined,
                                                      Unapproved)

    .PARAMETER status
    The status of updates to count. (Choices: Any,
                                              Failed,
                                              FailedOrNeeded,
                                              InstalledOrNotApplicable,
                                              InstalledOrNotApplicableOrNoStatus,
                                              Needed,
                                              NoStatus)
    
    .EXAMPLE
    Get-WsusUpdateCount.ps1 -UpdateApproval Approved -UpdateStatus Needed

    .NOTES
    Author: Rory Fewell
    GitHub: https://github.com/rozniak
    Website: https://oddmatics.uk
#>

Param (
    [Parameter(Position=0, Mandatory=$TRUE)]
    $UpdateApproval,
    [Parameter(Position=1, Mandatory=$TRUE)]
    $UpdateStatus
)

$updates = Get-WsusUpdate -Approval $UpdateApproval -Status $UpdateStatus

return $updates.Length