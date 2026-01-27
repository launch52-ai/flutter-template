#!/bin/bash
# Sync skills from flutter-template to a target location
#
# Usage:
#   ./sync-skills.sh global           # Symlink to ~/.claude/skills/ (per-skill)
#   ./sync-skills.sh /path/to/project # Copy to project/.claude/skills/
#   ./sync-skills.sh .                # Copy to current directory/.claude/skills/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/.claude/skills"

if [ -z "$1" ]; then
    echo "Usage:"
    echo "  ./sync-skills.sh global           # Symlink to ~/.claude/skills/ (per-skill)"
    echo "  ./sync-skills.sh /path/to/project # Copy to project/.claude/skills/"
    echo "  ./sync-skills.sh .                # Copy to current directory"
    exit 1
fi

if [ "$1" = "global" ]; then
    TARGET_DIR="$HOME/.claude/skills"
    USE_SYMLINKS=true
else
    # Resolve to absolute path
    TARGET_PATH="$(cd "$1" 2>/dev/null && pwd)" || { echo "Error: Directory '$1' not found"; exit 1; }
    TARGET_DIR="$TARGET_PATH/.claude/skills"
    USE_SYMLINKS=false
fi

# Create target directory if needed
mkdir -p "$TARGET_DIR"

# Count skills
count=0

echo "Syncing skills to $TARGET_DIR..."
if [ "$USE_SYMLINKS" = true ]; then
    echo "(using symlinks)"
fi
echo ""

for skill in "$SOURCE_DIR"/*/; do
    skill_name=$(basename "$skill")

    if [ "$USE_SYMLINKS" = true ]; then
        # Remove existing (symlink or directory)
        if [ -L "$TARGET_DIR/$skill_name" ] || [ -d "$TARGET_DIR/$skill_name" ]; then
            rm -rf "$TARGET_DIR/$skill_name"
        fi
        # Create symlink
        ln -s "$SOURCE_DIR/$skill_name" "$TARGET_DIR/$skill_name"
        echo "  → $skill_name (symlink)"
    else
        # Copy with rsync
        rsync -a --delete "$SOURCE_DIR/$skill_name/" "$TARGET_DIR/$skill_name/"
        echo "  → $skill_name"
    fi

    ((count++))
done

echo ""
echo "Done! Synced $count skills."
