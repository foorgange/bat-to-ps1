# bat-to-ps1

**Claude Code skills for running `.bat` files via `.ps1` wrappers on Windows.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## The Problem

On some Windows machines, double-clicking `.bat` files opens a terminal but **doesn't execute anything**. The terminal pops up, shows a PowerShell prompt (instead of cmd.exe), and sits there doing nothing — while `.ps1` files work perfectly fine.

After extensive diagnosis (6 rounds — see [BACKGROUND.md](BACKGROUND.md)), the root cause was traced to something below the user-mode registry layer — likely a security software kernel driver or Explorer process hook. The registry, file associations, AppLocker, SRP, and all other user-configurable settings were checked and found to be correct.

## The Workaround

Since `.ps1` files work normally on affected machines, these skills create **`.ps1` wrapper scripts** that execute the original `.bat` file via `cmd.exe /c` in the correct working directory. No BAT syntax conversion is attempted — the wrapper simply calls `cmd.exe` to run the original `.bat`, guaranteeing **100% behavioral equivalence** regardless of script complexity (goto, setlocal, errorlevel checks, etc.).

## Skills

| Skill | Command | What it does |
|-------|---------|-------------|
| `bat2ps1` | `/bat2ps1 <path>` | Creates `_runner.ps1` alongside the `.bat` file |
| `bat-run` | `/bat-run <path>` | Creates wrapper + runs it + auto-fixes errors (up to 3 retries) |

### `/bat2ps1`

```
/bat2ps1 C:\project\setup.bat
```

Creates `C:\project\setup_runner.ps1` — a wrapper that:
- Switches to the `.bat` file's directory
- Calls `cmd.exe /c` on the original `.bat`
- Preserves exit codes
- Auto-detects admin privilege requirements
- Forwards command-line arguments

### `/bat-run`

```
/bat-run C:\project\setup.bat
```

Does everything `/bat2ps1` does, **plus**:
- Executes the wrapper immediately
- Watches for errors
- Auto-fixes the wrapper if anything goes wrong (up to 3 retries)
- If the wrapper already exists, skips creation and just runs the test+fix loop

## Installation

### One-liner (Windows PowerShell)

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/foorgange/bat-to-ps1/main/install.ps1" | Invoke-Expression
```

### Manual

```bash
# Clone the repo
git clone https://github.com/foorgange/bat-to-ps1.git

# Run the installer
# Windows:
powershell -File install.ps1

# macOS / Linux:
bash install.sh
```

The installer copies the skill files to `~/.claude/skills/`.

### Verify

Restart Claude Code, then:

```
/bat2ps1 C:\path\to\any\file.bat
```

## Generated Wrapper Example

For `setup.bat`, the generated `setup_runner.ps1` looks like:

```powershell
[CmdletBinding()]
param([string[]]$BatArgs = @())

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BatPath = Join-Path $ScriptDir "setup.bat"

Push-Location $ScriptDir
try {
    cmd.exe /c "`"$BatPath`" $BatArgs"
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
```

## FAQ

**Q: Does this convert BAT syntax to PowerShell?**
No. The wrapper calls `cmd.exe /c` on the original `.bat` file. This guarantees equivalence for any `.bat` file, no matter how complex.

**Q: What about environment variables set by the .bat file?**
They apply within the `cmd.exe /c` session. For one-shot deployment scripts (`npm install`, `python setup.py`, etc.) this is all you need.

**Q: Does it work with admin-requiring scripts?**
Yes. The skill auto-detects commands like `net start`, `sc`, `reg add`, `bcdedit` and adds self-elevation code.

**Q: Can I double-click the generated .ps1?**
Yes! That's the whole point. Double-click works where double-clicking the original `.bat` didn't.

## License

MIT © [lihe4](https://github.com/foorgange)
