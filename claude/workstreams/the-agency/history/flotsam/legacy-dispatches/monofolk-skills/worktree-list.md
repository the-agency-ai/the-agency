---
allowed-tools: Bash(git worktree:*), Bash(git -C:*), Bash(git rev-parse:*), Bash(git status:*), Bash(ls:*), Bash(doppler configs:*), Read, Glob
description: List all git worktrees with status info (branch, clean/dirty, Doppler, deps)
---

# List Worktrees

Show all git worktrees under `.worktrees/` with their status.

## Instructions

### Step 1: Gather worktree info

Run `git worktree list` to get all registered worktrees.

For each worktree under `.worktrees/`:

1. **Branch** — `git rev-parse --abbrev-ref HEAD` (run in the worktree directory)
2. **Dirty** — `git status --porcelain` (run in the worktree directory). If output is non-empty, it's dirty.
3. **Doppler** — check if `.doppler.yaml` or `apps/backend/.doppler.yaml` exists in the worktree (indicates Doppler was configured)
4. **node_modules** — check if `node_modules/` exists in the worktree

### Step 2: Format output

Present as a table:

```
Worktrees (.worktrees/):

Name              Branch                  Status    Doppler   Deps
─────────────────────────────────────────────────────────────────────
hello-world       proto/hello-world       clean     yes       yes
proto-tooling     proto/proto-tooling     dirty     yes       yes
fix-auth          fix-auth                clean     no        no
```

If there are no worktrees, say "No worktrees found under .worktrees/".

Also mention the main repo worktree (the root) for completeness, but label it as "(main)".

### Step 3: Show switching instructions

After the table, always show:

```
To switch to a worktree, start a new Claude Code session:
  cd .worktrees/<name>/ && claude
There is no built-in tool to switch worktrees mid-session.
```
