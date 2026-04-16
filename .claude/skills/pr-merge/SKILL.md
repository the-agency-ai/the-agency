---
description: Merge a PR safely — true merge commit (never squash, never rebase), branch protection respected, --principal-approved gate for --admin override.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# PR Merge

Safe wrapper for merging PRs. Always uses true merge commit (never squash,
never rebase). Respects branch protection by default. Requires explicit
principal authorization for `--admin` override.

This skill exists because raw `gh pr merge` is too easy to misuse:
- GitHub's UI nudges you toward squash (the wide button)
- The `--squash` flag is one keystroke away from `--merge`
- `--admin` bypasses branch protection silently
- Without this discipline, the captain shipped 4 squash merges in one day

## When to use

- A PR is open, smoke check passes, principal has reviewed (or verbally OK'd
  in chat), ready to land.
- After resolving conflicts via `git-safe merge-from-master --remote` and
  pushing the resolution.

## When NOT to use

- The PR has unresolved merge conflicts → resolve locally first.
- The PR is in draft → mark as ready first.
- You're trying to squash → ALWAYS use a real merge commit. Squash is banned.

## Arguments

- `$ARGUMENTS`: at minimum, the PR number. Optional flags:
  - `--principal-approved` — captain attestation that principal verbally
    OK'd the merge. ONLY way to enable `--admin` override. Logged for audit.
  - `--delete-branch` — also delete remote branch after merge.
  - `--dry-run` — preview without merging.

## Steps

### Step 1: Pre-flight

1. Confirm the PR number (ask if missing).
2. Confirm you're not on the PR's branch — captain merges from main or any
   non-PR branch.
3. If you're going to use `--principal-approved`, confirm the principal
   has authorized in this conversation. Don't infer authorization.

### Step 2: Invoke the tool

```
./claude/tools/pr-merge <N>
```

Or with explicit principal approval (only if they verbally OK'd):

```
./claude/tools/pr-merge <N> --principal-approved
```

### Step 3: Handle the outcome

**On success:** report the merge URL and the next-steps (sync local main via
`./claude/tools/_sync-main-ref` or wait for next captain `/post-merge`).

**On branch-protection block (exit 3):** the tool prints the gate that's
blocking. Two paths:
- Ask the principal to `gh pr review <N> --approve` in GitHub UI, then
  re-run.
- If the principal has already authorized verbally in this conversation
  but not in GitHub UI, re-run with `--principal-approved`.

**On merge conflict (exit 1):** resolve locally first:

```
gh pr checkout <N>
./claude/tools/git-safe merge-from-master --remote
# resolve conflicts in working tree
./claude/tools/git-safe add <files>
./claude/tools/git-captain merge-continue
./claude/tools/git-push <branch>
# then retry
./claude/tools/pr-merge <N>
```

### Step 4: Post-merge

After a successful merge:
- Sync local main: `./claude/tools/_sync-main-ref`
- Create the GitHub release (if this is a release PR): `gh release create v<version> --target main --notes ...`
- Notify fleet (if relevant): `/dispatch` to affected agents
- Notify cross-repo collaborators (if relevant): `/collaborate send`

## What this skill does NOT do

- **Does not write commits** — merge happens server-side at GitHub.
- **Does not delete the local branch** — that's the next captain's call.
- **Does not auto-tag a release** — explicit `gh release create` afterward.
- **Does not push** — the merge is server-side; you don't push the merge
  commit.

## Why never squash, never rebase

Both rewrite history. The framework is built on visible, append-only history:
- Branch commits are individually meaningful (QGRs, fixes, version bumps)
- Merge commits create a permanent record of integration
- `git log --graph` shows the actual flow
- Bisecting works against real commits, not synthetic squash blobs

The cost is heavier `git log` output. The benefit is you can SEE what
happened and WHY, which is essential when fleet agents and adopters all
have to read the same history.

## Reference

- Tool: `claude/tools/pr-merge`
- Hookify: `claude/hookify/hookify.block-raw-gh-pr-merge.md` (blocks bare `gh pr merge`)
- Discipline: `claude/REFERENCE-GIT-MERGE-NOT-REBASE.md`

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
