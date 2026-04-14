---
description: Fetch review comments on current PR, compose threaded replies, and resolve threads. Does NOT make code changes.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# PR Respond

Fetch review comments on the current PR, compose threaded replies, and resolve threads. Does NOT make code changes.

## When to use

- After fixes are made, to confirm they're addressed
- To explain why a suggestion was not adopted
- To ask clarifying questions on review comments

## Arguments

- $ARGUMENTS: PR number (optional — detect from current branch if empty).

## Steps

### Step 1: Find the PR

If PR number provided, use it. Otherwise: `gh pr view --json number`.

### Step 2: Fetch unresolved comments

Use the GitHub GraphQL API via `gh api graphql` to fetch review threads that are not resolved.

### Step 3: Present comments

Show unresolved comments in a numbered list:

```
Unresolved Review Comments:

1. @reviewer in src/parser.ts:42
   "This null check should use optional chaining"

2. @reviewer in src/utils.ts:15
   "Consider using a Map instead of object for lookup"
```

### Step 4: Compose responses

For each comment, determine the appropriate response:
- If the issue was fixed: "Fixed in {commit}" with brief description
- If not adopted: explanation of why, with reasoning
- If unclear: ask a clarifying question

### Step 5: Post threaded replies

After user approval, post each reply as a threaded response to the original comment.

### Step 6: Summary

```
PR Respond Complete:
  Comments addressed: N
  Replies posted: N
  Still unresolved: N
```
