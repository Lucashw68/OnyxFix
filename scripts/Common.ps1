#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Shared constants are intentionally centralized to keep command scripts small.
$script:OnyxCertificateSubject = 'CN=Onyx Test Driver'
$script:OnyxRequiredSysFiles = @('OnyxFireWire.sys', 'OnyxFireWireAudio.sys', 'OnyxFireWireMidi.sys')
$script:OnyxLogPath = $null

function Get-OnyxToolkitRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return (Split-Path -Parent $PSScriptRoot)
}

function Get-OnyxDriverPath {
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$Path)

    if ($Path) { return [IO.Path]::GetFullPath($Path) }
    return (Join-Path (Get-OnyxToolkitRoot) 'driver')
}

function Initialize-OnyxLog {
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$LogDirectory = (Join-Path (Get-OnyxToolkitRoot) 'logs'))

    if (-not (Test-Path -LiteralPath $LogDirectory)) {
        $null = New-Item -ItemType Directory -Path $LogDirectory -Force
    }
    if (-not $script:OnyxLogPath) {
        $name = 'OnyxToolkit-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss')
        $script:OnyxLogPath = Join-Path $LogDirectory $name
        $header = @(
            'Mackie Onyx-i Windows 11 Portable Toolkit'
            "Date: $(Get-Date -Format 'o')"
            "User: $([Environment]::UserDomainName)\$([Environment]::UserName)"
            "OS: $([Environment]::OSVersion.VersionString)"
            "Architecture: $env:PROCESSOR_ARCHITECTURE"
        )
        $header | Out-File -LiteralPath $script:OnyxLogPath -Encoding utf8
    }
    return $script:OnyxLogPath
}

function Write-OnyxLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')][string]$Level = 'INFO'
    )

    $path = Initialize-OnyxLog
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'o'), $Level, $Message
    $line | Out-File -LiteralPath $path -Encoding utf8 -Append
}

function Write-OnyxMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$French,
        [Parameter(Mandatory)][string]$English,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')][string]$Kind = 'Info'
    )

    $text = if ([Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName -eq 'fr') {
        $French
    } else { $English }
    $color = @{ Info = 'Gray'; Warning = 'Yellow'; Error = 'Red'; Success = 'Green' }[$Kind]
    Write-Host $text -ForegroundColor $color
    Write-OnyxLog -Message "$French / $English" -Level $(if ($Kind -eq 'Error') { 'ERROR' } elseif ($Kind -eq 'Warning') { 'WARN' } else { 'INFO' })
}

function Test-OnyxAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function ConvertTo-OnyxCommandLine {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string[]]$ArgumentList)

    return (($ArgumentList | ForEach-Object {
        if ($_ -match '[\s"]') { '"{0}"' -f ($_ -replace '"', '\"') } else { $_ }
    }) -join ' ')
}

function Invoke-OnyxExternalCommand {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [int[]]$SuccessExitCodes = @(0),
        [switch]$SensitiveArguments
    )

    $display = if ($SensitiveArguments) { '[arguments redacted]' } else { ConvertTo-OnyxCommandLine $ArgumentList }
    Write-OnyxLog -Message "Execute: $FilePath $display"
    $output = & $FilePath @ArgumentList 2>&1 | ForEach-Object { $_.ToString() }
    $exitCode = $LASTEXITCODE
    if ($output) { Write-OnyxLog -Message ($output -join [Environment]::NewLine) }
    if ($SuccessExitCodes -notcontains $exitCode) {
        throw "External command failed ($exitCode): $FilePath $display`n$($output -join [Environment]::NewLine)"
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = @($output); Command = "$FilePath $display" }
}

function Get-OnyxSupportedDriver {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([string]$ConfigurationPath = (Join-Path (Get-OnyxToolkitRoot) 'config/supported-drivers.json'))

    if (-not (Test-Path -LiteralPath $ConfigurationPath -PathType Leaf)) {
        throw "Configuration not found: $ConfigurationPath"
    }
    $config = Get-Content -LiteralPath $ConfigurationPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($config.schemaVersion -ne 1 -or -not $config.drivers -or $config.drivers.Count -lt 1) {
        throw 'Unsupported or empty supported-drivers.json.'
    }
    return $config.drivers[0]
}

function Get-OnyxInfMetadata {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$Path)

    $content = Get-Content -LiteralPath $Path -Raw
    $getValue = {
        param([string]$Name)
        $match = [regex]::Match($content, "(?im)^\s*$([regex]::Escape($Name))\s*=\s*([^;\r\n]+)")
        if ($match.Success) { return $match.Groups[1].Value.Trim().Trim('"') }
        return $null
    }
    $driverVer = & $getValue 'DriverVer'
    $provider = & $getValue 'Provider'
    $catalog = & $getValue 'CatalogFile'
    return [pscustomobject]@{
        DriverVer = $driverVer
        Provider = $provider
        CatalogFile = $catalog
        Content = $content
    }
}

