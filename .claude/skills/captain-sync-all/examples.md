# captain-sync-all — examples

## Happy-path examples

### Session-start sync

Captain starts morning session. Overnight PR merged on GitHub.

```
/captain-sync-all
```

Expected flow: fetch → divergence detected → tag recovery → merge origin/master → enumerate worktrees → no local-only worktree commits to merge → sync worktrees to new master → report + handoff update.

### Sync with worktree work to land

Captain session, `devex` worktree has 3 commits not yet in master (captain may have forgotten to run this after devex's PR merged):

```
/captain-sync-all
```

Expected: Step 5 prompts:
```
Worktree 'devex' has 3 commits ahead of master:
  abc1234 feat(devex): X
  def5678 fix(devex): Y
  ghi9012 docs(devex): Z
Merge into master? [y/N]
```

Captain says yes → merges with `--no-ff` → `main-updated` dispatch fires → Step 6 propagates.

### All clean, no work

No remote changes, no worktree drift:

```
/captain-sync-all
```

Expected:
```
Sync complete:
  Master: at origin/master (e47ce53a)
  Worktrees: all in sync (17/17)
  Dispatches sent: 0
```

Size: S, fast pass, no-op in terms of state change.

---

## Edge-case examples

### Captain not on master

```
/captain-sync-all
```

Expected:
```
ABORT: captain must be on master (currently on captain-fix-foo).
  Switch: git-captain switch-branch master
```

Exit 1.

### Dirty tree

```
/captain-sync-all
```

Expected:
```
ABORT: master working tree is dirty (2 uncommitted files).
  Commit or stash before sync:
    M claude/REFERENCE-X.md
    ?? usr/jordan/captain/dispatches/new-one.md
```

Exit 1.

### Step 3 merge conflict

Captain's local master has a coord commit that conflicts with origin/master:

```
/captain-sync-all
```

Expected:
```
ABORT: merge origin/master conflicted:
  CONFLICT (content): claude/REFERENCE-SKILLS-INDEX.md
  
Resolve manually:
  git status
  # edit conflicted files
  git-safe add claude/REFERENCE-SKILLS-INDEX.md
  git-captain merge-continue
  # re-run /captain-sync-all
```

Exit 1. Working tree left mid-merge for resolution.

### Step 6 worktree sync conflict

Worktree `folio` has local changes that conflict with the newly-merged master:

```
/captain-sync-all
```

Expected:
```
Step 6: folio sync conflicted (CONFLICT in apps/folio/config.ts).
  Not synced. Agent will resolve on next /session-resume.
  Dispatch sent to folio agent noting the pending conflict.
...
Sync complete:
  Worktrees synced: 16/17
  Pending agent resolution: folio
```

Exit 0 (soft failure — captain did its job; agent owns conflict).

---

## Integration examples

### Daily captain rhythm

```
# morning
/session-resume
/captain-sync-all           # reconcile with overnight activity
# ... work ...
/pr-captain-merge <N>
/pr-captain-post-merge <N>  # internally calls /captain-sync-all at Step 5
# ... more work ...
/session-end
/captain-sync-all           # optional: leave things tidy for tomorrow
```

### After a fleet-wide framework change

Captain lands PR #110 that modifies `.claude/settings.json`:

```
/pr-captain-post-merge 110
# → includes /captain-sync-all → fleet worktrees pick up settings.json
```

Every agent's next `/session-resume` copies the updated settings (via `worktree-sync`'s settings-copy step).

### Manual run after a squash PR on GitHub

External collaborator's PR was squash-merged on GitHub. Captain is unaware of the change:

```
git-captain fetch     # hmm, origin/master has new commits
/captain-sync-all     # reconcile
```

Step 3 detects diverge (local has coord commits; origin has squash commits); merge-commit resolution preserves both.
