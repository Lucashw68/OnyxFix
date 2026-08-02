#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$drivers = @(Get-OnyxInstalledDriver)
if ($drivers.Count -eq 0) {
    Write-OnyxMessage -French 'Aucun package Onyx FireWire précis trouvé.' -English 'No exact Onyx FireWire package found.' -Kind Warning
}
$drivers