function Get-OnyxPeMachine {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$Path)

    $stream = [IO.File]::OpenRead($Path)
    try {
        $reader = New-Object IO.BinaryReader($stream)
        if ($reader.ReadUInt16() -ne 0x5A4D) { return 'Invalid' }
        $stream.Position = 0x3C
        $peOffset = $reader.ReadUInt32()
        if ($peOffset -gt ($stream.Length - 6)) { return 'Invalid' }
        $stream.Position = $peOffset
        if ($reader.ReadUInt32() -ne 0x00004550) { return 'Invalid' }
        $machine = $reader.ReadUInt16()
        switch ($machine) {
            0x8664 { return 'amd64' }
            0x014c { return 'x86' }
            0xAA64 { return 'arm64' }
            default { return ('unknown-0x{0:X4}' -f $machine) }
        }
    } finally { $stream.Dispose() }
}

function Test-OnyxDriverFiles {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$DriverPath,
        [switch]$AllowUnrecognized
    )

    $definition = Get-OnyxSupportedDriver
    $missing = @($definition.requiredFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $DriverPath $_) -PathType Leaf) })
    $files = @()
    foreach ($name in @($definition.requiredFiles + $definition.optionalFiles)) {
        $path = Join-Path $DriverPath $name
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $files += [pscustomobject]@{
                Name = $name
                SHA256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
                Version = (Get-Item -LiteralPath $path).VersionInfo.FileVersion
                Machine = if ([IO.Path]::GetExtension($name) -in @('.sys', '.dll', '.exe')) { Get-OnyxPeMachine $path } else { $null }
            }
        }
    }
    $infPath = Join-Path $DriverPath $definition.infName
    $metadata = if (Test-Path -LiteralPath $infPath) { Get-OnyxInfMetadata $infPath } else { $null }
    $wrongArchitecture = @($files | Where-Object { $_.Name -in $script:OnyxRequiredSysFiles -and $_.Machine -ne 'amd64' })
    $recognized = $false
    if ($metadata) {
        $recognized = ($metadata.Content -match '(?i)OnyxFireWire|LOUD.*ONYX') -and
            ($metadata.Provider -match '(?i)LOUD|Mackie|TC Applied')
    }
    $valid = ($missing.Count -eq 0 -and $wrongArchitecture.Count -eq 0 -and ($recognized -or $AllowUnrecognized))
    return [pscustomobject]@{
        Valid = $valid; MissingFiles = $missing; WrongArchitecture = $wrongArchitecture
        Recognized = $recognized; Inf = $metadata; Files = $files; Definition = $definition
    }
}

function Find-OnyxWindowsDriverTools {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $kitsRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits/10/bin'
    $versions = if (Test-Path -LiteralPath $kitsRoot) {
        @(Get-ChildItem -LiteralPath $kitsRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^10\.\d+' } | Sort-Object { [version]$_.Name } -Descending)
    } else { @() }
    $signTool = $null
    $inf2Cat = $null
    foreach ($version in $versions) {
        if (-not $signTool) {
            $candidate = Join-Path (Join-Path $version.FullName 'x64') 'signtool.exe'
            if (Test-Path -LiteralPath $candidate) { $signTool = $candidate }
        }
        if (-not $inf2Cat) {
            foreach ($arch in @('x86', 'x64')) {
                $candidate = Join-Path (Join-Path $version.FullName $arch) 'Inf2Cat.exe'
                if (Test-Path -LiteralPath $candidate) { $inf2Cat = $candidate; break }
            }
        }
    }
    if (-not $signTool) { $signTool = (Get-Command signtool.exe -ErrorAction SilentlyContinue).Source }
    if (-not $inf2Cat) { $inf2Cat = (Get-Command Inf2Cat.exe -ErrorAction SilentlyContinue).Source }
    return [pscustomobject]@{ SignTool = $signTool; Inf2Cat = $inf2Cat; KitsRoot = $kitsRoot }
}

function Get-OnyxCertificate {
    [CmdletBinding()]
    [OutputType([Security.Cryptography.X509Certificates.X509Certificate2])]
    param([string]$Subject = $script:OnyxCertificateSubject)

    return @(Get-ChildItem Cert:\LocalMachine\My -CodeSigningCert -ErrorAction SilentlyContinue |
        Where-Object { $_.Subject -eq $Subject } | Sort-Object NotAfter -Descending)[0]
}

function Backup-OnyxDriverPackage {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$DriverPath,
        [string]$BackupRoot = (Join-Path (Get-OnyxToolkitRoot) 'work/backup')
    )

    $destination = Join-Path $BackupRoot (Get-Date -Format 'yyyyMMdd-HHmmss')
    if ($PSCmdlet.ShouldProcess($destination, 'Back up official driver files')) {
        $null = New-Item -ItemType Directory -Path $destination -Force
        Get-ChildItem -LiteralPath $DriverPath -Force | Copy-Item -Destination $destination -Recurse -Force
        Write-OnyxLog -Message "Driver backup created: $destination"
    }
    return $destination
}

