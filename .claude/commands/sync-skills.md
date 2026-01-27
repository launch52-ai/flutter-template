Sync Flutter template skills to global or a specific project.

Usage:
```bash
# Sync to global (per-skill symlinks)
./sync-skills.sh global

# Sync to a specific project (copies)
./sync-skills.sh /path/to/project

# Sync to current directory (copies)
./sync-skills.sh .
```

**Global:** Creates symlinks per skill to `~/.claude/skills/`. Edits in flutter-template are instantly available everywhere. You can still add custom global skills alongside.

**Project:** Copies skills to project's `.claude/skills/` for git tracking.

Ask the user where they want to sync: global or a specific project path.
