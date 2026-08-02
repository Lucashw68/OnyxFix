#Requires -Version 5.1
[CmdletBinding()]
param([string]$DriverPath, [ValidateRange(1, 30)][int]$EventLookbackDays = 7)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$DriverPath = Get-OnyxDriverPath $DriverPath
$boot = Get-OnyxBootState
$guard = Get-OnyxDeviceGuardState
$certificate = Get-OnyxCertificate
$installed = @(Get-OnyxInstalledDriver)
$devices = @(Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match '(?i)LOUD|ONYXFIREWIRE' })
$audio = @(Get-CimInstance Win32_SoundDevice -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)Onyx' -or $_.Manufacturer -match '(?i)LOUD' })
$services = @(foreach ($name in @('OnyxFireWire', 'OnyxFireWireAudio', 'OnyxFireWireMidi')) {
    Get-CimInstance Win32_SystemDriver -Filter "Name='$name'" -ErrorAction SilentlyContinue
})
$events = @(Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-CodeIntegrity/Operational'; StartTime = (Get-Date).AddDays(-$EventLookbackDays)
} -ErrorAction SilentlyContinue | Where-Object { $_.Message -match '(?i)OnyxFireWire|TC Applied|LOUD' } | Select-Object -First 100)
$setupLog = Join-Path $env:SystemRoot 'INF\setupapi.dev.log'
$setupMatches = @()
if (Test-Path -LiteralPath $setupLog) {
    $setupMatches = @(Select-String -LiteralPath $setupLog -Pattern 'OnyxFireWire|LOUD' -Context 2, 4 -ErrorAction SilentlyContinue | Select-Object -Last 20)
}
$hashComparisons = @()
foreach ($name in $script:OnyxRequiredSysFiles) {
    $source = Join-Path $DriverPath $name
    $installedPath = Join-Path $env:SystemRoot "System32\drivers\$name"
    $hashComparisons += [pscustomobject]@{
        Name = $name
        PackageHash = if (Test-Path $source) { (Get-FileHash $source -Algorithm SHA256).Hash } else { $null }
        InstalledHash = if (Test-Path $installedPath) { (Get-FileHash $installedPath -Algorithm SHA256).Hash } else { $null }
    }
}
$asioPaths = @(
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\ASIO\OnyxFireWire ASIO',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ASIO\OnyxFireWire ASIO'
)
$asioPresent = @($asioPaths | Where-Object { Test-Path $_ }).Count -gt 0
$blocked = @($events | Where-Object { $_.Id -in @(3004, 3077, 3111) }).Count -gt 0
$catalogPath = Join-Path $DriverPath (Get-OnyxSupportedDriver).catalogFile
$catalogValid = if (Test-Path -LiteralPath $catalogPath) {
    (Get-AuthenticodeSignature -FilePath $catalogPath).Status -eq 'Valid'
} else { $false }
$rebootPending = (Test-Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
    (Test-Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
$conclusions = New-Object Collections.Generic.List[string]
if ($rebootPending) { $conclusions.Add('REBOOT_REQUIRED') }
if ($boot.SecureBoot -eq 'Enabled') { $conclusions.Add('SECURE_BOOT_ENABLED') }
if ($boot.TestSigning -ne 'Enabled') { $conclusions.Add('TEST_MODE_DISABLED') }
if (-not $certificate) { $conclusions.Add('CERTIFICATE_MISSING') }
if (-not $catalogValid) { $conclusions.Add('CATALOG_INVALID') }
if ($installed.Count -eq 0) { $conclusions.Add('DRIVER_NOT_INSTALLED') }
if ($devices.Count -eq 0) { $conclusions.Add('DEVICE_NOT_CONNECTED') }
if ($blocked) { $conclusions.Add('DRIVER_BLOCKED_BY_CODE_INTEGRITY') }
if ($guard.HVCI -eq 'Enabled' -and @($events | Where-Object Id -eq 3111).Count) { $conclusions.Add('HVCI_INCOMPATIBLE') }
if (@($services | Where-Object State -eq 'Running').Count) { $conclusions.Add('DRIVER_LOADED') }
if (@($audio | Where-Object Status -eq 'OK').Count) { $conclusions.Add('AUDIO_DEVICE_READY') }
$prerequisitesReady = -not $rebootPending -and $boot.SecureBoot -ne 'Enabled' -and
    $boot.TestSigning -eq 'Enabled' -and $certificate -and $catalogValid -and $installed.Count -gt 0 -and -not $blocked
if ($prerequisitesReady) { $conclusions.Insert(0, 'READY') }

$result = [pscustomobject]@{
    Conclusion = @($conclusions); Boot = $boot; DeviceGuard = $guard; Certificate = $certificate
    DriverStore = $installed; Services = $services; Devices = $devices; Audio = $audio; ASIO = $asioPresent; CatalogValid = $catalogValid
    Hashes = $hashComparisons; CodeIntegrityEvents = $events; SetupApiMatches = $setupMatches
}
Write-OnyxLog -Message "Diagnostic result: $($result.Conclusion -join ', '); DriverStore=$($installed.Count); Devices=$($devices.Count); Audio=$($audio.Count); ASIO=$asioPresent"
$events | ForEach-Object { Write-OnyxLog -Message "CodeIntegrity Event $($_.Id): $($_.Message)" -Level WARN }
$result
