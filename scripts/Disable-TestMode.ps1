#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

Write-OnyxMessage -French 'Après redémarrage, le pilote Onyx signé localement ne se chargera plus.' -English 'After reboot, the locally signed Onyx driver will no longer load.' -Kind Warning
if ($PSCmdlet.ShouldProcess('current boot configuration', 'Disable Windows Test Mode (testsigning)')) {
    Invoke-OnyxExternalCommand -FilePath (Join-Path $env:SystemRoot 'System32\bcdedit.exe') -ArgumentList @('/set', 'testsigning', 'off') | Out-Null
    Write-OnyxMessage -French 'Mode test désactivé au prochain redémarrage; le package reste installé.' -English 'Test Mode will be disabled after reboot; the package remains installed.' -Kind Warning
}
