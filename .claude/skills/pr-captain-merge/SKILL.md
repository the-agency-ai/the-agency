---
name: pr-captain-merge
description: Captain-only. Merge a PR safely — true merge commit (never squash, never rebase), branch protection respected, --principal-approved gate for --admin override. Prevents the "accidentally squashed via the wide GitHub UI button" failure mode that has burned the fleet.
agency-skill-version: 2
when_to_use: Captain on master in main checkout, after PR has passed CI and principal has approved (verbally or via GitHub review). Invoked by captain directly or as a step within /pr-captain-land. NEVER from a worktree. NEVER auto-invoked (disable-model-invocation).
argument-hint: "<pr-number> [--principal-approved] [--delete-branch] [--dry-run]"
paths: []
disable-model-invocation: true
required_reading:
  - claude/REFERENCE-GIT-MERGE-NOT-REBASE.md
  - claude/REFERENCE-SAFE-TOOLS.md
  - claude/REFERENCE-CODE-REVIEW-LIFECYCLE.md
---

<!--
  allowed-tools omitted — inherits Bash(*) from .claude/settings.json.
  Subcommand-level restriction (e.g. Bash(gh pr merge *)) silently blocked
  fleet agents in the past (flag #62/#63 / devex dispatch #171).
  This skill legitimately calls gh + claude/tools/pr-merge + claude/tools/git-*
  — narrow tool-level restriction would work but would need maintenance as
  called tools evolve. Inherit Bash(*) is safer.
-->

# pr-captain-merge

Captain's safe wrapper for merging PRs on GitHub. Always a true merge commit (no squash, no rebase). Respects branch protection by default. `--principal-approved` is the only way to engage `--admin` override.

**Name pattern:** `pr-` prefix groups with the PR skill family (autocomplete `/pr<tab>` shows the full kit), `captain-` qualifier makes captain-only scope visible at a glance.

## Why this exists

Raw `gh pr merge` is too easy to misuse:

- GitHub's UI nudges toward squash (the wide button)
- The `--squash` flag is one keystroke away from `--merge`
- `--admin` bypasses branch protection silently
- Without discipline, the captain shipped 4 squash merges in one day (pre-v2 incident)

`pr-captain-merge` is the gate — skill-level enforcement plus the underlying `claude/tools/pr-merge` tool that does the actual work.

## Required reading

Before running, Read the files in `required_reading:` frontmatter. `GIT-MERGE-NOT-REBASE.md` explains why we never squash or rebase. `SAFE-TOOLS.md` covers the safe-tool family this skill composes.

## Usage

```
/pr-captain-merge <pr-number>
/pr-captain-merge <pr-number> --principal-approved
/pr-captain-merge <pr-number> --delete-branch
/pr-captain-merge <pr-number> --dry-run
```

## Preconditions

- Captain is on master in main checkout. Not in a worktree.
- PR number is known. Captain has verified PR is not in draft.
- CI has passed (or deploy-preview flake is understood and ignored).
- Principal has approved — either via GitHub review OR verbally in this conversation.
- For `--principal-approved`: the principal's authorization is in THIS conversation. Do not infer from prior sessions.

If any precondition is missing, STOP. Ask the principal to resolve, or use the non-approved path and let branch protection block.

## Flow / Steps

### Step 1: Pre-flight

1. Confirm the PR number (ask if missing).
2. Confirm you're not on the PR's branch — captain merges from master or any non-PR branch.
3. If you're going to use `--principal-approved`, confirm the principal has authorized in THIS conversation. Don't infer from history.

### Step 2: Invoke the tool

```
./claude/tools/pr-merge <N>
```

Or with explicit principal approval (only when they verbally OK'd in-session):

```
./claude/tools/pr-merge <N> --principal-approved
```

Tool enforces:
- `--merge` always (never `--squash`, never `--rebase`)
- Branch protection respected by default
- `--admin` only when `--principal-approved` flag is present

### Step 3: Handle the outcome

**On success** (exit 0): report merge URL + next-step recommendation (sync master via `./claude/tools/_sync-main-ref`, or wait for `/post-merge`).

**On branch-protection block** (exit 3): tool prints the gate. Two resolutions:
- Ask principal to `gh pr review <N> --approve` in GitHub UI, then re-run.
- If principal authorized in this conversation but not GitHub UI, re-run with `--principal-approved`.

**On merge conflict** (exit 1): resolve locally first:
```
gh pr checkout <N>
./claude/tools/git-safe merge-from-master --remote
# resolve conflicts
./claude/tools/git-safe add <files>
./claude/tools/git-captain merge-continue
./claude/tools/git-push <branch>
# then retry
/pr-captain-merge <N>
```

### Step 4: Post-merge (handoff or chain)

After successful merge:
- Sync local master: `./claude/tools/_sync-main-ref`
- If release PR: run `/post-merge` (or `/pr-captain-post-merge` once refactored) to create GitHub release + fleet notification.
- Notify affected agents: `/dispatch create --type master-updated --to <agent>`
- Notify cross-repo collaborators: `/collaborate` if relevant

## Failure modes

- **CI failing:** do NOT merge. Address the failure; restart from `/pr-prep` or captain's diagnosis.
- **Merge conflicts on agent's branch:** sent back for agent to resolve. Captain doesn't resolve agent's conflicts.
- **Principal-approved flag without in-conversation authorization:** DO NOT PASS. Ask the principal explicitly; wait for their OK; then pass the flag. Captain attests to something real.
- **Squash or rebase attempted:** blocked by tool. No way in the skill to request.

## What this skill does NOT do

- **Does not write commits** — merge happens server-side at GitHub.
- **Does not delete the local branch** — that's captain's next decision (or `/pr-captain-post-merge`).
- **Does not auto-tag a release** — explicit `gh release create` afterward (or via `/pr-captain-post-merge`).
- **Does not push** — merge is server-side; no local push.
- **Does not squash, does not rebase** — blocked by the underlying tool (`claude/tools/pr-merge`).

## Why never squash, never rebase

Both rewrite history. The-agency framework is built on visible, append-only history:

- Branch commits are individually meaningful (QGRs, fixes, version bumps)
- Merge commits create a permanent record of integration
- `git log --graph` shows the actual flow
- Bisecting works against real commits, not synthetic squash blobs

Cost: heavier `git log` output. Benefit: you can SEE what happened and WHY, which is essential when fleet agents and adopters all have to read the same history.

## Captain-only — four-layer defense

Defense in depth against accidental invocation from the wrong context:

1. **`disable-model-invocation: true`** in frontmatter — Claude cannot auto-invoke. Captain must type the command.
2. **`paths: []`** (intentionally empty) — no auto-activation from any file path.
3. **Name contains `captain-`** — any reader sees scope in the skill listing.
4. **Runtime precondition** — underlying `claude/tools/pr-merge` checks caller context before engaging `--admin`.

## Status

`active` — ships as of agency-skill-version 2 adoption 2026-04-19. Replaces v1 `pr-merge` skill.

## Related

- `/pr-captain-land` — composite skill that calls this as its merge step
- `/pr-prep` — the QG-before-PR-create (agent-side)
- `/pr-submit` — agent hands branch to captain for landing
- `/post-merge` (TBD refactored to `/pr-captain-post-merge`) — release + fleet-notify after merge
- `claude/tools/pr-merge` — the underlying safe-merge tool
- `claude/hookify/hookify.block-raw-gh-pr-merge.md` — hookify rule that blocks bare `gh pr merge`
- `claude/REFERENCE-GIT-MERGE-NOT-REBASE.md` — the discipline rationale
- the-agency#296 — PR lifecycle ownership (the-agency direction)
- the-agency#298 — skill refactor recommendation (the methodology)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
