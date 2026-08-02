#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$tools = Find-OnyxWindowsDriverTools
Write-OnyxLog -Message "SignTool: $($tools.SignTool); Inf2Cat: $($tools.Inf2Cat)"
$tools
