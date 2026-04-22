---
description: Review a PR and post comments after approval. Does NOT make code changes.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Review PR

Review a pull request and post comments. Does NOT make code changes — only reads and comments.

## Arguments

- $ARGUMENTS: PR number (optional — if empty, detect from current branch).

## Steps

### Step 1: Find the PR

If PR number provided, use it. Otherwise: `gh pr view --json number` from current branch.

### Step 2: Gather context

- `gh pr view {number} --json title,body,files,reviews,comments`
- `gh pr diff {number}`
- Read existing review comments to avoid duplication

### Step 3: Write PR summary

One paragraph summarizing what the PR does and why.

### Step 4: Analyze changes

Review the diff for:
- Bugs and logic errors
- Security concerns
- Performance issues
- Edge cases
- API design problems
- Convention violations

### Step 5: Deduplicate

Remove findings already covered by existing review comments.

### Step 6: Strict filtering

Keep only the **top 5 most important** findings. Quality over quantity.

### Step 7: Present review for approval

Show the review to the user:

```
PR Review: #{number} — {title}

Summary: {one paragraph}

Comments (5):
1. {file}:{line} — {issue}
2. ...
```

**Do not post without explicit approval.**

### Step 8: Post review

After approval: `gh pr review {number} --comment --body "{review}"` or post individual line comments via the GitHub API.
