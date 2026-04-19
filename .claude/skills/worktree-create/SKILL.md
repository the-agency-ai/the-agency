---
description: Create a new git worktree with dedicated branch and bootstrapped dev environment
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Create Worktree

Create a new git worktree under `.claude/worktrees/` with a dedicated branch and bootstrapped dev environment.

## Arguments

- $ARGUMENTS: Two supported forms:
  1. **Ad-hoc worktree:** `<name>` in kebab-case (e.g., `fix-auth-bug`, `refactor-cart`) — for experiments and standalone branches that don't belong to a workstream.
  2. **Workstream agent:** `--workstream <ws> --agent <ag>` — for agents working on a declared workstream. The worktree directory name is computed from these two via the collapse rule below.

  Both forms accept optional `--from <branch>` to branch off a specific ref instead of current HEAD.

## Naming convention (workstream form)

Per the worktree naming convention (dispatches #166, #169), when both `--workstream` and `--agent` are given, the worktree directory name is computed:

```
if agent == workstream OR agent.startswith(workstream + "-"):
    name = agent               # collapse: drop the workstream prefix
else:
    name = "workstream-agent"  # full form: join with hyphen
```

**Examples:**

| Workstream | Agent | Worktree name |
|-----------|-------|---------------|
| `devex` | `devex` | `devex` (exact match → collapse) |
| `iscp` | `iscp` | `iscp` (exact match → collapse) |
| `mdpal` | `mdpal-app` | `mdpal-app` (prefix match → collapse) |
| `mdpal` | `mdpal-cli` | `mdpal-cli` (prefix match → collapse) |
| `agency` | `captain` | `agency-captain` (no match → full form) |
| `fleet` | `captain` | `fleet-captain` (no match → full form) |

The `agency/tools/worktree-create --compute-only --workstream <ws> --agent <ag>` mode prints the computed name without creating anything — useful if you want to check the canonical name before committing to a worktree layout.

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty, ask for either a name OR a workstream+agent pair.

Parse:
- First positional arg is the **name** (ad-hoc form)
- If `--workstream <ws>` and `--agent <ag>` are both present, compute the name via the collapse rule above (workstream agent form)
- If `--from <branch>` is present, record as **base ref**
- Mixing positional name with `--workstream`/`--agent` is an error (ambiguous)
- Legacy: if `--agent <agent-name>` is present WITHOUT `--workstream`, record as **agent name** for identity binding (the tool's `.agency-agent` file handling continues to support this)

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

If `./agency/tools/dependencies-install` exists, run it in the worktree directory to install project dependencies.

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
