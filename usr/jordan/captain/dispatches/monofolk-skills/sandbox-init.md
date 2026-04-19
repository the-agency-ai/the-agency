---
allowed-tools: Read, Write, Bash(mkdir:*), Bash(touch:*), Bash(cp:*), Bash(mv:*), Bash(ln:*), Bash(ls:*), Bash(readlink:*), Bash(git config:*), Bash(git rev-parse:*), Glob
description: Set up a new engineer's sandbox workspace under usr/
---

# /sandbox-init

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
     claude/
       commands/.gitkeep       — slash commands (activated via symlink)
       hooks/.gitkeep          — hooks
       hookify/.gitkeep        — hookify enforcement rules (activated via symlink)
       CLAUDE.md               — user-level instructions (symlinked to ~/.claude/CLAUDE.md)
       settings.local.json     — local settings overrides
     scripts/.gitkeep          — cross-cutting scripts
     tools/.gitkeep            — cross-cutting tools
     README.md                 — what's being worked on
   ```

   Project directories (e.g., `usr/<name>/folio/`, `usr/<name>/catalog/`) are created per-project as work begins, not at init time. Each project directory holds everything for that project: docs, data, config, code-reviews.

4. **Set up CLAUDE.md:**
   - If `~/.claude/CLAUDE.md` exists and is NOT a symlink:
     - Copy it to `usr/<name>/claude/CLAUDE.md`
     - Create symlink: `ln -sf <absolute-path-to-repo>/usr/<name>/claude/CLAUDE.md ~/.claude/CLAUDE.md`
     - Use `git rev-parse --show-toplevel` to get the absolute repo path
   - If `~/.claude/CLAUDE.md` is already a symlink:
     - Report where it points
     - If it doesn't point to this sandbox, ask if it should be updated
   - If `~/.claude/CLAUDE.md` doesn't exist:
     - Create a starter `usr/<name>/claude/CLAUDE.md` with a header
     - Create the symlink

5. **Set up settings.local.json:**
   - If `usr/<name>/claude/settings.local.json` doesn't exist, create it with `{}`

6. **Run sandbox-sync:**
   - If `usr/<name>/scripts/sandbox-sync.sh` exists (from an existing sandbox), run it to activate all symlinks
   - Otherwise, note that symlinks will be created as commands are added

7. **Scaffold README:**
   - Create `usr/<name>/README.md` with engineer name and date

8. **Print summary:**

   ```
   Sandbox initialized: usr/<name>/

   Structure:
     claude/commands/       — slash commands (activated via symlink)
     agency/hooks/          — hooks
     agency/hookify/        — hookify enforcement rules
     claude/CLAUDE.md       — your user-level instructions (symlinked to ~/.claude/CLAUDE.md)
     claude/settings.local.json — local settings overrides
     scripts/               — cross-cutting scripts
     tools/                 — cross-cutting tools
     {project}/             — created per-project as work begins

   Next steps:
     /sandbox-create command my-thing   — create your first experiment
     /sandbox-list                      — see what's available
     /sandbox-try jordan/<command>      — try an existing sandbox command
   ```
