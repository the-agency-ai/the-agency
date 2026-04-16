---
description: Code review the current branch against origin/master using 7 parallel review agents with confidence scoring.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Code Review

Code review the current branch against origin/master using 7 parallel review agents with confidence scoring. Runs locally against git diff; no GitHub PR required.

## Arguments

- $ARGUMENTS: Optional branch name, PR number, or empty for current branch.

## Steps

### Step 1: Determine branch and diff

1. If PR number provided: `gh pr view {number} --json headRefName` to get branch
2. If branch name provided: use it directly
3. If empty: use current branch via `git rev-parse --abbrev-ref HEAD`
4. Compute diff: `git diff origin/master...{branch}`

### Step 2: Gather CLAUDE.md files

Read all CLAUDE.md files in the repo to understand project conventions.

### Step 3: Summarize changes

Run `git diff --stat origin/master...{branch}` and categorize changed files by area.

### Step 4: Launch 7 parallel review agents

Launch all 7 as Sonnet agents in a single parallel call:

1. **CLAUDE.md compliance** — Check changes against project conventions
2. **Bug scan** — Logic errors, null handling, type mismatches, runtime crashes
3. **Git history** — `git log` context, are changes consistent with commit messages?
4. **Prior review context** — Check for existing review files, are prior findings addressed?
5. **Code comments** — Misleading comments, missing docs for public APIs
6. **Test coverage** — Coverage gaps, missing edge cases, stale assertions
7. **Test consistency** — Do tests match implementation? Stale mocks?

### Step 5: Score findings

Send all findings to a reviewer-scorer agent (model: haiku) for confidence scoring (0-100).

### Step 6: Filter

Remove findings with score < 80. Deduplicate.

### Step 7: Save review

Derive the project name from the branch (last segment after `/`, or the branch name itself).

Save to `claude/workstreams/{workstream}/code-reviews/{workstream}-review-{YYYYMMDD-HHMM}.md` where `{workstream}` is derived from the branch name (segment before `/`).

### Step 8: Post to GitHub (if PR exists)

If a PR exists for the branch, offer to post comments via `gh pr review`.

### Step 9: Present summary

Show the review results: total findings, breakdown by category, high-confidence issues.
