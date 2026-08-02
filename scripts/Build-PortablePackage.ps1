#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$OutputDirectory,
    [string]$Version = '0.1.0',
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
    [string]$ArchiveBaseName
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$root = Get-OnyxToolkitRoot
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $root 'dist' }
if (-not $ArchiveBaseName) { $ArchiveBaseName = "Mackie-Onyx-i-Windows11-Portable-Toolkit-$Version" }
$forbidden = @(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
    $_.FullName -notmatch '[\\/]\.git[\\/]|[\\/]dist[\\/]|[\\/]driver[\\/]|[\\/]work[\\/]|[\\/]logs[\\/]' -and
    $_.Extension -in @('.sys', '.cat', '.dll', '.exe')
})
if ($forbidden.Count) { throw "Proprietary/binary files must not be packaged: $($forbidden.FullName -join ', ')" }
$stage = Join-Path ([IO.Path]::GetTempPath()) "OnyxToolkit-package-$([guid]::NewGuid().ToString('N'))"
$zip = Join-Path $OutputDirectory "$ArchiveBaseName.zip"
if ($PSCmdlet.ShouldProcess($zip, 'Build portable source-only ZIP')) {
    try {
        $null = New-Item -ItemType Directory -Path $stage -Force
        foreach ($item in @('scripts', 'config', 'docs', 'Start-OnyxToolkit.cmd', 'Start-OnyxToolkit.ps1', 'README.md', 'LICENSE', 'CHANGELOG.md', 'SECURITY.md', 'CONTRIBUTING.md', 'CONTEXT.md')) {
            $source = Join-Path $root $item
            if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $stage -Recurse -Force }
        }
        $driverStage = Join-Path $stage 'driver'
        $null = New-Item -ItemType Directory -Path $driverStage -Force
        foreach ($name in @('README.md', 'PLACE_OFFICIAL_DRIVER_FILES_HERE.txt')) {
            Copy-Item -LiteralPath (Join-Path (Join-Path $root 'driver') $name) -Destination $driverStage -Force
        }
        $null = New-Item -ItemType Directory -Path (Join-Path $stage 'logs') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $stage 'work') -Force
        $null = New-Item -ItemType Directory -Path $OutputDirectory -Force
        Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
        $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
        "$hash  $([IO.Path]::GetFileName($zip))" | Out-File -LiteralPath "$zip.sha256" -Encoding ascii
    } finally { if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force } }
}
[pscustomobject]@{ Zip = $zip; SHA256File = "$zip.sha256" }
