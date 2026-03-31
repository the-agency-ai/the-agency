---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:--show-current), Bash(git rev-parse:*), Bash(gh pr list:*), Bash(gh pr create:*), Bash(gh pr edit:*), Bash(gh pr view:*), Bash(gh repo view:*), Bash(pnpm lint), Bash(pnpm lint:*), Bash(pnpm format), Bash(pnpm format:*), Bash(pnpx vitest:*), Read, Glob, Grep, Skill
description: Quality-check, commit, push, and create/update PR in one flow
---

# /ship

Run quality checks, commit, push, and create or update a PR — the full "code is ready" workflow.

## Arguments

`$ARGUMENTS` may contain:

- `--no-push` — skip the push step (commit only)
- `--no-pr` — skip PR creation/update (push only)
- No arguments runs the full flow

## Steps

1. **Pre-flight checks:**
   - `git branch --show-current` — must NOT be `master` (refuse to ship from master)
   - `git status` — show what is dirty/staged/untracked
   - `git diff --stat` — show what will be committed
   - If nothing to commit, inform the user and stop

2. **Quality gate:**
   - Run `pnpm lint` — must pass with 0 errors
   - Run `pnpm format:check` — must pass (or auto-fix with `pnpm format` first)
   - If any check fails, report the failures and stop — do NOT proceed to commit

3. **Commit:**
   - Invoke the `/git-commit` skill to stage and commit
   - This handles commit message generation and user approval
   - Wait for the commit to complete before proceeding

4. **Push** (unless `--no-push`):
   - `git push -u origin <branch>`
   - If push fails due to divergence, suggest `/sync` and stop

5. **Create or update PR** (unless `--no-pr`):
   - Check if PR exists: `gh pr list --head <branch> --json number`
   - If PR exists: invoke `/update-pr` skill
   - If no PR: invoke `/create-pr` skill
   - Report the PR URL

6. **Summary:**
   ```
   Ship complete:
   - Commit: <sha> <message>
   - Push: origin/<branch>
   - PR: <url> (created/updated)
   ```

## Guidelines

- This command orchestrates existing skills — it does not duplicate their logic
- The quality gate runs BEFORE commit, not after
- Always show the user what will be committed before proceeding
- If any step fails, stop and report — do not skip failed steps
- The push step and PR creation step both trigger the external-action hookify rule — the user must confirm each
