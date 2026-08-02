#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param([string]$DriverPath, [string]$Thumbprint, [string]$SignToolPath)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$DriverPath = Get-OnyxDriverPath $DriverPath
$definition = Get-OnyxSupportedDriver
$catalogPath = Join-Path $DriverPath $definition.catalogFile
if (-not (Test-Path -LiteralPath $catalogPath)) { throw "Catalogue not found: $catalogPath" }
$certificate = Assert-OnyxCertificate -Thumbprint $Thumbprint
if (-not $SignToolPath) { $SignToolPath = (Find-OnyxWindowsDriverTools).SignTool }
if (-not $SignToolPath) { throw 'SignTool.exe was not found.' }
if ($PSCmdlet.ShouldProcess($catalogPath, 'Sign and verify driver catalogue')) {
    Invoke-OnyxExternalCommand -FilePath $SignToolPath -ArgumentList (New-OnyxSignArguments -Thumbprint $certificate.Thumbprint -Path $catalogPath) | Out-Null
    Invoke-OnyxExternalCommand -FilePath $SignToolPath -ArgumentList @('verify', '/v', '/pa', $catalogPath) | Out-Null
    foreach ($name in @($definition.infName) + @($script:OnyxRequiredSysFiles)) {
        $file = Join-Path $DriverPath $name
        Invoke-OnyxExternalCommand -FilePath $SignToolPath -ArgumentList @('verify', '/v', '/pa', '/c', $catalogPath, $file) | Out-Null
    }
    Write-OnyxMessage -French "Catalogue signé. /kp n'est pas attendu avec une racine locale." -English 'Catalogue signed. /kp is not expected to pass with a local self-signed root.' -Kind Success
}
