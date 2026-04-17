---
description: Set up a new engineer's sandbox workspace under usr/
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Sandbox Init

Set up a per-engineer sandbox for Claude Code tooling development.

## Arguments

`$ARGUMENTS` is the engineer name (optional — auto-detected from `git config user.name` if omitted).

## Steps

1. **Detect engineer name:**
   - If provided in `$ARGUMENTS`, use it
   - Otherwise: `git config user.name`, lowercase, take first name, replace spaces with hyphens
   - Validate: must match `^[a-z0-9-]+$`

2. **Check if sandbox exists:**
   - If `usr/<name>/` exists and has the full structure, report what's there
   - If partially exists, fill in missing directories

3. **Create directory structure:**

   ```
   usr/<name>/
     commands/.gitkeep
     hooks/.gitkeep
     hookify/.gitkeep
     agents/.gitkeep
     scripts/.gitkeep
     tools/.gitkeep
     CLAUDE.md
     settings.local.json
     README.md
   ```

   > D44-R4 (#420): `commands/`, `hooks/`, `hookify/`, `agents/` live at the
   > sandbox root — NOT under a `claude/` subdirectory. This matches what
   > `claude/tools/sandbox-sync` reads from (it symlinks these into
   > `.claude/` discovery locations). `CLAUDE.md` and `settings.local.json`
   > also live at the sandbox root so `sandbox-sync` can find
   > `settings.local.json` at `usr/<name>/settings.local.json`.

   Project directories (e.g., `usr/<name>/captain/`, `usr/<name>/folio/`) are created per-project as work begins, not at init time.

4. **Set up CLAUDE.md:**
   - If `~/.claude/CLAUDE.md` exists and is NOT a symlink: copy to `usr/<name>/CLAUDE.md`, create symlink from `~/.claude/CLAUDE.md` back
   - If already a symlink: report where it points, offer to update
   - If doesn't exist: create a starter file at `usr/<name>/CLAUDE.md` and symlink

5. **Set up settings.local.json:**
   - Create `usr/<name>/settings.local.json` with `{}` if not present
   - (sandbox-sync will symlink this into `.claude/settings.local.json` in each worktree)

6. **Scaffold README:**
   - Create `usr/<name>/README.md` with engineer name and date

7. **Print summary:**

   ```
   Sandbox initialized: usr/<name>/

   Next steps:
     /sandbox-create command my-thing   — create your first experiment
     /sandbox-list                      — see what's available
     /sandbox-try jordan/<command>      — try an existing sandbox command
   ```
