---
description: Activate a sandbox item by symlinking it to the Claude Code discovery location
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Sandbox Activate

Wire up a sandbox item so Claude Code discovers and uses it.

## Arguments

`$ARGUMENTS` is `<name>` — the item name (without extension).

## Steps

1. **Detect engineer** from `usr/*/` directories.

2. **Find the item** by searching `usr/<engineer>/` for files matching `<name>`:
   - `usr/<engineer>/claude/commands/<name>.md` → command
   - `usr/<engineer>/agency/hooks/<name>.sh` → hook
   - `usr/<engineer>/agency/hookify/<name>.md` → hookify
   - `usr/<engineer>/tools/<name>.*` → tool
   - `usr/<engineer>/scripts/<name>.*` → script

3. **Check for existing symlink.** If one exists, show target and ask to replace.

4. **Create symlink** based on type:
   - command: `ln -sf ../../usr/<engineer>/claude/commands/<name>.md .claude/commands/usr-<engineer>.<name>.md`
   - hookify: `ln -sf ../usr/<engineer>/agency/hookify/<name>.md .claude/hookify.usr-<engineer>.<name>.local.md`
   - hook: create symlink + print the settings.local.json entry needed for manual wiring
   - tool/script: print PATH instruction

5. **Verify** the symlink resolves.

6. **Print confirmation.**
