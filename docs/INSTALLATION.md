# Installation

## Before changing Windows

Back up important data and create a Windows recovery point. Confirm Windows 11
x64, administrator access, Windows PowerShell 5.1+, and install the current
Windows SDK/WDK tools. Obtain the official Onyx-i driver yourself and copy its
extracted files into `driver\`.

Secure Boot must be disabled manually in UEFI. The toolkit can restart to firmware
settings but cannot alter the setting. Test Mode must be enabled. Disable VBS/HVCI
only if the diagnostic identifies Event 3111 or hypervisor incompatibility; doing
so is a separate security decision controlled by Windows settings.

## Guided sequence

Run `Start-OnyxToolkit.cmd`, approve elevation, and use:

1. **Check prerequisites**. Resolve missing SignTool/Inf2Cat and platform errors.
2. **Prepare official driver**. Validation checks required files, INF identity,
   PE headers, amd64 machine type, versions, and SHA-256 hashes, then backs up.
3. **Create certificate**. Note the displayed thumbprint. Only a public CER is exported.
4. **Sign SYS binaries**. The original signature is retained and a second local signature appended.
5. **Rebuild and sign catalogue**. Inf2Cat targets `10_X64`, then every required file is checked against the CAT.
6. **Install or repair**. Power off/unplug the console. The exact installed package
   is exported, removed, and the rebuilt INF installed.
7. Reboot if Windows requests it, reconnect the console, then run **Diagnose**.

A successful 1640i baseline shows operational Onyx FireWire and Onyx FireWire
Audio devices, `CM_PROB_NONE`, an OK `Win32_SoundDevice`, and an ASIO registration.

## Updates and reinstallation

Windows Update can invalidate or remove the package. Re-run diagnostics before
repeating signing. Signing is not blindly idempotent: each `/as` adds a signature,
so restore the backed-up originals before rebuilding a clean package again.
