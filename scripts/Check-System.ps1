#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$os = Get-CimInstance Win32_OperatingSystem
$boot = Get-OnyxBootState
$guard = Get-OnyxDeviceGuardState
$tools = Find-OnyxWindowsDriverTools
$certificate = Get-OnyxCertificate
$isWindows11 = ([version]$os.Version).Build -ge 22000
$isX64 = [Environment]::Is64BitOperatingSystem
$result = [pscustomobject]@{
    Administrator = Test-OnyxAdministrator
    Windows11X64 = ($isWindows11 -and $isX64)
    WindowsVersion = $os.Version
    SecureBoot = $boot.SecureBoot
    TestMode = $boot.TestSigning
    VBS = $guard.VBS
    HVCI = $guard.HVCI
    SignTool = $tools.SignTool
    Inf2Cat = $tools.Inf2Cat
    Certificate = if ($certificate) { $certificate.Thumbprint } else { $null }
}
Write-OnyxLog -Message ($result | Format-List | Out-String)
$result
