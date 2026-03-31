---
allowed-tools: Read, Glob, Grep, Bash(pnpm lint:*), Bash(pnpm typecheck:*), Bash(pnpm run test:*), Bash(git status:*), Bash(git push:*), Bash(git branch:*)
description: Run checks and push a prototype branch to origin for remote preview deployment
---

# Preview Prototype

Run pre-flight checks and push a prototype branch to origin for remote preview deployment.

## Arguments

- $ARGUMENTS: The prototype name to preview (e.g., `checkout-v2`)

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Read `docs/data-model/prototypes.md` and list active prototypes.
2. Ask: "Which prototype do you want to preview?"

### Step 1: Validate

1. Check `docs/data-model/prototypes.md` — confirm the prototype exists and has status `Active`.
2. Verify branch `proto/<name>` exists: `git branch --list proto/<name>`
3. If the branch doesn't exist, abort with an error.

### Step 2: Pre-flight checks

1. Run lint from the worktree: `pnpm lint`
2. Run typecheck from the worktree: `pnpm typecheck`
3. If either fails, report the errors and stop. Do not proceed until checks pass.

### Step 3: Tests

1. Run: `pnpm run test --testPathPattern prototype/<name> --coverage`
2. If no tests exist, warn the user but do not block the preview push.
3. If tests fail, report failures and stop.

### Step 4: Check worktree status

1. Check if `.worktrees/<name>/` exists.
2. If it does, run `git status` in the worktree directory.
3. If there are uncommitted changes, warn the user and ask them to commit or discard before continuing. Do not proceed until the worktree is clean.

### Step 5: Push branch

1. Push the prototype branch to origin: `git push -u origin proto/<name>`
2. If the branch already exists on the remote, this will push updates.
3. If the push fails, report the error and stop.

### Step 6: Summary

Report:

- What was pushed (branch name, latest commit SHA and message)
- The remote branch name: `proto/<name>`
- Note: Preview deploy infrastructure is pending — once the CI/CD pipeline is configured, pushing to `proto/*` will trigger an automatic preview deployment.
- Placeholder: `Preview URL: (pending — will be available once preview deploy pipeline is configured)`
