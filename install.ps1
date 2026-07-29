# Windows installer for bat-to-ps1 Claude Code skills
# Run: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

$SkillsDir = "$env:USERPROFILE\.claude\skills"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Installing bat-to-ps1 skills..." -ForegroundColor Cyan

# bat2ps1
$dst = "$SkillsDir\bat2ps1"
if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }
Copy-Item -Path "$ScriptDir\skills\bat2ps1\SKILL.md" -Destination "$dst\SKILL.md" -Force
Write-Host "  [OK] bat2ps1 -> $dst\SKILL.md"

# bat-run
$dst = "$SkillsDir\bat-run"
if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }
Copy-Item -Path "$ScriptDir\skills\bat-run\SKILL.md" -Destination "$dst\SKILL.md" -Force
Write-Host "  [OK] bat-run -> $dst\SKILL.md"

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Usage:"
Write-Host "  /bat2ps1 <path-to-bat-file>    - Create .ps1 wrapper"
Write-Host "  /bat-run  <path-to-bat-file>    - Create + test + auto-fix"
Write-Host ""
Write-Host "Restart Claude Code for the skills to take effect."
