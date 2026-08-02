#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param([string]$Thumbprint)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

if (-not $Thumbprint) {
    $certificate = Get-OnyxCertificate
    if (-not $certificate) { Write-OnyxMessage -French 'Aucun certificat trouvé.' -English 'No certificate found.'; return }
    $Thumbprint = $certificate.Thumbprint
}
foreach ($storeName in @('My', 'Root', 'TrustedPublisher')) {
    $path = "Cert:\LocalMachine\$storeName\$Thumbprint"
    if (Test-Path -LiteralPath $path) {
        if ($PSCmdlet.ShouldProcess($path, 'Remove Onyx test certificate')) { Remove-Item -LiteralPath $path -Force }
    }
}
Write-OnyxLog -Message "Removed certificate $Thumbprint from LocalMachine stores."
