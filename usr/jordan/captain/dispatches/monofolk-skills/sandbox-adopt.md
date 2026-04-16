---
allowed-tools: Read, Write, Bash(mv:*), Bash(rm:*), Bash(ls:*), Bash(readlink:*), Bash(find:*), Bash(git add:*), Bash(git rev-parse:*), Glob, Grep
description: Graduate a sandbox experiment to shared team-wide tooling
---

# /sandbox-adopt

Move an item from an engineer's sandbox to the shared `.claude/` (or `tools/`/`scripts/`) location, making it team-wide. Cleans up all symlinks.

## Arguments

`$ARGUMENTS` is `<name>` or `<engineer>/<name>`.

## Steps

1. **Find the item** in sandbox directories. If `<engineer>` not specified, search all `usr/*/`.

2. **Determine shared destination** based on type:
   - command: `.claude/commands/<name>.md`
   - hookify: `.claude/hookify.<name>.local.md`
   - hook: `.claude/hooks/<name>.sh`
   - tool: `tools/<name>.ts` (or appropriate extension)
   - script: `scripts/<name>.sh`

3. **Collision check** against the shared destination. If a file already exists there, report and stop.

4. **Find and remove ALL symlinks** to this item:
   - Scan `.claude/commands/usr-*.<name>.md`
   - Scan `.claude/hookify.usr-*.<name>.local.md`
   - Scan `.claude/hooks/usr-*.<name>.sh`
   - Remove only symlinks (safety check with `readlink`)

5. **Move the file** from sandbox to shared location:

   ```
   mv usr/<engineer>/claude/commands/<name>.md .claude/commands/<name>.md
   ```

6. **For hooks:** Also add the hook entry to `.claude/settings.json` and print what was added.

7. **Stage the new file:** `git add <shared-path>`

8. **Update the sandbox README:** Add an entry to the "Adopted" table in `usr/<engineer>/README.md`.

9. **Print summary:**

   ```
   Adopted: <name>
   From: usr/<engineer>/claude/commands/<name>.md
   To: .claude/commands/<name>.md
   Symlinks removed in this checkout: N

   Note: Other engineers who had this activated via /sandbox-try will have
   broken symlinks. They should run /sandbox-status to detect and
   /sandbox-deactivate to clean up.

   The file is staged. Commit when ready.
   ```
