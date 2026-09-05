# Security Policy

## Scope

This covers the skills (`/bat2ps1`, `/bat-run`), the installers (`install.ps1`,
`install.sh`), and the wrapper scripts they generate.

It does **not** cover the behaviour of the `.bat` files you point the tool at.
A wrapper is a thin `cmd.exe /c` passthrough: whatever the original `.bat` does,
the wrapper does. If you would not double-click the `.bat`, do not run the wrapper.

## Known design properties (not vulnerabilities)

These are deliberate trade-offs already documented in the README; please read them
before filing a report.

| Property | Detail |
|---|---|
| **Arbitrary code execution by design** | The generated wrapper executes the adjacent `.bat` file with `cmd.exe`. This is the entire purpose of the project. |
| **Self-elevation** | The skill inspects the `.bat` for commands such as `net`, `sc`, `reg add`, and `bcdedit`, and may emit a wrapper that re-launches itself elevated. A UAC prompt is expected in that path. |
| **`Invoke-Expression` install** | The one-liner in the README pipes a remote script into `Invoke-Expression`. This trusts `raw.githubusercontent.com` over TLS. If that trust model is unacceptable, use the `git clone` + `install.ps1` path and inspect the script first. |
| **Working directory** | Wrappers `Push-Location` to the `.bat`'s directory before running it, matching double-click semantics. A `.bat` that writes relative paths writes next to itself. |

## Reporting a vulnerability

Report privately via **GitHub's "Report a vulnerability" form** on this repository
(Security tab), or by opening a private fork. Do not open a public issue for a
live security problem.

Include:

1. Which component: `install.ps1`, `install.sh`, `/bat2ps1`, `/bat-run`, or a
   generated wrapper.
2. The `.bat` input (or a minimal stand-in) that triggers it.
3. Windows edition and terminal, since the underlying `.bat` interception this
   project works around is machine-specific.

## Response target

This is a personal, unmaintained-by-SLA project. I aim to acknowledge reports
within a week, but I make no commitment to that.

## Unsupported versions

Only `main` is supported. Fixing older states means fixing `main`.
