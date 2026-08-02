#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\Common.ps1')

function Get-ToolkitSummary {
    [CmdletBinding()]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param()

    $tools = Find-OnyxWindowsDriverTools
    $boot = Get-OnyxBootState
    $guard = Get-OnyxDeviceGuardState
    $certificate = Get-OnyxCertificate
    $driverValidation = Test-OnyxDriverFiles -DriverPath (Get-OnyxDriverPath)
    $installed = @(Get-OnyxInstalledDriver)
    $devices = @(Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match '(?i)LOUD|ONYXFIREWIRE' })
    $onyxDevice = @($devices | Where-Object { $_.FriendlyName -notmatch '(?i)Audio' })
    $audioDevice = @($devices | Where-Object { $_.FriendlyName -match '(?i)Audio' })
    $os = Get-CimInstance Win32_OperatingSystem
    $asio = (Test-Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\ASIO\OnyxFireWire ASIO') -or
        (Test-Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ASIO\OnyxFireWire ASIO')
    $summary = [ordered]@{
        'Administrateur / Administrator' = if (Test-OnyxAdministrator) { 'OK' } else { 'ERREUR / ERROR' }
        'Windows 11 x64' = if (([version]$os.Version).Build -ge 22000 -and [Environment]::Is64BitOperatingSystem) { 'OK' } else { 'ERREUR / ERROR' }
        'Secure Boot' = $boot.SecureBoot
        'Test Mode' = $boot.TestSigning
        'VBS' = $guard.VBS
        'HVCI' = $guard.HVCI
        'SignTool' = if ($tools.SignTool) { $tools.SignTool } else { 'ABSENT' }
        'Inf2Cat' = if ($tools.Inf2Cat) { $tools.Inf2Cat } else { 'ABSENT' }
        'Certificat / Certificate' = if ($certificate) { "PRESENT ($($certificate.Thumbprint))" } else { 'ABSENT' }
        'Package officiel / Official package' = if ($driverValidation.Valid) { 'VALIDE / VALID' } else { 'INCOMPLET / INCOMPLETE' }
        'Pilote installé / Driver installed' = if ($installed.Count) { 'OUI / YES' } else { 'NON / NO' }
        'Périphérique Onyx / Onyx device' = if (-not $onyxDevice.Count) { 'ABSENT' } elseif (@($onyxDevice | Where-Object Status -ne 'OK').Count) { 'ERREUR / ERROR' } else { 'OK' }
        'Audio WDM' = if (-not $audioDevice.Count) { 'ABSENT' } elseif (@($audioDevice | Where-Object Status -ne 'OK').Count) { 'ERREUR / ERROR' } else { 'OK' }
        'ASIO' = if ($asio) { 'PRESENT' } else { 'ABSENT / NON VERIFIABLE' }
    }
    Write-OnyxLog -Message "Toolkit summary: $($summary | ConvertTo-Json -Compress)"
    return $summary
}

function Show-ToolkitMenu {
    [CmdletBinding()]
    param()

    Clear-Host
    Write-Host 'Mackie Onyx-i Windows 11 Portable Toolkit' -ForegroundColor Cyan
    Write-Host 'LOCAL TEST SIGNING — NOT SECURE BOOT COMPATIBLE' -ForegroundColor Yellow
    Write-Host 'Not affiliated with Mackie or LOUD Technologies.' -ForegroundColor Yellow
    Write-Host ''
    try {
        (Get-ToolkitSummary).GetEnumerator() | ForEach-Object { Write-Host ('{0,-39} {1}' -f $_.Key, $_.Value) }
    } catch {
        Write-OnyxMessage -French "État partiel indisponible : $($_.Exception.Message)" -English "Some status data is unavailable: $($_.Exception.Message)" -Kind Warning
    }
    Write-Host @'

 1. Vérifier les prérequis / Check prerequisites
 2. Préparer le pilote officiel / Prepare official driver
 3. Créer ou vérifier le certificat / Create or verify certificate
 4. Signer les pilotes SYS / Sign SYS binaries
 5. Régénérer et signer le catalogue / Rebuild and sign catalogue
 6. Installer ou réparer / Install or repair
 7. Diagnostiquer / Diagnose
 8. Activer le mode test / Enable Test Mode
 9. Désactiver le mode test / Disable Test Mode
10. Redémarrer vers l'UEFI / Restart to UEFI
11. Désinstaller / Uninstall
12. Restaurer les fichiers originaux / Restore original files
13. Implications de sécurité / Security implications
 0. Quitter / Exit
'@
}

$null = Initialize-OnyxLog
do {
    Show-ToolkitMenu
    $choice = Read-Host 'Choix / Choice'
    try {
        switch ($choice) {
            '1' { & (Join-Path $PSScriptRoot 'scripts\Check-System.ps1') | Format-List }
            '2' {
                & (Join-Path $PSScriptRoot 'scripts\Validate-DriverFiles.ps1') | Out-Null
                & (Join-Path $PSScriptRoot 'scripts\Backup-DriverPackage.ps1') | Out-Null
                Write-OnyxMessage -French 'Pilote validé et sauvegardé.' -English 'Driver validated and backed up.' -Kind Success
            }
            '3' { & (Join-Path $PSScriptRoot 'scripts\Create-TestCertificate.ps1') | Format-List Subject, Thumbprint, NotAfter, HasPrivateKey }
            '4' { & (Join-Path $PSScriptRoot 'scripts\Sign-DriverBinaries.ps1') }
            '5' {
                & (Join-Path $PSScriptRoot 'scripts\Build-DriverCatalog.ps1') | Out-Null
                & (Join-Path $PSScriptRoot 'scripts\Sign-DriverCatalog.ps1')
            }
            '6' { & (Join-Path $PSScriptRoot 'scripts\Install-OnyxDriver.ps1') }
            '7' { & (Join-Path $PSScriptRoot 'scripts\Diagnose-OnyxDriver.ps1') | Format-List }
            '8' { & (Join-Path $PSScriptRoot 'scripts\Enable-TestMode.ps1') }
            '9' { & (Join-Path $PSScriptRoot 'scripts\Disable-TestMode.ps1') }
            '10' { & (Join-Path $PSScriptRoot 'scripts\Restart-ToUEFI.ps1') }
            '11' { & (Join-Path $PSScriptRoot 'scripts\Uninstall-OnyxDriver.ps1') }
            '12' { & (Join-Path $PSScriptRoot 'scripts\Restore-OriginalDriverFiles.ps1') }
            '13' { Get-Content -LiteralPath (Join-Path $PSScriptRoot 'docs\SECURITY-IMPLICATIONS.md') | Out-Host }
            '0' { continue }
            default { Write-OnyxMessage -French 'Choix invalide.' -English 'Invalid choice.' -Kind Warning }
        }
    } catch {
        Write-OnyxLog -Message $_.Exception.ToString() -Level ERROR
        Write-OnyxMessage -French "Échec : $($_.Exception.Message)" -English "Failed: $($_.Exception.Message)" -Kind Error
    }
    if ($choice -ne '0') { $null = Read-Host 'Entrée pour continuer / Press Enter to continue' }
} while ($choice -ne '0')
