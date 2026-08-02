# Error and state reference

| Code/event | Meaning and response |
|---|---|
| SC 4551 | Application Control policy blocked the file. Inspect Code Integrity events and signatures. |
| SC 1058 | Service disabled or no enabled associated device. This can be normal for a PnP driver while the console is disconnected. |
| WIN32_EXIT_CODE 1077 | The driver has not started since the last boot. Connect the device and review PnP state. |
| Event 3004 | Windows could not verify image integrity or a file hash was not found. Rebuild the CAT after the final SYS changes. |
| Event 3076 | Audit-mode policy would have blocked the image but allowed it. Treat as compatibility evidence. |
| Event 3077 | Code Integrity policy blocked the image. Check Test Mode, trust stores, hashes, and catalogue. |
| Event 3111 | Driver is incompatible with hypervisor enforcement. Review HVCI/VBS implications. |
| CM_PROB_PHANTOM | Device is currently absent or disconnected. |
| CM_PROB_NONE | Device is operational. |

Diagnostic conclusions include `READY`, `REBOOT_REQUIRED`,
`SECURE_BOOT_ENABLED`, `TEST_MODE_DISABLED`, `CERTIFICATE_MISSING`,
`CATALOG_INVALID`, `DRIVER_NOT_INSTALLED`, `DEVICE_NOT_CONNECTED`,
`DRIVER_BLOCKED_BY_CODE_INTEGRITY`, `HVCI_INCOMPATIBLE`, `DRIVER_LOADED`, and
`AUDIO_DEVICE_READY`. More than one conclusion can apply simultaneously.
