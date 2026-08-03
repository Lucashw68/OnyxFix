<div align="center">
  <a href="https://mackie-jp.com/mixers/onyxiseries/onyx1640i/">
    <img src="https://mackie-jp.com/images/nav/mackie_logo.gif" alt="Mackie" height="52">
  </a>
  <br><br>
  <img src="https://mackie-jp.com/images/products/onyxi/1640i_mast.jpg" alt="Mackie Onyx 1640i FireWire Recording Mixer" width="760">
  <br><br>
  <img src="https://mackie-jp.com/images/products/onyxi/1640i_on.gif" alt="Mackie Onyx 1640i overview" height="300">
  &nbsp;&nbsp;
  <img src="https://mackie-jp.com/images/products/onyxi/Onyx%201640i%20Top.jpg" alt="Mackie Onyx 1640i top view" height="300">
</div>

# OnyxFix - Mackie Onyx-i Windows 11 Portable Toolkit

> **Security warning:** this toolkit requires Windows Test Mode and Secure Boot to
> remain disabled while the legacy driver is loaded. Test signing reduces Windows
> security. Read [the security implications](docs/SECURITY-IMPLICATIONS.md) first.

This toolkit automates a locally test-signed installation of the legacy Mackie
Onyx-i FireWire driver. **It does not make the driver Secure Boot compatible.**
It is a recovery/installation automation toolkit, not a new driver and not a
Secure Boot bypass.

**Not affiliated with Mackie or LOUD Technologies.** This unofficial community
project is not developed, approved, supported, or endorsed by Mackie or LOUD
Technologies. Product images and trademarks shown above belong to their respective
owners and are referenced from the official Mackie Japan website for identification.

## Download

