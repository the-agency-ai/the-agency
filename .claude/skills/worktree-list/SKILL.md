---
allowed-tools: Bash(git worktree:*), Bash(git -C:*), Bash(git rev-parse:*), Bash(git status:*), Bash(ls:*), Read, Glob
description: List all git worktrees with status info (branch, clean/dirty, deps)
---

# List Worktrees

Show all git worktrees under `.claude/worktrees/` with their status.

## Instructions

### Step 1: Gather worktree info

Run `git worktree list`. For each worktree under `.claude/worktrees/`:

1. **Agent** — read `.claude/worktrees/<name>/.agency-agent` if it exists (the bound agent identity). If missing, show `(unbound)`.
2. **Branch** — `git rev-parse --abbrev-ref HEAD` (in the worktree)
3. **Dirty** — `git status --porcelain` (in the worktree)
4. **Dependencies** — check if dependency artifacts exist (`node_modules/`, `vendor/`, `.venv/`, etc.)

### Step 2: Format output

```
Worktrees (.claude/worktrees/):

Name              Agent         Branch                  Status    Deps
──────────────────────────────────────────────────────────────────────
hello-world       hello-world   hello-world             clean     yes
mdpal             mdpal-cli     mdpal                   clean     yes
fix-auth          (unbound)     fix-auth                dirty     no
```

If no worktrees, say "No worktrees found."

### Step 3: Show instructions

```
To switch to a worktree, start a new Claude Code session:
  cd .claude/worktrees/<name>/ && claude
```
