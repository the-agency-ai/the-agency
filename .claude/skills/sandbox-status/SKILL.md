---
allowed-tools: Bash(readlink:*), Bash(ls:*), Glob
description: Show all active sandbox symlinks and their health (OK or broken)
---

# Sandbox Status

Show all active sandbox symlinks across all engineers.

## Steps

1. **Scan discovery directories** for `usr-*` symlinks:
   - `.claude/commands/usr-*`
   - `.claude/hooks/usr-*`
   - `.claude/hookify.usr-*.local.md`

2. **For each symlink**, resolve the target and check if it exists.

3. **Display table:**

   ```
   Active Sandbox Symlinks:

   Symlink                                        Source                                     Status
   ─────────────────────────────────────────────────────────────────────────────────────────────────
   .claude/commands/usr-jordan.my-thing.md         usr/jordan/claude/commands/my-thing.md      OK
   .claude/hookify.usr-jordan.strict.local.md      usr/jordan/claude/hookify/strict.md         OK
   .claude/commands/usr-alex.quick-deploy.md       usr/alex/claude/commands/quick-deploy.md    BROKEN
   ```

4. **If broken symlinks found:** suggest `/sandbox-deactivate`.

5. **If no symlinks:** report "No active sandbox symlinks."
