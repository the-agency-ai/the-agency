---
allowed-tools: Bash(ls:*), Bash(find:*), Bash(readlink:*), Bash(git config:*), Glob, Read
description: Show all sandbox items across engineers with activation status
---

# /sandbox-list

Show what's in every engineer's sandbox, with activation status.

## Steps

1. **Detect current engineer:**
   - Match `git config user.name` (lowercased first name) against `usr/*/` directories
   - If no match, show all sandboxes without highlighting "yours"

2. **Scan all sandboxes:**
   - For each `usr/*/` directory, find all items:
     - `usr/<name>/claude/commands/*.md` (commands)
     - `usr/<name>/claude/hooks/*.sh` (hooks)
     - `usr/<name>/claude/hookify/*.md` (hookify rules)
     - `usr/<name>/tools/*` (tools)
     - `usr/<name>/scripts/*` (scripts)
   - Skip `.gitkeep` files

3. **Check activation status:**
   - For each command: does `.claude/commands/usr-<engineer>.<item>.md` exist as a symlink?
   - For each hookify rule: does `.claude/hookify.usr-<engineer>.<item>.local.md` exist as a symlink?
   - For each hook: does `.claude/hooks/usr-<engineer>.<item>.sh` exist as a symlink?
   - For tools/scripts: just show them (activation is PATH-based, not symlink-based)

4. **Display grouped by engineer:**

   ```
   jordan (you):

   Type      Name              Status
   ────────────────────────────────────────
   command   my-workflow       active
   hookify   strict-imports    inactive
   tool      audit-helper      —

   alex:

   Type      Name              Status
   ────────────────────────────────────────
   command   quick-deploy      inactive
   ```

   Mark the current engineer's sandbox with "(you)".
   Tools and scripts show "—" for status (PATH-based, not symlink-tracked).

5. **If no sandboxes exist:**
   ```
   No sandboxes found. Run /sandbox-init to create yours.
   ```
