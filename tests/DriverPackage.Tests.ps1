BeforeAll { . (Join-Path $PSScriptRoot '../scripts/Common.ps1') }

Describe 'PnPUtil parsing and driver deletion safety' {
    It 'contains the complete portable package structure' {
        $root = Split-Path -Parent $PSScriptRoot
        $required = @(
            'Start-OnyxToolkit.cmd', 'Start-OnyxToolkit.ps1', 'README.md', 'SECURITY.md',
            'config/supported-drivers.json', 'scripts/Common.ps1',
            'scripts/Diagnose-OnyxDriver.ps1', 'docs/INSTALLATION.md',
            'driver/PLACE_OFFICIAL_DRIVER_FILES_HERE.txt'
        )
        foreach ($relative in $required) {
            Test-Path -LiteralPath (Join-Path $root $relative) | Should -BeTrue -Because $relative
        }
    }

    It 'parses English PnPUtil output and keeps the expected fields' {
        $lines = @(
            'Published Name: oem42.inf', 'Original Name: OnyxFireWire.inf',
            'Provider Name: LOUD Technologies Inc.', 'Class Name: MEDIA',
            'Class GUID: {4d36e96c-e325-11ce-bfc1-08002be10318}',
            'Driver Version: 10/03/2012 4.1.0.14624', 'Signer Name: Onyx Test Driver', 'Attributes: Legacy', ''
        )
        $item = @(ConvertFrom-OnyxPnpUtilDrivers $lines)[0]
        $item.PublishedName | Should -Be 'oem42.inf'
        $item.SignerName | Should -Be 'Onyx Test Driver'
    }

    It 'parses French PnPUtil output' {
        $lines = @("Nom publié : oem7.inf", "Nom d'origine : OnyxFireWire.inf", 'Nom du fournisseur : LOUD Technologies Inc.', '')
        $item = @(ConvertFrom-OnyxPnpUtilDrivers $lines)[0]
        $item.OriginalName | Should -Be 'OnyxFireWire.inf'
    }

    It 'filters a non-Onyx MEDIA driver even when its class matches' {
        $lines = @('Published Name: oem9.inf', 'Original Name: OtherAudio.inf', 'Provider Name: LOUD Technologies Inc.', 'Class Name: MEDIA', '')
        @(Get-OnyxInstalledDriver -PnpUtilOutput $lines).Count | Should -Be 0
    }

    It 'declares SupportsShouldProcess on destructive scripts' {
        foreach ($name in @('Install-OnyxDriver.ps1', 'Uninstall-OnyxDriver.ps1', 'Restore-OriginalDriverFiles.ps1')) {
            $command = Get-Command (Join-Path $PSScriptRoot "../scripts/$name")
            $command.Parameters.Keys | Should -Contain 'WhatIf'
        }
    }

    It 'does not create a portable archive with WhatIf' {
        $output = Join-Path $TestDrive 'dist'
        & (Join-Path $PSScriptRoot '../scripts/Build-PortablePackage.ps1') -OutputDirectory $output -WhatIf | Out-Null
        Test-Path -LiteralPath $output | Should -BeFalse
    }
}
