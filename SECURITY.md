# Security policy

## Reporting a vulnerability

Do not open a public issue for a vulnerability involving command injection,
certificate private-key exposure, unsafe driver deletion, or privilege escalation.
Use the repository host's private security advisory feature. Include the affected
version, reproduction steps, impact, and a proposed mitigation if available.

## Security boundary

This toolkit performs privileged operations only after explicit user action. It
creates a local, non-exportable code-signing key in `LocalMachine\My`, copies the
public certificate to `LocalMachine\Root` and `LocalMachine\TrustedPublisher`, and
exports only a public `.cer`. It never creates or exports a PFX and never logs a
private key or password.

Test Mode and disabling Secure Boot weaken the platform trust boundary. Only use
this toolkit on a machine whose risk you understand. Do not distribute your local
certificate or key, and do not use the certificate to sign unrelated software.

To retire the setup:

1. uninstall the verified Onyx package if no longer needed;
2. run `scripts\Remove-TestCertificate.ps1` as administrator;
3. run `scripts\Disable-TestMode.ps1` and reboot;
4. re-enable Secure Boot manually in UEFI;
5. restore original driver files from `work\backup` if needed.

Never delete Windows `.cip` policy files. The validated procedure does not require
`nointegritychecks`; the toolkit intentionally does not set it.
