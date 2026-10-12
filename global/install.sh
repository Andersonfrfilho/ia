#!/usr/bin/env bash
# Links the versioned global files into ~/.claude; existing files are moved to *.bak first.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${CLAUDE_HOME:-$HOME/.claude}"
LINKED_ITEMS=(CLAUDE.md RTK.md CLAUDE-omc.md standards hooks)

mkdir -p "$TARGET_DIR"
for item in "${LINKED_ITEMS[@]}"; do
  target="$TARGET_DIR/$item"
  if [ -e "$target" ] && [ ! -L "$target" ]; then mv "$target" "$target.bak"; fi
  ln -sfn "$SOURCE_DIR/$item" "$target"
  echo "linked $target"
done
