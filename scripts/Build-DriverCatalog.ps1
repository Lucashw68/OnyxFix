#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param([string]$DriverPath, [string]$Inf2CatPath)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$DriverPath = Get-OnyxDriverPath $DriverPath
$validation = Test-OnyxDriverFiles -DriverPath $DriverPath
if (-not $validation.Valid) { throw 'Driver package validation failed before catalogue generation.' }
if (-not $Inf2CatPath) { $Inf2CatPath = (Find-OnyxWindowsDriverTools).Inf2Cat }
if (-not $Inf2CatPath) { throw 'Inf2Cat.exe was not found.' }
$catalogPath = Join-Path $DriverPath $validation.Definition.catalogFile
if (Test-Path -LiteralPath $catalogPath) {
    $backupCatalog = "$catalogPath.pre-rebuild-$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
    if ($PSCmdlet.ShouldProcess($catalogPath, "Back up old catalogue to $backupCatalog")) { Copy-Item -LiteralPath $catalogPath -Destination $backupCatalog }
}
if ($PSCmdlet.ShouldProcess($DriverPath, 'Generate Windows 10 x64 driver catalogue')) {
    $run = Invoke-OnyxExternalCommand -FilePath $Inf2CatPath -ArgumentList @("/driver:$DriverPath", '/os:10_X64')
    if (($run.Output -join "`n") -match '(?im)\bwarning\b|\bavertissement\b') { throw 'Inf2Cat completed with warnings; inspect the log.' }
    if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) { throw "Inf2Cat did not create $catalogPath." }
    Write-OnyxLog -Message "Catalogue generated: $catalogPath; SHA256=$((Get-FileHash $catalogPath -Algorithm SHA256).Hash)"
}
$catalogPath
