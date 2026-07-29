#!/usr/bin/env bash
# Unix installer for bat-to-ps1 Claude Code skills
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$SKILLS_DIR"

echo "Installing bat-to-ps1 skills..."

cp -r "$SCRIPT_DIR/skills/bat2ps1" "$SKILLS_DIR/bat2ps1"
echo "  [OK] bat2ps1 -> $SKILLS_DIR/bat2ps1/SKILL.md"

cp -r "$SCRIPT_DIR/skills/bat-run" "$SKILLS_DIR/bat-run"
echo "  [OK] bat-run -> $SKILLS_DIR/bat-run/SKILL.md"

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  /bat2ps1 <path-to-bat-file>    - Create .ps1 wrapper"
echo "  /bat-run  <path-to-bat-file>    - Create + test + auto-fix"
echo ""
echo "Restart Claude Code for the skills to take effect."
