---
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git branch:*), Bash(git show:*), Bash(gh pr comment:*), Bash(gh pr view:*), Bash(gh pr list:*), Bash(date:*), Read, Write, Glob, Grep, Agent
description: Code review a branch — runs locally against git diff, optionally posts to GitHub PR
---

Code review the current branch (or a named branch) against origin/master using 7 parallel review agents with confidence scoring.

This runs **locally** against the git diff. No GitHub PR is required. If a PR exists for the branch, findings are optionally posted as a comment.

## Arguments

- `$ARGUMENTS`: Optional. Can be:
  - A branch name (e.g., `pr/folio`) — review that branch's diff against origin/master
  - A PR number (e.g., `22`) — resolve to the branch, review locally
  - Empty — review the current branch

## Branch-to-Project Mapping

Derive the project name from the branch:
- If branch matches `pr/<name>`, project is `<name>`
- If branch matches `proto/<name>`, project is `<name>`
- Otherwise use the branch name as the project, or default to `captain`

The review file will be saved to `usr/jordan/<project>/code-reviews/`.

## Steps

Follow these steps precisely:

1. **Determine the branch and diff.** If `$ARGUMENTS` is a PR number, resolve the branch via `gh pr view <number> --json headRefName --jq .headRefName`. If it's a branch name, use it directly. If empty, use the current branch (`git branch --show-current`). Then get the diff: `git diff origin/master...<branch>`. If the diff is empty, report "No changes to review" and stop.

2. **Gather CLAUDE.md files.** Use a Haiku agent to list file paths (not contents) of relevant CLAUDE.md files: the root `CLAUDE.md`, the user-level `usr/jordan/claude/CLAUDE.md`, and any CLAUDE.md files in directories whose files appear in the diff.

3. **Summarize the changes.** Use a Haiku agent to read the diff and return a summary of what changed.

4. **Launch 7 parallel Sonnet agents** to independently review the diff. Each agent reads the diff (via `git diff origin/master...<branch>`) and relevant source files. They return a list of issues with the reason each was flagged:
   a. **Agent #1 (CLAUDE.md compliance):** Audit changes for compliance with CLAUDE.md files. Not all instructions apply during code review — focus on those that are relevant to the code being changed.
   b. **Agent #2 (bug scan):** Shallow scan for obvious bugs in the changed code. Focus on the diff, not full files. Focus on large bugs, avoid nitpicks.
   c. **Agent #3 (git history):** Read git blame and history of modified files to identify bugs in light of historical context.
   d. **Agent #4 (prior review context):** Check if previous PRs that touched these files had review comments that may also apply here.
   e. **Agent #5 (code comments):** Read code comments in modified files and check that changes comply with any guidance in the comments.
   f. **Agent #6 (test coverage):** Review test files for coverage gaps. Cross-reference test assertions with implementation changes. Are new code paths tested? Missing edge cases? Error paths covered?
   g. **Agent #7 (test consistency):** Check test/implementation consistency. Stale tests? Assertions match behavior? Test descriptions match what they test?

5. **Score each issue.** For each issue from step 4, launch a parallel Haiku agent to score confidence 0-100. Give each scoring agent the issue, the diff context, and the CLAUDE.md file list. The rubric (give verbatim):
   a. 0: Not confident at all. False positive, doesn't stand up to scrutiny, or pre-existing.
   b. 25: Somewhat confident. Might be real, might be false positive. Stylistic issues not explicitly in CLAUDE.md.
   c. 50: Moderately confident. Real issue but might be a nitpick or rare in practice.
   d. 75: Highly confident. Verified as very likely real, will be hit in practice, or directly mentioned in CLAUDE.md.
   e. 100: Absolutely certain. Confirmed real, happens frequently, evidence directly confirms.

6. **Filter.** Remove issues with score less than 80. If no issues remain, note "clean review" and continue to step 7.

7. **Save the review locally.** Determine the project name (Branch-to-Project Mapping above). Create the directory if needed: `mkdir -p usr/jordan/<project>/code-reviews/`. Get timestamp: `date +%Y%m%d-%H%M`. Write to `usr/jordan/<project>/code-reviews/<project>-review-<timestamp>.md`:

```markdown
---
branch: <branch name>
base: origin/master
sha: <branch HEAD SHA>
timestamp: <YYYY-MM-DD HH:MM>
issues_found: <total before filtering>
issues_posted: <total after filtering>
agents: 7 (5 code + 2 test)
---

## Code Review — <project> (<branch>)

### Summary
<change summary from step 3>

### Issues (confidence >=80)
<numbered list with confidence score, file path, line range, description>

### Filtered (confidence <80)
<numbered list, for reference only>

### Review Agents
- Agent 1 (CLAUDE.md compliance): <count> issues
- Agent 2 (bug scan): <count> issues
- Agent 3 (git history): <count> issues
- Agent 4 (prior review context): <count> issues
- Agent 5 (code comments): <count> issues
- Agent 6 (test coverage): <count> issues
- Agent 7 (test consistency): <count> issues
```

8. **Post to GitHub (if PR exists).** Check if a PR exists for this branch: `gh pr view <branch> --json number 2>/dev/null`. If yes, post a comment with the findings. If no PR exists, skip this step — the review file is the record.

   GitHub comment format:

   ---

   ### Code review

   Found N issues:

   1. <brief description> (<category>)

   `<file path>#L<start>-L<end>`

   **Quality process:** Reviewed locally using 7 parallel agents (5 code + 2 test) with confidence scoring (threshold >=80). This is in addition to the quality gate process (parallel review, test-driven fixes, red-green cycle) applied at every iteration and phase boundary during development.

   Generated with [Claude Code](https://claude.ai/code)

   ---

   Or if clean:

   ---

   ### Code review

   No issues found. Checked for bugs, CLAUDE.md compliance, and test coverage.

   **Quality process:** Reviewed locally using 7 parallel agents (5 code + 2 test) with confidence scoring (threshold >=80).

   Generated with [Claude Code](https://claude.ai/code)

   ---

9. **Present summary to the user:**
   - Branch and project
   - Issues found / posted
   - Review file path
   - Whether GitHub comment was posted (and PR number if applicable)

## False Positive Examples (for steps 4 and 5)

- Pre-existing issues not introduced in this branch
- Code that looks like a bug but isn't
- Pedantic nitpicks a senior engineer wouldn't flag
- Issues linters/typecheckers will catch (imports, types, formatting)
- General quality issues unless explicitly required in CLAUDE.md
- Issues silenced by lint-ignore comments in the code
- Intentional functionality changes related to the broader change
- Real issues on lines not modified in this branch

## Notes

- Do not build, typecheck, or run tests. Those run separately.
- The diff is the primary input. Use `git diff origin/master...<branch>` for the full diff, `git diff origin/master...<branch> -- <path>` for specific files.
- Cite file paths and line numbers for every issue.
- Make a todo list first.
