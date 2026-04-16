---
allowed-tools: Bash(rm:*), Bash(ls:*), Bash(readlink:*), Bash(find:*), Glob
description: Remove a sandbox symlink to deactivate an experimental item
---

# /sandbox-deactivate

Remove the symlink for a sandbox item, deactivating it.

## Arguments

`$ARGUMENTS` is `<name>` — the item name.

## Steps

1. **Find all symlinks** matching this name in discovery directories:
   - `.claude/commands/usr-*.<name>.md`
   - `.claude/hooks/usr-*.<name>.sh`
   - `.claude/hookify.usr-*.<name>.local.md`

2. **Safety check:** For each match, verify it IS a symlink (`readlink`). Never remove regular files.

3. **Show what will be removed** and confirm:

   ```
   Will deactivate:
     .claude/commands/usr-jordan.my-thing.md → usr/jordan/claude/commands/my-thing.md

   The source file in your sandbox is NOT deleted.
   ```

4. **Remove the symlinks.**

5. **Print confirmation:**
   ```
   Deactivated: <name>
   Source still at: usr/<engineer>/claude/commands/<name>.md
   ```
