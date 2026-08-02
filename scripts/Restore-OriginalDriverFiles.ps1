#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param([string]$DriverPath, [string]$BackupPath)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$DriverPath = Get-OnyxDriverPath $DriverPath
if (-not $BackupPath) {
    $root = Join-Path (Get-OnyxToolkitRoot) 'work/backup'
    $latest = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $latest) { throw 'No original-file backup was found.' }
    $BackupPath = $latest.FullName
}
$backupValidation = Test-OnyxDriverFiles -DriverPath $BackupPath
if (-not $backupValidation.Valid) { throw "Backup is not a valid Onyx package: $BackupPath" }
if ($PSCmdlet.ShouldProcess($DriverPath, "Restore original files from $BackupPath")) {
    Get-ChildItem -LiteralPath $BackupPath -File | Copy-Item -Destination $DriverPath -Force
    Write-OnyxLog -Message "Original driver files restored from $BackupPath"
}
