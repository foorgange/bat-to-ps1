# Windows installer for bat-to-ps1 Claude Code skills
# Run: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

$SkillsDir = "$env:USERPROFILE\.claude\skills"

if (-not (Test-Path $SkillsDir)) {
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Installing bat-to-ps1 skills..." -ForegroundColor Cyan

Copy-Item -Path "$ScriptDir\skills\bat2ps1.md" -Destination "$SkillsDir\bat2ps1.md" -Force
Write-Host "  [OK] bat2ps1.md -> $SkillsDir\bat2ps1.md"

Copy-Item -Path "$ScriptDir\skills\bat-run.md" -Destination "$SkillsDir\bat-run.md" -Force
Write-Host "  [OK] bat-run.md -> $SkillsDir\bat-run.md"

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Usage:"
Write-Host "  /bat2ps1 <path-to-bat-file>    - Create .ps1 wrapper"
Write-Host "  /bat-run  <path-to-bat-file>    - Create + test + auto-fix"
Write-Host ""
Write-Host "Restart Claude Code for the skills to take effect."
