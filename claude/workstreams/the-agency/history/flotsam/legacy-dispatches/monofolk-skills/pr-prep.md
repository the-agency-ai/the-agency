---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Read, Glob, Grep, Edit, Write, Agent, Skill
description: Run a quality gate before creating a PR — review, fix, test, report, produce QGR receipt
---

# PR Prep — Quality Gate Before PR Creation

Run this before creating a pull request. Invokes `/quality-gate` for the review+fix cycle, produces a QGR receipt, and prepares the branch for PR creation. The captain uses this before `/captain-review` or direct PR creation.

Unlike `/phase-complete`, this does NOT squash commits or land on master. It gates the current branch state for PR readiness.

## Arguments

- $ARGUMENTS: Description of the PR scope (e.g., "pr-prep: framework tools + QG hardening"). If empty, infer from the branch name and recent commits.

## Steps

### Step 1: Preconditions

1. If `$ARGUMENTS` is empty, read the branch name and `git log --oneline -10` to infer the PR scope. Construct a description.
2. Run `git diff --stat HEAD` and `git status`. Note any uncommitted changes — they should be committed or stashed before the QG runs.
3. Identify the plan file in `docs/plans/` if one exists.

### Step 2: Run the quality gate

Invoke `/quality-gate` via the Skill tool, passing `pr-prep: $ARGUMENTS` as the skill argument. The `pr-prep` prefix tells `/quality-gate` what boundary type to use for the QGR receipt filename.

This runs the full QG protocol: parallel agent review → consolidate → bug-exposing tests → fix → coverage tests → confirm clean → present QGR → write QGR receipt file.

The QG scope is the **full diff against origin/master** — everything that will be in the PR.

Wait for the QGR to be presented and the receipt file written before proceeding.

### Step 3: Fix and commit any QG findings

If the QG found and fixed issues (it usually does):

1. Stage the fixes and any new test files.
2. Use `/git-safe-commit` to commit them. The QGR receipt from Step 2 covers the pre-fix state; the commit will update the staged content. This is expected — the receipt proves the QG ran.
3. If the fixes are significant, consider running the QG again on the updated code.

### Step 4: Report readiness

Present a summary:

> **PR Prep Complete**
>
> - Branch: `{branch}`
> - QGR receipt: `{path}`
> - QG findings: N found, N fixed
> - Tests: N passing, 0 failing
> - Ready for: `/captain-review`, `create-pr`, or `/code-review`

### Note

This command does not create the PR itself. After PR prep:

- **Captain workflow:** The captain runs `/captain-review` → dispatches findings → rebuilds PR branches → pushes → creates draft PRs.
- **Direct workflow:** Use `/create-pr` or `gh pr create` to create the PR immediately.
