---
description: Try another engineer's sandbox experiment by symlinking it locally
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Sandbox Try

Activate another engineer's experiment in your local environment.

## Arguments

`$ARGUMENTS` is `<engineer>/<name>` — e.g., `jordan/my-workflow` or `alex/quick-deploy`.

## Steps

1. **Parse arguments:** Split on `/` to get engineer and item name.

2. **Verify the item exists** in `usr/<engineer>/`. If not found, show what IS in that sandbox.

3. **Check for conflicts:** Is there already an active symlink with the same name?

4. **Create symlink** using the **author's** prefix (not yours):
   - The symlink name is `usr-<author>.<name>` regardless of who activates
   - Same type-specific handling as `/sandbox-activate`

5. **Print confirmation:**

   ```
   Trying: <engineer>/<name>
   Symlink: .claude/commands/usr-<engineer>.<name>.md → usr/<engineer>/claude/commands/<name>.md

   This is <engineer>'s experiment. To stop: /sandbox-deactivate <name>
   ```
