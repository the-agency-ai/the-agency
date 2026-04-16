---
allowed-tools: Bash(ln:*), Bash(ls:*), Bash(readlink:*), Bash(git rev-parse:*), Bash(git config:*), Glob, Read
description: Activate a sandbox item by symlinking it to the Claude Code discovery location
---

# /sandbox-activate

Wire up a sandbox item so Claude Code discovers and uses it.

## Arguments

`$ARGUMENTS` is `<name>` — the item name (without extension).

## Steps

1. **Detect engineer** from `usr/*/` directories (same heuristic as sandbox-create).

2. **Find the item** by searching `usr/<engineer>/` for files matching `<name>`:
   - `usr/<engineer>/claude/commands/<name>.md` → type: command
   - `usr/<engineer>/claude/hooks/<name>.sh` → type: hook
   - `usr/<engineer>/claude/hookify/<name>.md` → type: hookify
   - `usr/<engineer>/tools/<name>.*` → type: tool
   - `usr/<engineer>/scripts/<name>.*` → type: script
   - If multiple matches, ask which to activate

3. **Check for existing symlink** at the target location. If one exists:
   - Show where it currently points (`readlink`)
   - Ask if the user wants to replace it
   - If not, stop

4. **Create symlink** based on type:

   **command:**

   ```
   ln -sf ../../usr/<engineer>/claude/commands/<name>.md .claude/commands/usr-<engineer>.<name>.md
   ```

   **hookify:**

   ```
   ln -sf ../usr/<engineer>/claude/hookify/<name>.md .claude/hookify.usr-<engineer>.<name>.local.md
   ```

   **hook:**
   - Warn: "Raw hooks need manual wiring in `.claude/settings.local.json`. Hookify rules are auto-discovered."
   - Create the symlink anyway: `ln -sf ../../usr/<engineer>/claude/hooks/<name>.sh .claude/hooks/usr-<engineer>.<name>.sh`
   - Print the settings.local.json entry the engineer needs to add manually:
     ```json
     {
       "matcher": "",
       "hooks": [
         {
           "type": "command",
           "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/usr-<engineer>.<name>.sh",
           "timeout": 15
         }
       ]
     }
     ```
   - Note: the symlink is gitignored, the settings.local.json entry is also gitignored

   **tool/script:**
   - Print PATH instruction:

     ```
     Add to your shell profile (~/.zshrc):
       export PATH="$PATH:<absolute-repo-path>/usr/<engineer>/tools"

     Or for this session only:
       PATH="$PATH:<absolute-repo-path>/usr/<engineer>/tools"
     ```

   - Use `git rev-parse --show-toplevel` for the absolute path

5. **Verify** the symlink resolves: `readlink -f <symlink-path>` should point to the sandbox file.

6. **Print confirmation:**

   ```
   Activated: usr-<engineer>.<name>
   Symlink: .claude/commands/usr-<engineer>.<name>.md → usr/<engineer>/claude/commands/<name>.md

   The command /<name> is now available in this session.
   ```
