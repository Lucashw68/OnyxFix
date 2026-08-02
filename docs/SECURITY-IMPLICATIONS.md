# Security implications

Secure Boot accepts only a controlled boot trust chain. A locally generated test
certificate is not a Microsoft production-signing root, so Secure Boot must remain
disabled while this driver loads. Test Mode tells Windows to permit test-signed
kernel code and visibly reduces the assurance provided by normal Code Integrity.

The certificate is generated independently on every machine as RSA 4096/SHA-256.
Its private key is placed in `LocalMachine\My` with non-exportable policy. The
public certificate is trusted locally in Root and TrustedPublisher; only that
public portion is exported to `work\Onyx-Test-Driver.cer`. Sharing the certificate
is unnecessary, and sharing a private key would allow others to impersonate its
signer. No key, password, or PFX belongs in a repository or release.

VBS and HVCI add another enforcement boundary. Disable them only when Event 3111
or diagnostics show they block this legacy binary, and only after understanding
the wider impact. The working procedure does not require `nointegritychecks`.
Never delete Microsoft Code Integrity `.cip` policies: that is unsupported,
unnecessary here, and can damage Windows security or servicing.

To reverse the changes, uninstall the precisely identified package, optionally
restore original files, remove the local certificate, disable Test Mode, reboot,
and re-enable Secure Boot in UEFI. Windows updates may break compatibility at any
time. Use a dedicated/offline audio workstation if the reduced security posture
is unacceptable on a general-purpose machine.
