#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$DriverPath,
    [switch]$SkipDisconnectPrompt
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$DriverPath = Get-OnyxDriverPath $DriverPath
$validation = Test-OnyxDriverFiles -DriverPath $DriverPath
if (-not $validation.Valid) { throw 'Refusing to install an invalid Onyx driver package.' }
if (-not $SkipDisconnectPrompt) {
    $continue = $PSCmdlet.ShouldContinue('Power off or unplug the Onyx console before continuing. Is it disconnected?', 'Hardware safety / Sécurité matérielle')
    if (-not $continue) { throw 'Installation cancelled until the console is disconnected.' }
}
$pnputil = Join-Path $env:SystemRoot 'System32\pnputil.exe'
$installed = @(Get-OnyxInstalledDriver)
foreach ($driver in $installed) {
    if ($driver.PublishedName -notmatch '^oem\d+\.inf$') { throw "Unsafe published name returned by PnPUtil: $($driver.PublishedName)" }
    $backup = Join-Path (Join-Path (Get-OnyxToolkitRoot) 'work/driverstore-backup') (Get-Date -Format 'yyyyMMdd-HHmmss')
    if ($PSCmdlet.ShouldProcess($driver.PublishedName, "Export and remove verified Onyx driver ($($driver.ProviderName))")) {
        $null = New-Item -ItemType Directory -Path $backup -Force
        Invoke-OnyxExternalCommand -FilePath $pnputil -ArgumentList @('/export-driver', $driver.PublishedName, $backup) | Out-Null
        Invoke-OnyxExternalCommand -FilePath $pnputil -ArgumentList @('/delete-driver', $driver.PublishedName, '/uninstall', '/force') -SuccessExitCodes @(0, 3010) | Out-Null
        Write-OnyxLog -Message "Removed $($driver.PublishedName); Driver Store backup: $backup"
    }
}
$infPath = Join-Path $DriverPath $validation.Definition.infName
if ($PSCmdlet.ShouldProcess($infPath, 'Add and install rebuilt Onyx driver')) {
    $result = Invoke-OnyxExternalCommand -FilePath $pnputil -ArgumentList @('/add-driver', $infPath, '/install') -SuccessExitCodes @(0, 3010)
    Write-OnyxLog -Message "PnPUtil installation result: $($result.ExitCode)"
    Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match '(?i)LOUD|ONYXFIREWIRE' } |
        Format-Table Status, Class, FriendlyName, InstanceId -AutoSize
    if ($result.ExitCode -eq 3010) { Write-OnyxMessage -French 'Redémarrage requis; aucun redémarrage automatique.' -English 'A reboot is required; no automatic reboot was started.' -Kind Warning }
}
