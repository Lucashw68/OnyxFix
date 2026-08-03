# Project context memory

This file is the durable context for maintainers and future coding sessions.

## Mission

Build a portable, open-source Windows 11 x64 toolkit that rebuilds and locally
test-signs the user-supplied legacy Mackie Onyx-i FireWire driver. It is not a
driver and does not make the driver compatible with Secure Boot.

## Validated baseline

- Hardware: Mackie Onyx 1640i.
- Driver: 4.1.0.14624, dated 2012-10-03, provider LOUD Technologies Inc.
- The three SYS files must receive an appended (`SignTool /as`) local signature.
- The catalogue must then be regenerated and signed.
- Test Mode must be enabled; Secure Boot must remain disabled.
- HVCI/VBS can still reject the legacy driver.

## Design decisions

- PowerShell 5.1 is the compatibility floor; scripts avoid PowerShell 7-only APIs.
- Shared behavior lives in `scripts/Common.ps1`; entry scripts are thin commands.
- Destructive operations use `SupportsShouldProcess` and validate driver identity.
- Official/proprietary binaries are never committed or packaged.
- The private key remains non-exportable by the toolkit. Only a public CER is exported.
- Runtime artefacts belong in ignored `driver/`, `work/`, and `logs/` directories.
- Tagged releases publish a stable source-only ZIP filename for the README's latest-release link.
- README brand/product imagery is referenced from official Mackie Japan URLs, not redistributed in the repository.
- The Internet Archive driver page is linked as an untrusted third-party source; no automatic download or execution is implemented.
- UI text is concise bilingual French/English where action or risk matters most.

## Known environmental limits

CI can validate parsing, argument construction, repository policy, and package layout.
Signing, BCDEdit, certificate stores, Driver Store mutation, FireWire enumeration,
and actual driver loading require an elevated physical Windows 11 test host.

Update this file whenever a compatibility finding or architecture decision changes.
