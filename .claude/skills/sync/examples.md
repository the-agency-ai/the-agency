# sync — examples

## Happy-path examples

### Agent pushes worktree branch after commits

Agent on `devex` branch with 3 local commits:

```
/sync
```

Flow: fetch → show 3 commits to push → "Merge origin/master and push to origin/devex? [y/N]" → merges master → pushes → reports.

### Captain syncs captain-* branch

Captain on `captain-ref-doc-update`:

```
/sync
```

Same flow. Captain confirms push; work lands on origin ready for PR.

### Sync with non-default target

Agent wants to integrate another feature branch before pushing:

```
/sync feature-other
```

Merges `feature-other` into current branch, then pushes current branch.

---

## Edge-case examples

### On master (abort)

```
/sync
```

Expected:
```
ABORT: never push directly to master.
  On master: use a PR flow (/captain-release or /pr-submit).
```

Exit 1.

### Dirty tree (abort)

```
/sync
```

Expected:
```
ABORT: working tree dirty. Commit or stash before sync:
   M apps/foo/src/bar.ts
  ?? apps/foo/tests/bar.test.ts
```

Exit 1.

### Branch checked out in another worktree

Agent has `feature-x` checked out in worktree A and also locally. Running `/sync` from local:

```
/sync
```

Expected:
```
ABORT: branch 'feature-x' is checked out in another worktree at:
  .claude/worktrees/feature-x
Sync from there instead, or switch to a different local branch.
```

Exit 1.

### Merge conflict during Step 5

```
/sync
```

Expected:
```
Step 5: merge origin/master conflicted:
  CONFLICT (content): apps/foo/src/shared.ts
  
Resolve manually:
  git status
  # edit conflicted files
  git-safe add apps/foo/src/shared.ts
  git-captain merge-continue
  # re-run /sync
```

Exit 1. Working tree left mid-merge for resolution.

### Push rejected (branch protection)

```
/sync
```

Expected:
```
Step 6: push to origin/devex rejected.
  git-push tool reports: branch protection — must be reviewed.
  Resolve:
    - Create a PR via /captain-release or /pr-submit
    - Or ask principal to review branch
```

Exit 1.

---

## Integration examples

### Standalone push (no PR yet)

Agent staged some commits, wants origin copy but not yet ready to PR:

```
# ... work + /git-safe-commit ...
/sync
# later, when ready:
/pr-submit --scope "<one-liner>"
```

### Part of captain-release

```
/captain-release "..."  # internally calls git-push (equivalent to /sync's push step)
```

No separate `/sync` call needed; captain-release composes it.

### Force-with-lease after amend

Agent amended their last commit and wants to update the remote:

```
# ... amend + force-with-lease ...
/sync
```

Flow: fetch → show amended commit → confirm → `git-push --force-with-lease`.

`git-push` tool detects the force-with-lease need automatically when local history is rewritten. Hookify blocks bare `--force`; `--force-with-lease` is permitted.
