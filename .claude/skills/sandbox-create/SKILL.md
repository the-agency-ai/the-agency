---
description: Create a new experimental command, hook, rule, tool, or script in your sandbox
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Sandbox Create

Scaffold a new item in your sandbox with collision detection.

## Arguments

`$ARGUMENTS` is `<type> <name>` where:
- **type**: `command`, `hook`, `hookify`, `tool`, `script`
- **name**: kebab-case name (no extension)

## Steps

1. **Parse arguments:** Extract type and name. Validate name matches `^[a-z0-9-]+$`.

2. **Detect engineer:** Scan `usr/*/` directories. If only one, use it. If multiple, match against `git config user.name`.

3. **Collision check:** Search ALL locations for the same name:
   - Shared: `.claude/commands/`, `.claude/hooks/`, `.claude/hookify.*`, `claude/tools/`
   - All sandboxes: `usr/*/claude/commands/`, `usr/*/claude/hooks/`, `usr/*/claude/hookify/`, `usr/*/tools/`, `usr/*/scripts/`
   - If collision found: report WHERE and ask to continue or rename

4. **Scaffold the item** based on type with appropriate template (command .md, hook .sh, hookify .md, tool .ts, script .sh).

5. **Make executable** (hook and script types only).

6. **Print result:**

   ```
   Created: usr/<engineer>/<path>/<name>.<ext>

   Next: edit the file, then activate it:
     /sandbox-activate <name>
   ```
