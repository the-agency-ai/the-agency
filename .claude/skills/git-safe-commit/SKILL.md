---
description: Git Commit Message Generator — QG-aware wrapper
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Git Safe Commit — QG-Aware Wrapper

The only way to run `git commit`. Never run raw `git commit` — always use this skill.

## Arguments

- `$ARGUMENTS`: Optional. Pass `--force` to skip the QGR receipt check (for non-QG commits like handoff-only or config-only changes). Any other arguments are treated as the commit message body.

## Step 1: Check for QGR receipt

Before committing, verify that a Quality Gate has been run for the staged changes.

1. Run `./claude/tools/stage-hash` to compute the stage hash of currently staged files.
2. Glob for `usr/*/*/qgr-*-{stage-hash}-*.md` where `{stage-hash}` is the hash from step 1.
3. **If a matching QGR file is found:** Report "QGR receipt found: `{path}`" and proceed to Step 2.
4. **If no matching QGR file is found AND `--force` was NOT passed:** Stop and ask:
   > No QGR receipt found for the staged changes (stage hash: `{hash}`).
   >
   > Options:
   > - Run `/quality-gate` first to produce a QGR
   > - Re-run `/git-safe-commit --force` to commit without a QGR (use sparingly — handoff, config, docs only)
5. **If `--force` was passed:** Note "Committing without QGR receipt (--force)" and proceed to Step 2.

## Step 2: Analyze changes

1. Run `git status` to see all untracked and modified files.
2. Run `git diff --cached` to see staged changes.
3. Run `git log --oneline -5` to see recent commit style.

## Step 3: Generate commit message

Create a commit message following the project's format:

```
<prefix>: <concise summary in one line>

- Additional detail (if needed)
- Another detail (if needed)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Prefixes

| Prefix | Usage                                                |
| ------ | ---------------------------------------------------- |
| `feat` | New feature or feature addition                      |
| `fix`  | Bug fix                                              |
| `misc` | Refactors, minor changes, or supporting code changes |
| `rmv`  | Major code deletion, removal, or cleanup             |

### Guidelines

- Keep the main message concise and under 72 characters
- Use imperative mood (e.g., "add feature" not "added feature")
- Only add bullet points for details that cannot fit in the one-liner
- Focus on **what** changed and **why**, not **how**
- If the QGR receipt was found, the caller likely provided a full structured commit message — use it as-is
- If this commit is at an iteration or phase boundary, the message must lead with the Phase-Iteration slug: `Phase 1.3: feat: summary`

## Step 4: Stage and commit

1. Stage any unstaged files that should be included (ask if unsure).
2. If a QGR receipt file was found in Step 1, stage it too — it should be committed alongside the work.
3. Run `git commit` with the message.
4. Run `git status` to verify the commit succeeded.
