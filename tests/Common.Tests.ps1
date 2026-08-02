BeforeAll {
    . (Join-Path $PSScriptRoot '../scripts/Common.ps1')
}

Describe 'Common toolkit helpers' {
    It 'quotes external command arguments containing spaces' {
        ConvertTo-OnyxCommandLine @('/driver:C:\Onyx Driver', '/os:10_X64') |
            Should -Be '"/driver:C:\Onyx Driver" /os:10_X64'
    }

    It 'builds append-signing arguments without a timestamp or private-key export' {
        $args = New-OnyxSignArguments -Thumbprint 'ABC123' -Path 'C:\Driver\OnyxFireWire.sys' -Append
        $args | Should -Be @('sign', '/v', '/sm', '/s', 'My', '/fd', 'SHA256', '/sha1', 'ABC123', '/as', 'C:\Driver\OnyxFireWire.sys')
        $args | Should -Not -Contain '/f'
        $args | Should -Not -Contain '/p'
    }

    It 'parses the supported-driver schema' {
        $driver = Get-OnyxSupportedDriver
        $driver.infName | Should -Be 'OnyxFireWire.inf'
        $driver.requiredFiles.Count | Should -Be 4
        $driver.architectures | Should -Contain 'amd64'
    }

    It 'parses every PowerShell file without syntax errors' {
        $root = Split-Path -Parent $PSScriptRoot
        foreach ($file in Get-ChildItem -LiteralPath $root -Filter '*.ps1' -Recurse) {
            $tokens = $null; $errors = $null
            $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
            $errors | Should -BeNullOrEmpty -Because $file.FullName
        }
    }
}
