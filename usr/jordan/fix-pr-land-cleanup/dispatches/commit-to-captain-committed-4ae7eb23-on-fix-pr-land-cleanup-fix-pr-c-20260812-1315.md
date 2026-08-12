---
type: commit
from: the-agency/jordan/fix-pr-land-cleanup
to: the-agency/jordan/captain
date: 2026-08-12T05:15
status: created
priority: normal
subject: "Committed 4ae7eb23 on fix-pr-land-cleanup: fix(pr-captain-land): stop passing --delete-branch to pr-merge; delete remote land branch explicitly in step 9

gh pr merge --delete-branch=true also deletes the LOCAL _land-<slug> branch,
but the scratch worktree still holds it at merge time (torn down in step 9).
The local delete failed, pr-merge exited non-zero, and the whole step aborted
AFTER the server-side merge already landed — release uncut, reconcile un-run.
Observed live on PRs #467 and #468 (flag #236).

Fix: drop --delete-branch from the merge args; after destroy_scratch frees the
local branch, delete the REMOTE ref via gh-api ... --method DELETE (best-effort).
Docs + comments updated; 4 regression bats added (48/48 green)."
in_reply_to: null
---

# Committed 4ae7eb23 on fix-pr-land-cleanup: fix(pr-captain-land): stop passing --delete-branch to pr-merge; delete remote land branch explicitly in step 9

gh pr merge --delete-branch=true also deletes the LOCAL _land-<slug> branch,
but the scratch worktree still holds it at merge time (torn down in step 9).
The local delete failed, pr-merge exited non-zero, and the whole step aborted
AFTER the server-side merge already landed — release uncut, reconcile un-run.
Observed live on PRs #467 and #468 (flag #236).

Fix: drop --delete-branch from the merge args; after destroy_scratch frees the
local branch, delete the REMOTE ref via gh-api ... --method DELETE (best-effort).
Docs + comments updated; 4 regression bats added (48/48 green).

## Commit: 4ae7eb23

**Branch:** fix-pr-land-cleanup
**Agent:** the-agency/jordan/fix-pr-land-cleanup
**Message:** housekeeping/captain: fix(pr-captain-land): stop passing --delete-branch to pr-merge; delete remote land branch explicitly in step 9

gh pr merge --delete-branch=true also deletes the LOCAL _land-<slug> branch,
but the scratch worktree still holds it at merge time (torn down in step 9).
The local delete failed, pr-merge exited non-zero, and the whole step aborted
AFTER the server-side merge already landed — release uncut, reconcile un-run.
Observed live on PRs #467 and #468 (flag #236).

Fix: drop --delete-branch from the merge args; after destroy_scratch frees the
local branch, delete the REMOTE ref via gh-api ... --method DELETE (best-effort).
Docs + comments updated; 4 regression bats added (48/48 green).

### Metadata
- commit_hash: 4ae7eb23
- branch: fix-pr-land-cleanup
- files_changed: 7
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/pr-captain-land/SKILL.md
.claude/skills/pr-captain-land/reference.md
.claude/skills/pr-captain-land/scripts/pr-captain-land
src/claude/skills/pr-captain-land/SKILL.md
src/claude/skills/pr-captain-land/reference.md
src/claude/skills/pr-captain-land/scripts/pr-captain-land
src/tests/skills/pr-captain-land-localfirst.bats
```
