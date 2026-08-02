#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$drivers = @(Get-OnyxInstalledDriver)
if ($drivers.Count -eq 0) { Write-OnyxMessage -French 'Aucun pilote Onyx à supprimer.' -English 'No Onyx driver to remove.'; return }
$pnputil = Join-Path $env:SystemRoot 'System32\pnputil.exe'
foreach ($driver in $drivers) {
    # Revalidate every identity field immediately before the destructive command.
    if ($driver.OriginalName -ine 'OnyxFireWire.inf' -or $driver.ProviderName -notmatch '(?i)^LOUD Technologies Inc\.?$' -or $driver.PublishedName -notmatch '^oem\d+\.inf$') {
        throw "Refusing to remove an imprecisely identified package: $($driver | Out-String)"
    }
    if ($PSCmdlet.ShouldProcess("$($driver.PublishedName) ($($driver.ProviderName))", 'Uninstall and delete verified Onyx driver')) {
        Invoke-OnyxExternalCommand -FilePath $pnputil -ArgumentList @('/delete-driver', $driver.PublishedName, '/uninstall', '/force') -SuccessExitCodes @(0, 3010) | Out-Null
    }
}
