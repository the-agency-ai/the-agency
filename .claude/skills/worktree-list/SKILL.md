---
allowed-tools: Bash(git worktree:*), Bash(git -C:*), Bash(git rev-parse:*), Bash(git status:*), Bash(ls:*), Read, Glob
description: List all git worktrees with status info (branch, clean/dirty, deps)
---

# List Worktrees

Show all git worktrees under `.claude/worktrees/` with their status.

## Instructions

### Step 1: Gather worktree info

Run `git worktree list`. For each worktree under `.claude/worktrees/`:

1. **Branch** — `git rev-parse --abbrev-ref HEAD` (in the worktree)
2. **Dirty** — `git status --porcelain` (in the worktree)
3. **Dependencies** — check if dependency artifacts exist (`node_modules/`, `vendor/`, `.venv/`, etc.)

### Step 2: Format output

```
Worktrees (.claude/worktrees/):

Name              Branch                  Status    Deps
─────────────────────────────────────────────────────────
hello-world       hello-world             clean     yes
fix-auth          fix-auth                dirty     no
```

If no worktrees, say "No worktrees found."

### Step 3: Show instructions

```
To switch to a worktree, start a new Claude Code session:
  cd .claude/worktrees/<name>/ && claude
```
