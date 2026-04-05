---
allowed-tools: Read, Write, Bash(git worktree:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git show-ref:*), Bash(./claude/tools/dependencies-install:*), Glob
description: Create a new git worktree with dedicated branch and bootstrapped dev environment
---

# Create Worktree

Create a new git worktree under `.claude/worktrees/` with a dedicated branch and bootstrapped dev environment.

## Arguments

- $ARGUMENTS: The worktree name in kebab-case (e.g., `fix-auth-bug`, `refactor-cart`). Optionally followed by `--from <branch>` to branch off a specific ref instead of current HEAD.

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty, ask for a name.

Parse:
- First positional arg is the **name**
- If `--from <branch>` is present, record as **base ref**
- If `--agent <agent-name>` is present, record as **agent name** (for identity binding)

### Step 1: Validate the name

1. Must be kebab-case: lowercase letters, numbers, and hyphens only.
2. Check for conflicts:
   - `git worktree list` — abort if `.claude/worktrees/<name>` already exists
   - `git show-ref refs/heads/<name>` — abort if branch exists

### Step 2: Validate base ref (if provided)

If `--from <branch>` was specified: `git rev-parse --verify <branch>` — abort if invalid.

### Step 3: Create branch and worktree

```
git worktree add .claude/worktrees/<name> -b <name> [<base-ref>]
```

### Step 3b: Write .agency-agent identity file

Write the agent name to `.claude/worktrees/<name>/.agency-agent` so `agent-identity` resolves correctly in this worktree.

- If `--agent <agent-name>` was provided, use that
- Otherwise, use the worktree `<name>` as the agent name

```
echo "<agent-name>" > .claude/worktrees/<name>/.agency-agent
```

This file is gitignored (worktrees are local state) but critical for ISCP — without it, the worktree agent resolves as captain.

### Step 4: Bootstrap the worktree

If `./claude/tools/dependencies-install` exists, run it in the worktree directory to install project dependencies.

Otherwise, check for common dependency files and install:
- `package.json` → run the project's package manager install
- `Gemfile` → `bundle install`
- `requirements.txt` → `pip install -r requirements.txt`
- `go.mod` → `go mod download`

### Step 5: Report

```
Worktree created:
  Path:   .claude/worktrees/<name>/
  Branch: <name>
  Base:   <base-ref or current HEAD>

To work in this worktree:
  cd .claude/worktrees/<name>/ && claude
```
