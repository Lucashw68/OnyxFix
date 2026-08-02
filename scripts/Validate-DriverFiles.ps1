#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$DriverPath,
    [switch]$Force
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$DriverPath = Get-OnyxDriverPath $DriverPath
$initial = Test-OnyxDriverFiles -DriverPath $DriverPath
if (-not $initial.Recognized -and $Force) {
    $caption = 'Unrecognized driver / Pilote non reconnu'
    $question = 'The files do not clearly identify an Onyx-i driver. Continue validation anyway? / Continuer malgré tout ?'
    if (-not $PSCmdlet.ShouldContinue($question, $caption)) { throw 'Validation cancelled by user.' }
    $result = Test-OnyxDriverFiles -DriverPath $DriverPath -AllowUnrecognized
} else { $result = $initial }

$result.Files | Format-Table Name, Machine, Version, SHA256 -AutoSize
if (-not $result.Valid) {
    $details = "Missing: $($result.MissingFiles -join ', '); wrong architecture: $($result.WrongArchitecture.Name -join ', '); recognized: $($result.Recognized)"
    throw "Official driver package validation failed. $details"
}
Write-OnyxLog -Message "Driver package valid at $DriverPath. Hashes: $($result.Files | ConvertTo-Json -Compress)"
$result
