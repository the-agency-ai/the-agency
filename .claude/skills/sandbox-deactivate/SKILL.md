---
allowed-tools: Bash(rm:*), Bash(ls:*), Bash(readlink:*), Glob
description: Remove a sandbox symlink to deactivate an experimental item
---

# Sandbox Deactivate

Remove the symlink for a sandbox item, deactivating it. The source file is NOT deleted.

## Arguments

`$ARGUMENTS` is `<name>` — the item name.

## Steps

1. **Find all symlinks** matching this name:
   - `.claude/commands/usr-*.<name>.md`
   - `.claude/hooks/usr-*.<name>.sh`
   - `.claude/hookify.usr-*.<name>.local.md`

2. **Safety check:** Verify each match IS a symlink. Never remove regular files.

3. **Show what will be removed** and confirm.

4. **Remove the symlinks.**

5. **Print confirmation** with source file location.
