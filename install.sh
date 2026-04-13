#!/bin/bash
# Install Joybuy community Claude Code skills into ~/.claude/skills/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude/skills"

mkdir -p "$TARGET_DIR"

SKILLS=(
  "prd-writer"
  "translate-meeting"
)

echo "Installing Joybuy community Claude Code skills..."
echo ""

for skill in "${SKILLS[@]}"; do
  if [ -d "$SCRIPT_DIR/$skill" ]; then
    cp -R "$SCRIPT_DIR/$skill" "$TARGET_DIR/"
    echo "  Installed: $skill"
  else
    echo "  Skipped (not found): $skill"
  fi
done

echo ""
echo "Done. ${#SKILLS[@]} skills installed to $TARGET_DIR"
echo ""
echo "Restart Claude Code (or start a new conversation) for skills to take effect."
echo "Use /prd-writer or /translate-meeting as slash commands."
