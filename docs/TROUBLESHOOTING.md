# Troubleshooting

Run `scripts\Diagnose-OnyxDriver.ps1` and inspect the newest `logs\OnyxToolkit-*.log`.

- **Secure Boot enabled:** disable it manually in UEFI. The toolkit cannot bypass it.
- **Test Mode disabled:** enable it, then reboot. An installed package can remain present while it is off.
- **Certificate missing:** recreate it and rebuild signatures/catalogue; do not import another user's private key.
- **CAT invalid:** restore original files, append SYS signatures once, regenerate the CAT, sign, and verify membership.
- **Event 3004/3077:** compare package and installed SYS hashes and reinstall the rebuilt package.
- **Event 3111:** HVCI/hypervisor enforcement may be incompatible. Decide whether reducing that protection is acceptable.
- **Device absent/phantom:** power-cycle and reconnect FireWire after installation; inspect Device Manager and SetupAPI.
- **WDM works, ASIO absent:** ensure the official optional ASIO companion files were installed by the original package and check both 32/64-bit ASIO registry views.

Do not delete `.cip` policies or randomly remove other MEDIA-class drivers. Do not
assume a Windows update, another Onyx-i model, or another FireWire controller will
behave like the initially validated system.
