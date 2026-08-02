#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$DriverPath,
    [string]$Thumbprint,
    [string]$SignToolPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$DriverPath = Get-OnyxDriverPath $DriverPath
$validation = Test-OnyxDriverFiles -DriverPath $DriverPath
if (-not $validation.Valid) { throw 'Driver package validation failed before signing.' }
$certificate = Assert-OnyxCertificate -Thumbprint $Thumbprint
if (-not $SignToolPath) { $SignToolPath = (Find-OnyxWindowsDriverTools).SignTool }
if (-not $SignToolPath) { throw 'SignTool.exe was not found.' }

$backup = Backup-OnyxDriverPackage -DriverPath $DriverPath -WhatIf:$WhatIfPreference
Write-OnyxLog -Message "Pre-signing backup: $backup"
foreach ($name in $script:OnyxRequiredSysFiles) {
    $path = Join-Path $DriverPath $name
    $before = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($PSCmdlet.ShouldProcess($path, 'Append Authenticode test signature')) {
        Invoke-OnyxExternalCommand -FilePath $SignToolPath -ArgumentList (New-OnyxSignArguments -Thumbprint $certificate.Thumbprint -Path $path -Append) | Out-Null
        $verify = Invoke-OnyxExternalCommand -FilePath $SignToolPath -ArgumentList @('verify', '/v', '/pa', '/all', $path)
        $text = $verify.Output -join "`n"
        if ($text -notmatch '(?i)Onyx Test Driver' -or
            $text -notmatch '(?i)Signature Index:\s*0' -or
            $text -notmatch '(?i)Signature Index:\s*1') {
            throw "Both the historical and appended Onyx signatures were not confirmed for $name."
        }
        $after = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        Write-OnyxLog -Message "$name SHA256 before=$before after=$after"
    }
}
