---
allowed-tools: Read, Write, Bash(mv:*), Bash(rm:*), Bash(ls:*), Bash(readlink:*), Bash(git add:*), Bash(git rev-parse:*), Glob, Grep
description: Graduate a sandbox experiment to shared team-wide tooling
---

# Sandbox Adopt

Move an item from an engineer's sandbox to the shared location, making it team-wide. Cleans up all symlinks.

## Arguments

`$ARGUMENTS` is `<name>` or `<engineer>/<name>`.

## Steps

1. **Find the item** in sandbox directories.

2. **Determine shared destination:**
   - command: `.claude/commands/<name>.md`
   - hookify: `.claude/hookify.<name>.local.md`
   - hook: `.claude/hooks/<name>.sh`
   - tool: `claude/tools/<name>`
   - script: `scripts/<name>.sh`

3. **Collision check** against destination.

4. **Remove ALL symlinks** to this item across `.claude/`.

5. **Move the file** to the shared location.

6. **Stage the new file:** `git add <shared-path>`

7. **Print summary** including note about broken symlinks for other engineers.
