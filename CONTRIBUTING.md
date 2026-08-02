# Contributing

Contributions must preserve Windows PowerShell 5.1 compatibility, strict mode,
idempotence, exact package identity checks, `ShouldProcess` on mutations, and the
source-only distribution policy. Put shared behavior in `scripts/Common.ps1`
instead of copying it into entry scripts.

Before submitting:

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error
Invoke-Pester -Path tests -Output Detailed
.\scripts\Build-PortablePackage.ps1 -Version dev
```

Never commit `.sys`, `.cat`, `.dll`, `.exe`, private keys, PFX files, official
installer content, machine logs containing personal data, or manually copied
Windows policy files. Use the compatibility issue form for new hardware results.
Document untested assumptions and update `CONTEXT.md` when a durable design or
compatibility fact changes.
