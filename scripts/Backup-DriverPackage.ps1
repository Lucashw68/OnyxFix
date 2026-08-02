#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param([string]$DriverPath)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$DriverPath = Get-OnyxDriverPath $DriverPath
$validation = Test-OnyxDriverFiles -DriverPath $DriverPath
if (-not $validation.Valid) { throw 'Refusing to back up an invalid driver package.' }
Backup-OnyxDriverPackage -DriverPath $DriverPath -WhatIf:$WhatIfPreference
