---
allowed-tools: Read, Write, Bash(ls:*), Bash(chmod:*), Bash(git config:*), Bash(git rev-parse:*), Glob, Grep
description: Create a new experimental command, hook, rule, tool, or script in your sandbox
---

# /sandbox-create

Scaffold a new item in your sandbox with collision detection.

## Arguments

`$ARGUMENTS` is `<type> <name>` where:

- **type**: `command`, `hook`, `hookify`, `tool`, `script`
- **name**: kebab-case name (no extension)

## Steps

1. **Parse arguments:**
   - Extract type and name from `$ARGUMENTS`
   - Validate name: must match `^[a-z0-9-]+$`
   - Validate type: must be one of the 5 supported types

2. **Detect engineer:**
   - Scan `usr/*/` directories
   - If only one exists, use it
   - If multiple, match against `git config user.name` (lowercased first name)
   - If ambiguous, ask

3. **Collision check** — search ALL of these locations for the same name:
   - **Shared commands:** `.claude/commands/<name>.md`
   - **Shared hooks:** `.claude/hooks/<name>.sh`
   - **Shared hookify:** `.claude/hookify.*<name>*.local.md` (exclude `usr-*` symlinks — those are sandbox activations, not collisions)
   - **Shared tools:** `tools/<name>.ts`
   - **Shared scripts:** `scripts/<name>.sh`
   - **All sandboxes:** `usr/*/claude/commands/<name>.md`, `usr/*/claude/hooks/<name>.sh`, `usr/*/claude/hookify/<name>.md`, `usr/*/tools/<name>.ts`, `usr/*/scripts/<name>.sh`
   - If collision found: report WHERE and ask to continue or rename

4. **Scaffold the item** based on type:

   **command** → `usr/<engineer>/claude/commands/<name>.md`:

   ```markdown
   ---
   allowed-tools: Read, Glob, Grep
   description: <TODO: describe what this command does>
   ---

   # /<name>

   <TODO: describe the command>

   ## Arguments

   `$ARGUMENTS` contains...

   ## Steps

   1. ...
   ```

   **hook** → `usr/<engineer>/claude/hooks/<name>.sh`:

   ```bash
   #!/bin/bash
   # <name>.sh — <TODO: describe>
   #
   # Wired as: <TODO: SessionStart | PreToolUse | PostToolUse | Stop>

   # --- PATH resolution (for non-login shells) ---
   [ -d /opt/homebrew/bin ] && export PATH="/opt/homebrew/bin:$PATH"
   [ -d "$HOME/.asdf/shims" ] && export PATH="$HOME/.asdf/shims:$PATH"

   # jq is required for safe JSON output
   command -v jq >/dev/null 2>&1 || exit 0

   INPUT=$(cat)

   # TODO: implement hook logic

   exit 0
   ```

   **hookify** → `usr/<engineer>/claude/hookify/<name>.md`:

   ```markdown
   ---
   name: <name>
   enabled: true
   event: bash
   pattern: <TODO: regex pattern>
   action: warn
   ---

   **<TODO: warning message title>**

   <TODO: explain what this rule catches and why>
   ```

   **tool** → `usr/<engineer>/tools/<name>.ts`:

   ```typescript
   /**
    * <name> — <TODO: describe>
    *
    * Usage: pnpm tsx usr/<engineer>/tools/<name>.ts [args]
    */

   const args = process.argv.slice(2);

   if (args.length === 0) {
     console.error('Usage: pnpm tsx usr/<engineer>/tools/<name>.ts [args]');
     process.exit(1);
   }

   // TODO: implement
   ```

   **script** → `usr/<engineer>/scripts/<name>.sh`:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   # <name>.sh — <TODO: describe>

   # TODO: implement
   ```

5. **Make executable** (for hook and script types only):

   ```
   chmod +x usr/<engineer>/claude/hooks/<name>.sh
   ```

6. **Print result:**

   ```
   Created: usr/<engineer>/<path>/<name>.<ext>

   Next: edit the file, then activate it:
     /sandbox-activate <name>
   ```
