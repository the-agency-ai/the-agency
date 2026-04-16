---
allowed-tools: Read, Bash(git worktree:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git show-ref:*), Bash(bash scripts/worktree-bootstrap.sh *)
description: Create a new git worktree with full dev environment (Doppler, pnpm, Prisma)
---

# Create Worktree

Create a new git worktree under `.worktrees/` with a dedicated branch and fully bootstrapped dev environment.

## Arguments

- $ARGUMENTS: The worktree name in kebab-case (e.g., `fix-auth-bug`, `refactor-cart`). Optionally followed by `--from <branch>` to branch off a specific ref instead of current HEAD.

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Ask: "What should the worktree be called? (kebab-case, e.g., `fix-auth-bug`)"

Parse the arguments:

- First positional arg is the **name**
- If `--from <branch>` is present, record that as the **base ref**

### Step 1: Validate the name

1. The name must be kebab-case: lowercase letters, numbers, and hyphens only. No dots, no slashes.
2. Check for conflicts:
   - `git worktree list` — abort if `.worktrees/<name>` already exists
   - `git show-ref refs/heads/<name>` — abort if a branch with this name already exists
   - `git show-ref refs/heads/proto/<name>` — abort if a prototype branch with this name exists (prototypes use the `proto/` prefix)
3. If the name starts with `proto/` or `prototype`, warn the user: "This looks like a prototype — did you mean `/prototype-create`?" and ask to confirm.

### Step 2: Validate the base ref (if provided)

If `--from <branch>` was specified:

1. `git rev-parse --verify <branch>` — abort if the ref doesn't exist
2. Report: "Branching from `<branch>`"

### Step 3: Create branch and worktree

If a base ref was provided:

1. `git worktree add .worktrees/<name> -b <name> <base-ref>`

Otherwise:

1. `git worktree add .worktrees/<name> -b <name>`

### Step 4: Bootstrap the worktree

Run `bash scripts/worktree-bootstrap.sh .worktrees/<name>/`

This configures Doppler, installs pnpm dependencies, generates Prisma clients, and runs a smoke lint check.

### Step 5: Report success

Print a summary:

```
Worktree created:
  Path:   .worktrees/<name>/
  Branch: <name>
  Base:   <base-ref or current HEAD>

To work in this worktree:
  cd .worktrees/<name>/ && claude
```