function ConvertFrom-OnyxPnpUtilDrivers {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param([Parameter(Mandatory)][AllowEmptyString()][string[]]$Lines)

    $map = @{
        'published name'='PublishedName'; 'nom publié'='PublishedName'; 'original name'='OriginalName'; "nom d'origine"='OriginalName'
        'provider name'='ProviderName'; 'nom du fournisseur'='ProviderName'; 'class name'='ClassName'; 'nom de classe'='ClassName'
        'class guid'='ClassGuid'; 'guid de classe'='ClassGuid'; 'driver version'='DriverVersion'; 'version du pilote'='DriverVersion'
        'signer name'='SignerName'; 'nom du signataire'='SignerName'; 'attributes'='Attributes'; 'attributs'='Attributes'
    }
    $items = @(); $current = @{}
    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($current.Count) { $items += [pscustomobject]$current; $current = @{} }
            continue
        }
        $match = [regex]::Match($line, '^\s*([^:]+?)\s*:\s*(.*)$')
        if ($match.Success) {
            $key = $match.Groups[1].Value.Trim().ToLowerInvariant()
            if ($map.ContainsKey($key)) { $current[$map[$key]] = $match.Groups[2].Value.Trim() }
        }
    }
    if ($current.Count) { $items += [pscustomobject]$current }
    return @($items)
}

function Get-OnyxInstalledDriver {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param([string[]]$PnpUtilOutput)

    if (-not $PnpUtilOutput) {
        $PnpUtilOutput = (Invoke-OnyxExternalCommand -FilePath "$env:SystemRoot\System32\pnputil.exe" -ArgumentList @('/enum-drivers')).Output
    }
    return @(ConvertFrom-OnyxPnpUtilDrivers $PnpUtilOutput | Where-Object {
        $_.PSObject.Properties.Name -contains 'OriginalName' -and $_.OriginalName -ieq 'OnyxFireWire.inf' -and
        $_.PSObject.Properties.Name -contains 'ProviderName' -and $_.ProviderName -match '(?i)^LOUD Technologies Inc\.?$'
    })
}

function Get-OnyxBootState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $secureBoot = 'Unknown'
    try { $secureBoot = if (Confirm-SecureBootUEFI) { 'Enabled' } else { 'Disabled' } } catch { }
    $bcd = @()
    try { $bcd = (Invoke-OnyxExternalCommand -FilePath "$env:SystemRoot\System32\bcdedit.exe" -ArgumentList @('/enum', '{current}')).Output } catch { }
    $testSigning = if (($bcd -join "`n") -match '(?im)^testsigning\s+(yes|oui)') { 'Enabled' } else { 'Disabled' }
    return [pscustomobject]@{ SecureBoot = $secureBoot; TestSigning = $testSigning; BcdEdit = $bcd }
}

function Get-OnyxDeviceGuardState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    try {
        $guard = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName Win32_DeviceGuard
        return [pscustomobject]@{
            VBS = if ($guard.VirtualizationBasedSecurityStatus -eq 2) { 'Enabled' } else { 'Disabled' }
            HVCI = if (@($guard.SecurityServicesRunning) -contains 2) { 'Enabled' } else { 'Disabled' }
            Raw = $guard
        }
    } catch { return [pscustomobject]@{ VBS = 'Unknown'; HVCI = 'Unknown'; Raw = $null } }
}

function New-OnyxSignArguments {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)][string]$Thumbprint,
        [Parameter(Mandatory)][string]$Path,
        [switch]$Append
    )

    $arguments = @('sign', '/v', '/sm', '/s', 'My', '/fd', 'SHA256', '/sha1', $Thumbprint)
    if ($Append) { $arguments += '/as' }
    $arguments += $Path
    return $arguments
}

function Assert-OnyxCertificate {
    [CmdletBinding()]
    [OutputType([Security.Cryptography.X509Certificates.X509Certificate2])]
    param([string]$Thumbprint)

    $certificate = if ($Thumbprint) { Get-Item "Cert:\LocalMachine\My\$Thumbprint" -ErrorAction SilentlyContinue } else { Get-OnyxCertificate }
    if (-not $certificate -or -not $certificate.HasPrivateKey -or $certificate.NotAfter -le (Get-Date)) {
        throw 'A valid Onyx test certificate with its private key is required.'
    }
    return $certificate
}
