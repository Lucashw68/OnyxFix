# Manual command-line procedure

Use an elevated Windows PowerShell console from the toolkit directory. The scripts
perform validation and logging around these commands:

```powershell
.\scripts\Check-System.ps1
.\scripts\Validate-DriverFiles.ps1
.\scripts\Backup-DriverPackage.ps1
$cert = .\scripts\Create-TestCertificate.ps1
.\scripts\Sign-DriverBinaries.ps1 -Thumbprint $cert.Thumbprint
.\scripts\Build-DriverCatalog.ps1
.\scripts\Sign-DriverCatalog.ps1 -Thumbprint $cert.Thumbprint
.\scripts\Install-OnyxDriver.ps1
.\scripts\Diagnose-OnyxDriver.ps1
```

Internally, SYS signing is equivalent to:

```text
signtool sign /v /sm /s My /fd SHA256 /sha1 <thumbprint> /as <file.sys>
signtool verify /v /pa /all <file.sys>
Inf2Cat /driver:<driver-folder> /os:10_X64
signtool sign /v /sm /s My /fd SHA256 /sha1 <thumbprint> <catalog.cat>
signtool verify /v /pa /c <catalog.cat> <member-file>
```

Do not substitute a manually supplied `oemXX.inf`. The install/uninstall scripts
enumerate PnPUtil, then require original name `OnyxFireWire.inf`, provider
`LOUD Technologies Inc.`, and a syntactically valid published name before deletion.
The validated sequence uses `bcdedit /set testsigning on`; it does not use
`nointegritychecks` and does not modify Code Integrity policy files.
