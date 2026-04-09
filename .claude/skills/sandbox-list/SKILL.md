---
description: Show all sandbox items across engineers with activation status
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Sandbox List

Show what's in every engineer's sandbox, with activation status.

## Steps

1. **Detect current engineer** from `git config user.name` matched against `usr/*/`.

2. **Scan all sandboxes** for items:
   - `usr/<name>/claude/commands/*.md`
   - `usr/<name>/claude/hooks/*.sh`
   - `usr/<name>/claude/hookify/*.md`
   - `usr/<name>/tools/*`
   - `usr/<name>/scripts/*`
   - Skip `.gitkeep` files

3. **Check activation status** for each item (symlink exists in `.claude/`).

4. **Display grouped by engineer:**

   ```
   jordan (you):

   Type      Name              Status
   ────────────────────────────────────────
   command   my-workflow       active
   hookify   strict-imports    inactive
   tool      audit-helper      —
   ```

5. **If no sandboxes:** suggest `/sandbox-init`.
