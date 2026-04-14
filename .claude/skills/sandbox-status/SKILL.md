---
description: Show all active sandbox symlinks and their health (OK or broken)
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

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
   .claude/commands/usr-alice.my-thing.md           usr/alice/claude/commands/my-thing.md       OK
   .claude/hookify.usr-alice.strict.local.md       usr/alice/claude/hookify/strict.md          OK
   .claude/commands/usr-bob.quick-deploy.md        usr/bob/claude/commands/quick-deploy.md     BROKEN
   ```

4. **If broken symlinks found:** suggest `/sandbox-deactivate`.

5. **If no symlinks:** report "No active sandbox symlinks."
