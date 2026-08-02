BeforeAll { . (Join-Path $PSScriptRoot '../scripts/Common.ps1') }

Describe 'Windows driver tool discovery' {
    It 'prefers the newest SDK and x64 SignTool while accepting x86 Inf2Cat' {
        $old = ${env:ProgramFiles(x86)}
        try {
            ${env:ProgramFiles(x86)} = $TestDrive
            $base = Join-Path $TestDrive 'Windows Kits/10/bin'
            foreach ($version in @('10.0.19041.0', '10.0.26100.0')) {
                $null = New-Item -ItemType Directory -Path (Join-Path $base "$version/x64") -Force
                $null = New-Item -ItemType Directory -Path (Join-Path $base "$version/x86") -Force
                $null = New-Item -ItemType File -Path (Join-Path $base "$version/x64/signtool.exe")
                $null = New-Item -ItemType File -Path (Join-Path $base "$version/x86/Inf2Cat.exe")
            }
            $tools = Find-OnyxWindowsDriverTools
            $tools.SignTool | Should -Match '10\.0\.26100\.0[\\/]x64[\\/]signtool\.exe$'
            $tools.Inf2Cat | Should -Match '10\.0\.26100\.0[\\/]x86[\\/]Inf2Cat\.exe$'
        } finally { ${env:ProgramFiles(x86)} = $old }
    }
}
