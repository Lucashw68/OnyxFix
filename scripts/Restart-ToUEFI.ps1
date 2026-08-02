#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$state = Get-OnyxBootState
Write-OnyxMessage -French "Secure Boot : $($state.SecureBoot). Le script ne peut pas le désactiver." -English "Secure Boot: $($state.SecureBoot). This script cannot disable it." -Kind Warning
if ($PSCmdlet.ShouldProcess('computer', 'Restart immediately to UEFI firmware settings')) {
    Invoke-OnyxExternalCommand -FilePath (Join-Path $env:SystemRoot 'System32\shutdown.exe') -ArgumentList @('/r', '/fw', '/t', '0') | Out-Null
}
