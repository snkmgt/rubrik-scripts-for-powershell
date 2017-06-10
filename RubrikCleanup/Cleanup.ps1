[CmdletBinding()]
  Param(
    [Parameter(Mandatory = $true)]
    [String]$Brik,
    [Parameter(Mandatory = $true)]
    [String]$Username,
    [Parameter(Mandatory = $true)]
    [String]$Password
    )

# Import the current module
Import-Module -Name "$PSScriptRoot\..\Rubrik\Rubrik" -Force
. "$PSScriptRoot\CleanupFunctions.ps1"

# Connect to the Brik
Connect -Brik $Brik -Username $Username -Password $Password -ErrorAction Stop

# Remove Live Mounts
RemoveMount

# Remove all VMs, DBs, and filesets protected by bogus SLA Domains

RemoveProtectionVM

RemoveProtectionDB

RemoveProtectionFileset

# Remove all non-essential SLA Domains

RemoveSLA

# Remove all non-essential reports

RemoveReport

# Report

ReportCleanup