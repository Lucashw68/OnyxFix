#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateRange(1, 10)][int]$ValidYears = 3,
    [string]$Subject = 'CN=Onyx Test Driver'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$certificate = Get-OnyxCertificate -Subject $Subject
if ($certificate -and $certificate.NotAfter -gt (Get-Date) -and $certificate.HasPrivateKey) {
    Write-OnyxMessage -French "Certificat existant réutilisé : $($certificate.Thumbprint)" -English "Reusing existing certificate: $($certificate.Thumbprint)" -Kind Success
} else {
    if ($certificate -and -not $PSCmdlet.ShouldContinue('Replace the expired or unusable certificate?', 'Onyx test certificate')) {
        throw 'A usable certificate is required.'
    }
    if ($PSCmdlet.ShouldProcess($Subject, 'Create a non-exportable local-machine code-signing certificate')) {
        $certificate = New-SelfSignedCertificate -Type CodeSigningCert -Subject $Subject `
            -CertStoreLocation 'Cert:\LocalMachine\My' -KeyAlgorithm RSA -KeyLength 4096 `
            -HashAlgorithm SHA256 -KeyExportPolicy NonExportable -NotAfter (Get-Date).AddYears($ValidYears)
    }
}
if (-not $certificate) { return }
if (-not $certificate.HasPrivateKey) { throw 'The certificate has no private key.' }

foreach ($storeName in @('Root', 'TrustedPublisher')) {
    if ($PSCmdlet.ShouldProcess("LocalMachine\$storeName", "Trust public certificate $($certificate.Thumbprint)")) {
        $store = New-Object Security.Cryptography.X509Certificates.X509Store($storeName, 'LocalMachine')
        try { $store.Open('ReadWrite'); $store.Add($certificate) } finally { $store.Close() }
    }
}
$work = Join-Path (Get-OnyxToolkitRoot) 'work'
$null = New-Item -ItemType Directory -Path $work -Force
$cerPath = Join-Path $work 'Onyx-Test-Driver.cer'
if ($PSCmdlet.ShouldProcess($cerPath, 'Export public certificate only')) {
    Export-Certificate -Cert $certificate -FilePath $cerPath -Type CERT -Force | Out-Null
}
Write-OnyxMessage -French "Empreinte du certificat : $($certificate.Thumbprint)" -English "Certificate thumbprint: $($certificate.Thumbprint)" -Kind Success
Write-OnyxLog -Message "Certificate thumbprint: $($certificate.Thumbprint); expires: $($certificate.NotAfter.ToString('o')); public CER: $cerPath"
$certificate
