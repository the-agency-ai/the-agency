---
allowed-tools: Bash(ln:*), Bash(ls:*), Bash(readlink:*), Bash(git rev-parse:*), Glob, Read
description: Try another engineer's sandbox experiment by symlinking it locally
---

# /sandbox-try

Activate another engineer's experiment in your local environment.

## Arguments

`$ARGUMENTS` is `<engineer>/<name>` — e.g., `jordan/my-workflow` or `alex/quick-deploy`.

## Steps

1. **Parse arguments:** Split on `/` to get engineer and item name.

2. **Verify the item exists** in `usr/<engineer>/`:
   - Search across all type directories (commands, hooks, hookify, tools, scripts)
   - If not found, show what IS in that engineer's sandbox

3. **Check for conflicts:**
   - Is there already an active symlink with the same name? (from your own sandbox or another engineer's)
   - If so, report the conflict and ask to deactivate first

4. **Create symlink** using the **author's** prefix (not yours):
   - The symlink name is `usr-<author>.<name>` regardless of who is activating
   - Same relative path logic as `/sandbox-activate`
   - Same type-specific handling (commands get symlinks, tools get PATH instructions)

5. **Print confirmation:**

   ```
   Trying: <engineer>/<name>
   Symlink: .claude/commands/usr-<engineer>.<name>.md → usr/<engineer>/claude/commands/<name>.md

   This is <engineer>'s experiment. Changes should be committed to usr/<engineer>/.
   To stop using it: /sandbox-deactivate <name>
   ```

## Notes

- The prefix identifies the author, not you — so everyone trying the same experiment has the same symlink name
- If you find bugs, commit fixes to `usr/<engineer>/` (sandboxes are collaborative)
- To stop using it: `/sandbox-deactivate <name>`
