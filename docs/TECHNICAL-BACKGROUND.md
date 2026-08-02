# Technical background

The original package carried historical signatures from TC Applied Technologies.
On the validated Windows 11 system, rebuilding and signing only the CAT did not
resolve Code Integrity blocks. Each of the three kernel images required an
additional Authenticode signature appended with SignTool `/as`, preserving the
historical signature as index 0 and adding `Onyx Test Driver` as index 1.

Changing a SYS changes its hash, invalidating the old catalogue membership. The
correct dependency order is therefore SYS signing, CAT regeneration with Inf2Cat,
CAT signing, membership verification, and Driver Store reinstall. Reordering these
steps produces a catalogue whose hashes no longer match.

The observed policy GUIDs were:

- `784c4414-79f4-4c32-a6a5-f0fb42a51d0d` — Microsoft Windows Cross Certificates for Code Integrity Exceptions Audit Policy.
- `8f9cb695-5d48-48d6-a329-7202b44607e3` — Microsoft Windows Cross Certificates for Code Integrity Exceptions Policy.

They are diagnostic context, not files to remove. The validated end state included
`CM_PROB_NONE` for Onyx FireWire and Onyx FireWire Audio, an OK LOUD Technologies
sound device, and 16 working ASIO outputs in FL Studio on one Onyx 1640i setup.
