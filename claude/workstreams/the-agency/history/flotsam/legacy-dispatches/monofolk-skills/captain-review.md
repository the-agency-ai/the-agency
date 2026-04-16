---
allowed-tools: Bash(gh issue view:*), Bash(gh search:*), Bash(gh issue list:*), Bash(gh pr comment:*), Bash(gh pr diff:*), Bash(gh pr view:*), Bash(gh pr list:*), Bash(gh api:*), Bash(date:*), Bash(git rev-parse:*), Read, Write, Glob, Grep, Agent
description: Review all draft PRs — run /code-review on each, save results, generate dispatch report
---

Review all draft PRs (or a specific one) and generate a dispatch report for routing findings to worktree agents.

## Arguments

- `$ARGUMENTS`: Optional. Can be:
  - A PR number (e.g., `22`) — review that PR only
  - A project name (e.g., `folio`) — resolve to the PR on `pr/folio`
  - `--all` or empty — review all open draft PRs on `pr/*` branches

## Instructions

### Step 1: Identify PRs to review

If `$ARGUMENTS` is a PR number, use that. If it's a project name, resolve via `gh pr list --head pr/<name> --json number --jq '.[0].number'`. If `--all` or empty, list all open PRs on `pr/*` branches: `gh pr list --state open --json number,headRefName --jq '.[] | select(.headRefName | startswith("pr/"))'`.

### Step 2: Review each PR

For each PR, run the `/code-review` process (the full 7-agent pipeline defined in `usr/jordan/claude/commands/code-review.md`):

1. Derive project from branch name (`pr/<name>` → `<name>`)
2. Run all 9 steps of `/code-review`
3. The review file is saved to `usr/jordan/<project>/code-reviews/`
4. GitHub comment is posted if issues ≥80 confidence exist

If reviewing multiple PRs, process them **sequentially** (not parallel — each review uses many agents already).

### Step 3: Generate dispatch files

For each project where issues were found (confidence ≥80), write a dispatch file:

```
usr/jordan/<project>/code-reviews/<project>-dispatch-<YYYYMMDD-HHmm>.md
```

Format:

```markdown
---
pr: <number>
project: <name>
sha: <reviewed SHA>
timestamp: <YYYY-MM-DD HH:MM>
issues: <count>
review_file: <path to the review file>
---

## Dispatch — <project>

This is review input from an independent 7-agent code review — not an action list. Use your judgment.

### Process

Read the injected `code-review-lifecycle.md` reference "Worktree Agent: Handling a Dispatch" for the full process. Summary:

1. **Evaluate** each finding for validity — investigate the code, is it real?
2. **Write a bug-exposing test** for valid findings (where appropriate) — confirm it fails (red)
3. **Fix the issue** — confirm the test passes (green)
4. **Document disputes** — if a finding is wrong, note your reasoning on that finding below
5. **Run `/iteration-complete`** — the QG validates your work
6. **Commit documents**: which findings addressed, how, any disputes, any QG discoveries

### Issues

1. **<summary>** (confidence: <score>)
   - File: `<path>#L<start>-L<end>`
   - Category: <CLAUDE.md compliance | bug | test gap | etc.>
   - Details: <description>
   - Suggested fix: <if available>

2. ...

### Resolution

_To be filled by the worktree agent after addressing findings._

| #   | Finding | Status | Action | Tests |
| --- | ------- | ------ | ------ | ----- |
|     |         |        |        |       |

_(One row per finding from the Issues section above. Status: Fixed, Disputed, Stale, Deferred, N/A)_

Commit: _pending_
```

### Step 4: Present dispatch report

Show a summary table:

```
## Captain Review — <date>

| PR | Project | Branch | Issues | Review File | Action |
|----|---------|--------|--------|-------------|--------|
| #20 | folio | pr/folio | 3 | usr/jordan/folio/code-reviews/folio-review-20260323-1503.md | Dispatch |
| #21 | catalog | pr/catalog | 0 | usr/jordan/catalog/code-reviews/catalog-review-20260323-1505.md | Clean |
| #22 | workflow | pr/workflow | 1 | usr/jordan/workflow/code-reviews/workflow-review-20260323-1507.md | Dispatch |

Dispatch files written:
- usr/jordan/folio/code-reviews/folio-dispatch-20260323-1503.md
- usr/jordan/workflow/code-reviews/workflow-dispatch-20260323-1507.md
```

### Step 5: Commit review and dispatch files

Stage and commit all review and dispatch files:

```
git add usr/jordan/*/code-reviews/*
git commit -m "misc: captain review — <date> — <N> PRs reviewed, <M> with issues"
```

### Note on Charly

Charly (the third-party review bot) refuses to review large diffs. Our PRs exceed its size limit. This captain review process is our alternative: 7 parallel agents with confidence scoring, run locally, results committed to the repo and posted to GitHub.
