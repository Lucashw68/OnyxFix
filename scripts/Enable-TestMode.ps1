#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$state = Get-OnyxBootState
if ($state.TestSigning -eq 'Enabled') { Write-OnyxMessage -French 'Le mode test est déjà activé.' -English 'Test Mode is already enabled.' -Kind Success; return }
if ($state.SecureBoot -eq 'Enabled') {
    Write-OnyxMessage -French 'Secure Boot est activé : BCDEdit peut refuser la modification.' -English 'Secure Boot is enabled: BCDEdit may reject this change.' -Kind Warning
}
if ($PSCmdlet.ShouldProcess('current boot configuration', 'Enable Windows Test Mode (testsigning)')) {
    Invoke-OnyxExternalCommand -FilePath (Join-Path $env:SystemRoot 'System32\bcdedit.exe') -ArgumentList @('/set', 'testsigning', 'on') | Out-Null
    Write-OnyxMessage -French 'Mode test configuré. Redémarrez manuellement.' -English 'Test Mode configured. Reboot manually.' -Kind Warning
}
