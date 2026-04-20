---
name: sync
description: Merge a target branch into the current branch and push to origin. The ONLY framework skill that pushes to a remote. Requires explicit confirmation. Never rebases. Default-actor skill (agents and captain both use it; captain for captain-* branches, agents for their worktree branches).
agency-skill-version: 2
when_to_use: On any non-master branch (worktree agent branch OR captain-* branch), when ready to push committed work to origin. NEVER from master (use PR flow instead). NEVER for auto-invocation — always requires confirmation.
argument-hint: "[<target-branch>]"
paths: []
required_reading:
  - claude/REFERENCE-GIT-MERGE-NOT-REBASE.md
  - claude/REFERENCE-SAFE-TOOLS.md
---

<!--
  allowed-tools omitted — inherits Bash(*). Composes git-captain + git-safe
  + git-push with user confirmation at each step. Subcommand-level restriction
  unsafe (flag #62/#63).
-->

# sync

The framework's single authorized push path. Merges a target branch (default `origin/master`) into the current branch and pushes to origin. Every other push attempt is blocked by hookify (raw `git push` refused at the hook layer).

**Name pattern:** noun-verb (`sync` is both noun and verb by context). No actor qualifier because sync is default-actor — anyone on a non-master branch uses it.

## Why this exists

Pushing is a privileged action. Without a single authorized path:

- Agents push broken branches (no QG run)
- Captain pushes to master accidentally (catastrophic — bypasses PR review)
- Forced pushes overwrite teammates' work

`sync` enforces: (a) not master, (b) clean tree, (c) single-worktree checkout, (d) confirmation before each destructive step, (e) merge not rebase. The underlying `claude/tools/git-push` tool adds its own layer of safety (blocks main/master, blocks bare `--force`).

## Required reading

Before proceeding, Read the files listed in `required_reading:` frontmatter.

## Usage

```
/sync                    # merge origin/master into current branch, push
/sync origin/main        # explicit target
/sync other-branch       # merge from a non-default target
```

## Preconditions

- Current branch is NOT master (or main). Running on master aborts.
- Working tree is clean.
- Branch is checked out here (not in another worktree).

## Flow / Steps

### Step 1: Safety checks

1. Get current branch. If master, **abort**: "Never push directly to master. Use a PR."
2. Verify clean working tree.
3. Verify this branch is not checked out in another worktree (prevents dual-commit race).

### Step 2: Fetch

```
./claude/tools/git-captain fetch
```

### Step 3: Show what will be pushed

```
git log --oneline origin/<current-branch>..HEAD   # if tracking exists
git log --oneline <target>..HEAD                  # if no tracking
```

Captain shows commit list; principal verifies scope.

### Step 4: Confirm

Prompt:

> Merge `<target>` into `<branch>` and push to `origin/<branch>`?

**Do not push without explicit confirmation.**

### Step 5: Merge target

```
git merge <target>
```

If conflicts: show conflict files, ask principal to resolve or abort. No auto-resolution.

### Step 6: Push

```
./claude/tools/git-push <branch>
```

**Never raw `git push`** — blocked by hookify. `git-push` tool validates target (refuses main/master), checks force-with-lease semantics, and is the only authorized push path in the framework.

### Step 7: Report

```
Sync complete:
  Branch: <branch>
  Pushed: N commits to origin/<branch>
  Base:   <target>
```

## Failure modes

- **On master**: abort (Step 1). Never push master directly.
- **Dirty tree**: abort. Commit or stash.
- **Branch checked out elsewhere**: abort. Only one worktree at a time can sync.
- **Merge conflict** (Step 5): halt; principal resolves or aborts.
- **Push rejected** (non-fast-forward, branch protection, etc.): report; principal investigates.

## What this does NOT do

- **Does not push master**: abort on master.
- **Does not rebase**: uses merge commits only (per `REFERENCE-GIT-MERGE-NOT-REBASE.md`).
- **Does not force-push bare**: only via `--force-with-lease` and only via `git-push` tool.
- **Does not create PRs**: that's `/captain-release` (captain) or `/pr-submit` (agent).
- **Does not run QG**: that's `/pr-prep`. Run QG BEFORE `/sync` if this push is PR-bound.

## disable-model-invocation: true

Pushing is destructive and requires principal confirmation. Model auto-invocation could push in the wrong context. The `disable-model-invocation: true` frontmatter prevents that. Principal/captain types `/sync` explicitly.

## Status

`active` (v2, refactored in-place from legacy `sync` 2026-04-19; name unchanged).

## Related

- `/captain-release` — captain's one-flow release (includes sync internally)
- `/pr-submit` — agent signals captain; no direct push
- `/pr-captain-land` — captain's lifecycle for agent-owned branches
- `/captain-sync-all` — captain's master-sync (never pushes; different scope)
- `/worktree-sync` — worktree sync (never pushes; local master merge only)
- `claude/tools/git-push` — underlying authorized push tool
- `claude/hookify/hookify.block-raw-git-push.md` — blocks raw `git push`
- `claude/REFERENCE-GIT-MERGE-NOT-REBASE.md` — merge discipline

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
