# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `/bat-run` skill: creates the wrapper if missing, executes it, and auto-repairs
  a failing wrapper across up to 3 retries (basic fixes -> line-by-line analysis ->
  report with manual fix suggestions).

## [1.0.0] - 2026-07-29

### Added

- `/bat2ps1` skill: generates a `.ps1` wrapper next to any `.bat` file.
- The generated wrapper runs the original `.bat` through `cmd.exe /c`, so BAT
  semantics (`goto`, `call`, `setlocal`, `errorlevel`, nested scripts) stay intact.
- Wrapper features: working-directory parity via `Push-Location`/`Pop-Location`,
  admin-elevation detection (`net`, `sc`, `reg add`, `bcdedit`, ...), space-safe
  quoting, `-BatArgs` argument pass-through, `$LASTEXITCODE` propagation, and
  UTF-8 BOM / UTF-16 encoding handling.
- `install.ps1` and `install.sh` installers that copy the skills into
  `~/.claude/skills/`, plus a one-liner `Invoke-WebRequest | Invoke-Expression`
  install path documented in the README.
- Bilingual README (EN / 中文) with the problem statement, solution overview,
  equivalence guarantee, known limitations, and FAQ.
- `BACKGROUND.md` recording the full 6-round diagnostic history that motivated
  the workaround.

### Known limitations

- Environment variables set with `set` inside the `.bat` do not persist into the
  calling PowerShell session after `cmd.exe /c` exits.
- A wrapper exits when the script finishes; it does not leave an interactive
  shell open.
