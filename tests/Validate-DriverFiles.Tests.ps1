BeforeAll {
    . (Join-Path $PSScriptRoot '../scripts/Common.ps1')

    function New-TestPeFile {
        [CmdletBinding()]
        param([string]$Path, [uint16]$Machine = 0x8664)
        $bytes = New-Object byte[] 512
        $bytes[0] = 0x4D; $bytes[1] = 0x5A
        [BitConverter]::GetBytes([uint32]128).CopyTo($bytes, 0x3C)
        $bytes[128] = 0x50; $bytes[129] = 0x45
        [BitConverter]::GetBytes($Machine).CopyTo($bytes, 132)
        [IO.File]::WriteAllBytes($Path, $bytes)
    }
}

Describe 'Official driver validation' {
    BeforeEach {
        $script:package = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $script:package
        @'
[Version]
Signature="$Windows NT$"
Provider="LOUD Technologies Inc."
CatalogFile=OnyxFireWire.cat
DriverVer=10/03/2012,4.1.0.14624
[Manufacturer]
%LOUD%=LOUD,NTamd64
[LOUD.NTamd64]
%Onyx%=Install,1394\LOUD&ONYXI
'@ | Set-Content -LiteralPath (Join-Path $script:package 'OnyxFireWire.inf') -Encoding Ascii
        foreach ($name in @('OnyxFireWire.sys', 'OnyxFireWireAudio.sys', 'OnyxFireWireMidi.sys')) {
            New-TestPeFile (Join-Path $script:package $name)
        }
    }

    It 'accepts a complete recognized amd64 package and computes hashes' {
        $result = Test-OnyxDriverFiles -DriverPath $script:package
        $result.Valid | Should -BeTrue
        $result.Files.Count | Should -Be 4
        ($result.Files | Where-Object Name -eq 'OnyxFireWire.sys').SHA256 | Should -Match '^[A-F0-9]{64}$'
    }

    It 'rejects a missing required SYS file' {
        Remove-Item -LiteralPath (Join-Path $script:package 'OnyxFireWireMidi.sys')
        $result = Test-OnyxDriverFiles -DriverPath $script:package
        $result.Valid | Should -BeFalse
        $result.MissingFiles | Should -Contain 'OnyxFireWireMidi.sys'
    }

    It 'rejects a 32-bit SYS file' {
        New-TestPeFile (Join-Path $script:package 'OnyxFireWireAudio.sys') 0x014c
        $result = Test-OnyxDriverFiles -DriverPath $script:package
        $result.Valid | Should -BeFalse
        $result.WrongArchitecture.Name | Should -Contain 'OnyxFireWireAudio.sys'
    }
}