[![Download latest portable ZIP](https://img.shields.io/badge/download-latest_portable_ZIP-0969da?logo=github)](https://github.com/Lucashw68/OnyxFix/releases/latest/download/Mackie-Onyx-i-Windows11-Portable-Toolkit.zip)

- [Download the latest portable toolkit](https://github.com/Lucashw68/OnyxFix/releases/latest/download/Mackie-Onyx-i-Windows11-Portable-Toolkit.zip)
- [Download its SHA-256 checksum](https://github.com/Lucashw68/OnyxFix/releases/latest/download/Mackie-Onyx-i-Windows11-Portable-Toolkit.zip.sha256)
- [Browse all releases](https://github.com/Lucashw68/OnyxFix/releases)

The release is source-only and contains no proprietary Mackie/LOUD driver files.
After downloading, extract the ZIP and place your legally obtained official files
in `driver\` before launching the toolkit.

## Obtaining the legacy driver

A community-uploaded copy of the Onyx FireWire v4.1 package is currently listed
on [Internet Archive](https://archive.org/details/onyx-fire-wire-v-4.1). This is a
third-party archival source, not an official toolkit mirror or endorsement. Its
contents, rights status, integrity, and continued availability are controlled by
the uploader and Internet Archive. Check that you are permitted to download and
use it in your jurisdiction.

OnyxFix does not download, bundle, execute, or redistribute this archive. Always
compare its SHA-256 before using it. The following values were observed on
2026-08-03; they no longer apply if the Internet Archive files change.

| Internet Archive file | SHA-256 | VirusTotal |
|---|---|---|
| `OnyxFireWire-v4.1-Extracted-Drivers.zip` | `baa49c22c7063dcf8fe7d04b97e27a3a9e4720be7df0807990e161e11cd1b8bf` | [View report / search hash](https://www.virustotal.com/gui/file/baa49c22c7063dcf8fe7d04b97e27a3a9e4720be7df0807990e161e11cd1b8bf) |
| `OnyxFireWire-v4.1-Installer.zip` | `d44c41f948fbf4812afad9f30af0f1744b66494fe638ee887e9da4e34a45f602` | [View report / search hash](https://www.virustotal.com/gui/file/d44c41f948fbf4812afad9f30af0f1744b66494fe638ee887e9da4e34a45f602) |

These links query VirusTotal by hash and do not upload the archives. VirusTotal may
show no report until someone submits the exact file. No detection score is embedded
because reports can change as antivirus engines are updated. A clean report lowers
risk but does not prove that an old kernel driver is safe or compatible.

The extracted-drivers ZIP was also inspected on 2026-08-03. It contains the eight
expected Onyx package files, `cpl.defs`, and the original release-notes document;
the previously observed uninstall and Vista installer artefacts are no longer
present. Copy only the expected files listed below into `driver\`.

## Why this project ?

I have a Mackie Onyx 1640i console and wanted to use it with Windows 11 x64.

## Why its needed ?

Because the original Onyx-i driver was last updated in 2012, it is not compatible with Windows 11 x64 Secure Boot. The driver is blocked by Code Integrity and
cannot be loaded. This toolkit automates a locally test-signed installation of the original driver so that it can be used on Windows 11 x64 with Secure Boot disabled. It backs up the supplied files before appending signatures to the working SYS copies; it does not make the driver Secure Boot compatible.

## Compatibility status

| Model | Status | Driver baseline |
|---|---|---|
| Onyx 1640i | Initially validated | 4.1.0.14624, 2012-10-03 |
| Onyx 820i | Designed for future testing | Not validated |
| Onyx 1220i | Designed for future testing | Not validated |
| Onyx 1620i | Designed for future testing | Not validated |

No universal compatibility is claimed. Windows updates, host FireWire chipsets,
firmware, VBS/HVCI, and application behavior can change the result.

## Workflow

```mermaid
flowchart LR
  A[User-supplied official files] --> B[Validate + backup]
  B --> C[Create local non-exportable certificate]
  C --> D[Append signature to 3 SYS files]
  D --> E[Rebuild and sign CAT]
  E --> F[Verify exact old Driver Store package]
  F --> G[Export, remove, reinstall]
  G --> H[Diagnose CI, PnP, WDM and ASIO]
```

The repository and OnyxFix releases contain no Mackie/LOUD/TC Applied driver, installer,
DLL, SYS, INF, CAT, or proprietary executable. You must obtain the official files
yourself and place them in `driver\`.

## Requirements

- Windows 11 x64 and Windows PowerShell 5.1 or newer;
- administrator access;
- Secure Boot disabled manually in UEFI;
- Windows Test Mode enabled;
- VBS/HVCI disabled only if diagnostics show hypervisor enforcement blocks the driver;
- Windows SDK/WDK, or at least `SignTool.exe` and `Inf2Cat.exe`.

The initially validated package contains `OnyxFireWire.inf`,
`OnyxFireWire.sys`, `OnyxFireWireAudio.sys`, and `OnyxFireWireMidi.sys`.
Optional companion files are listed in [driver/README.md](driver/README.md).

## Quick start

1. Download the portable ZIP above, or clone this source-only repository.
2. Copy your personally obtained official driver files into `driver\`.
3. Right-click `Start-OnyxToolkit.cmd` and run it, or double-click it and approve elevation.
4. Run menu items 1 through 7 in order. Enable Test Mode and configure UEFI when required.
5. Reconnect/power on the console only when the installation step tells you to do so.

For the full sequence, expected reboots, and tool installation, see
[INSTALLATION.md](docs/INSTALLATION.md). The exact command-line equivalent is in
[MANUAL-PROCEDURE.md](docs/MANUAL-PROCEDURE.md).

## Rollback

Use menu item 11 to remove only the precisely matched Onyx package, item 12 to
restore the latest original-file backup, and item 9 to disable Test Mode. After
reboot, re-enable Secure Boot manually in UEFI if your machine supports it.
Removing the test certificate is deliberately separate:

```powershell
.\scripts\Remove-TestCertificate.ps1
```

The driver may remain in the Driver Store while Test Mode is off; it will not load
after reboot until Test Mode is enabled again and Secure Boot is disabled, subject
to later Windows compatibility changes.

## FAQ

**Does this preserve Secure Boot?** No. A locally self-signed test certificate
does not chain to a Microsoft production root.

**Why is signing only the CAT insufficient?** The validated 2012 package was also
blocked on its kernel images. Appending a second Authenticode signature to all
three SYS files, then rebuilding the CAT, was required.

**Why `/as`?** It appends the local signature and preserves the historical TC
Applied Technologies signature where SignTool supports the existing image.

**Why does `/kp` fail?** `/kp` validates production kernel-mode policy. A local
self-signed test root is intentionally not a Microsoft production root; the
toolkit uses `/pa` and catalogue membership checks for this test-signing workflow.

**Does FL Studio/ASIO always expose 16 outputs?** It did on the validated 1640i
system. The toolkit can detect the ASIO registration but cannot guarantee every
DAW, routing mode, or other model.

## Known errors and support

Start with [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) and
[ERROR-CODES.md](docs/ERROR-CODES.md). Diagnostic logs are written beside the
toolkit under `logs\`; review them before sharing and never upload proprietary
driver files. Security issues follow [SECURITY.md](SECURITY.md).

Contributions and new compatibility reports are welcome; see
[CONTRIBUTING.md](CONTRIBUTING.md). Every report must state the exact model,
driver version, Windows build, FireWire controller, Secure Boot, Test Mode, VBS,
and HVCI state.

## Packaging

On Windows PowerShell:

```powershell
.\scripts\Build-PortablePackage.ps1 -Version 0.1.0
```

The command creates a versioned source-only ZIP and adjacent SHA-256 file in `dist\`.
Release builds use a stable filename so the README download link always targets
the newest tagged release.
