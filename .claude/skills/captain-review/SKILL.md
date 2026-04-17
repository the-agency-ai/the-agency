---
description: Review all draft PRs and generate dispatch reports for routing findings to worktree agents.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Captain Review

Review all draft PRs and generate dispatch reports for routing findings to worktree agents.

## Arguments

- $ARGUMENTS: PR number, project name, `--all`, or empty (defaults to `--all`).

## Steps

### Step 1: Identify PRs to review

- If PR number: review that specific PR
- If project name: find PRs for that project
- If `--all` or empty: `gh pr list --state open --draft` to find all draft PRs

### Step 2: Review each PR

For each PR, invoke `/code-review` via the Skill tool with the PR number.

### Step 3: Generate dispatch files

For each project with findings, create a dispatch file at `claude/workstreams/{workstream}/code-reviews/{workstream}-dispatch-{YYYYMMDD-HHMM}.md` containing:

- PR reference
- Findings grouped by file
- Suggested fixes
- Priority ordering

The workstream is derived from the PR branch name (segment before `/`).

### Step 4: Present dispatch report

Show a summary of all reviews:

```
Captain Review Complete:

Project          PR    Findings   Dispatch
─────────────────────────────────────────────
mdpal            #12   8 issues   claude/workstreams/mdpal/code-reviews/mdpal-dispatch-20260401-1430.md
mock-and-mark    #15   3 issues   claude/workstreams/mock-and-mark/code-reviews/mock-and-mark-dispatch-20260401-1430.md
```

### Step 5: Commit review and dispatch files

Stage and commit the review and dispatch files using `/git-safe-commit --force` (these are coordination artifacts, not code changes).
