---
allowed-tools: Read, Write, Bash(mkdir:*), Bash(touch:*), Bash(cp:*), Bash(ln:*), Bash(ls:*), Bash(readlink:*), Bash(git config:*), Bash(git rev-parse:*), Glob
description: Set up a new engineer's sandbox workspace under usr/
---

# Sandbox Init

Set up a per-engineer sandbox for Claude Code tooling development.

## Arguments

`$ARGUMENTS` is the engineer name (optional — auto-detected from `git config user.name` if omitted).

## Steps

1. **Detect engineer name:**
   - If provided in `$ARGUMENTS`, use it
   - Otherwise: `git config user.name`, lowercase, take first name, replace spaces with hyphens
   - Validate: must match `^[a-z0-9-]+$`

2. **Check if sandbox exists:**
   - If `usr/<name>/` exists and has the full structure, report what's there
   - If partially exists, fill in missing directories

3. **Create directory structure:**

   ```
   usr/<name>/
     claude/
       commands/.gitkeep
       hooks/.gitkeep
       hookify/.gitkeep
       CLAUDE.md
       settings.local.json
     scripts/.gitkeep
     tools/.gitkeep
     README.md
   ```

   Project directories (e.g., `usr/<name>/captain/`, `usr/<name>/folio/`) are created per-project as work begins, not at init time.

4. **Set up CLAUDE.md:**
   - If `~/.claude/CLAUDE.md` exists and is NOT a symlink: copy to sandbox, create symlink back
   - If already a symlink: report where it points, offer to update
   - If doesn't exist: create a starter file and symlink

5. **Set up settings.local.json:**
   - If not present, create with `{}`

6. **Scaffold README:**
   - Create `usr/<name>/README.md` with engineer name and date

7. **Print summary:**

   ```
   Sandbox initialized: usr/<name>/

   Next steps:
     /sandbox-create command my-thing   — create your first experiment
     /sandbox-list                      — see what's available
     /sandbox-try jordan/<command>      — try an existing sandbox command
   ```
