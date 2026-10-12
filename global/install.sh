#!/usr/bin/env bash
# Links the versioned global files into ~/.claude and merges settings.json.
# Existing files are moved to *.bak first. Safe to run again.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SOURCE_DIR")"
TARGET_DIR="${CLAUDE_HOME:-$HOME/.claude}"
LINKED_ITEMS=(CLAUDE.md RTK.md CLAUDE-omc.md standards hooks)

mkdir -p "$TARGET_DIR"
for item in "${LINKED_ITEMS[@]}"; do
  target="$TARGET_DIR/$item"
  if [ -e "$target" ] && [ ! -L "$target" ]; then mv "$target" "$target.bak"; fi
  ln -sfn "$SOURCE_DIR/$item" "$target"
  echo "linked $target"
done

# ~/.claude/rules -> repository root (rules/, codex/, global/)
target="$TARGET_DIR/rules"
if [ -e "$target" ] && [ ! -L "$target" ]; then mv "$target" "$target.bak"; fi
ln -sfn "$REPO_DIR" "$target"
echo "linked $target"

# settings.json = existing * base * linux overlay * machine-specific directories
settings="$TARGET_DIR/settings.json"
[ -f "$settings" ] || echo '{}' > "$settings"
tmp="$(mktemp)"
jq -s --arg dir "${PERSONAL_DIR:-$HOME/personal}" \
  '.[0] * .[1] * .[2] * {permissions: {additionalDirectories: [$dir]}}' \
  "$settings" "$SOURCE_DIR/settings.base.json" "$SOURCE_DIR/settings.linux.json" > "$tmp"
mv "$tmp" "$settings"
echo "merged $settings"
