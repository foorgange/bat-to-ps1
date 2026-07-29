#!/usr/bin/env bash
# Unix installer for bat-to-ps1 Claude Code skills
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$SKILLS_DIR"

echo "Installing bat-to-ps1 skills..."

cp "$SCRIPT_DIR/skills/bat2ps1.md" "$SKILLS_DIR/bat2ps1.md"
echo "  [OK] bat2ps1.md -> $SKILLS_DIR/bat2ps1.md"

cp "$SCRIPT_DIR/skills/bat-run.md" "$SKILLS_DIR/bat-run.md"
echo "  [OK] bat-run.md -> $SKILLS_DIR/bat-run.md"

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  /bat2ps1 <path-to-bat-file>    - Create .ps1 wrapper"
echo "  /bat-run  <path-to-bat-file>    - Create + test + auto-fix"
echo ""
echo "Restart Claude Code for the skills to take effect."
