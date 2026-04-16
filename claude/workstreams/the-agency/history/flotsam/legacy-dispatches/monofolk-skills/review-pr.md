---
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr list:*), Bash(gh repo view:*), Bash(git diff:*), Bash(git log:*), Bash(gh api repos/*/pulls/*/comments:*), Bash(gh api repos/*/issues/*/comments:*), Bash(gh api repos/*/pulls/*/reviews:*), Bash(gh api repos/*/pulls/*/reviews --input:*), Read, Glob, Grep
description: Review a PR and post comments after approval
---

# PR Reviewer

Review a PR's changes, present findings for approval, then post as a GitHub review.

## Arguments

- $ARGUMENTS: PR number (optional — defaults to current branch's PR)

## Instructions

1. **Find the PR**:
   - If a PR number is provided in `$ARGUMENTS`, use it directly
   - Otherwise, run `gh pr list --head $(git branch --show-current) --json number,title --jq '.[0].number'`
   - If no PR exists, inform the user and stop

2. **Gather context**:
   - Run `gh pr view <number> --json title,body,baseRefName,headRefName` to understand the PR
   - Run `gh pr diff <number>` to get the full diff
   - Fetch existing review comments to check for duplicates:
     - `gh api repos/{owner}/{repo}/pulls/{number}/comments --jq '.[].body'` (inline review comments)
     - `gh api repos/{owner}/{repo}/pulls/{number}/reviews --jq '.[].body'` (review summaries)
   - Read any files that need deeper context to understand the changes

3. **Write a PR summary** for the reviewer's reference. Adapt detail to the size of the change:
   - **Small PRs** (≤ ~50 lines changed): 2–3 sentence overview, no code snippets needed
   - **Medium PRs** (~50–300 lines): short paragraph summarising intent, with code snippets for the most important changes (new APIs, tricky logic, behaviour changes)
   - **Large PRs** (300+ lines): structured summary with sections per area of change — use code snippets for critical/surprising changes and concise text summaries for the rest (renames, boilerplate, config, tests)

   For code snippets, show only the essential lines (not full functions) and annotate them briefly. Use a format like:

   > **New retry logic in `fetchPatient`** (`src/api/patient.ts:34-41`):
   >
   > ```ts
   > for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
   >   const res = await fetch(url);
   >   if (res.ok) return res.json();
   > }
   > ```

   For less critical changes, a one-line text summary suffices:

   > - Renamed `getUser` → `fetchUser` across 4 files for consistency
   > - Added unit tests for the new validation helpers

4. **Analyse the changes** and identify issues worth commenting on. Focus on:
   - **Bugs and correctness issues** — logic errors, off-by-one, null/undefined risks
   - **Security concerns** — injection, auth gaps, secrets exposure
   - **Performance problems** — N+1 queries, unnecessary re-renders, missing indexes
   - **Missing edge cases** — error handling, empty states, race conditions
   - **API design issues** — breaking changes, inconsistent naming

5. **Deduplicate against existing comments**:
   - Compare each issue you found against the existing review comments fetched in step 2
   - Drop any comment that covers the same issue as an existing comment, even if worded differently — match on semantic intent, not exact text
   - If all your comments are already covered, report that the PR has already been thoroughly reviewed and stop

6. **Apply strict filtering** — quality over quantity:
   - Maximum **5 comments** per review (force-rank if you find more)
   - Skip stylistic nitpicks, formatting, naming preferences, and trivial suggestions
   - Skip anything a linter or formatter would catch
   - Skip "consider doing X" suggestions unless X prevents a real bug
   - Each comment must identify a **concrete problem or risk**, not a preference
   - If there are no meaningful issues, say so — an empty review is fine

7. **Present the review for approval** using AskUserQuestion:
   - Start with the PR summary from step 3 (this is for the reviewer, not posted to GitHub)
   - Then show a summary table of all comments you plan to post:

     | #   | File:Line       | Comment           | Severity          |
     | --- | --------------- | ----------------- | ----------------- |
     | 1   | path/to/file:42 | Brief description | bug/security/perf |

   - Include the full text of each comment you plan to post
   - Ask: "Post this review?" with options: "Post review", "Edit comments first"
   - If the user wants edits, adjust and re-present

8. **Post the review** only after approval:
   - Write the review payload as JSON to `/tmp/pr-review-payload.json`
   - Use `gh api repos/{owner}/{repo}/pulls/{number}/reviews --input /tmp/pr-review-payload.json`
   - Use `COMMENT` event (not `APPROVE` or `REQUEST_CHANGES` — leave that to the user)
   - Example payload:
     ```json
     {
       "event": "COMMENT",
       "body": "Review summary",
       "comments": [{ "path": "file", "line": 42, "body": "comment" }]
     }
     ```

## Guidelines

- Be opinionated but fair — only flag things that genuinely matter
- Assume the author is competent; don't explain basics
- Reference specific lines and suggest fixes where possible
- Group related issues into a single comment rather than multiple small ones
- If the PR is clean, say so — don't invent issues to justify the review
