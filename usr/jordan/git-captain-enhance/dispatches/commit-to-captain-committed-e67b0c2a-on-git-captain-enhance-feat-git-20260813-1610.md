---
type: commit
from: the-agency/jordan/git-captain-enhance
to: the-agency/jordan/captain
date: 2026-08-13T08:10
status: created
priority: normal
subject: "Committed e67b0c2a on git-captain-enhance: feat(git-captain): add cherry-pick + feature-merge subcommands (flag #120/#109) — v1.1.0

Two gaps in the captain's safe-git surface that forced raw git (hookify-blocked):
- 'git-captain merge <branch>': merge a branch INTO the current feature branch
  (--no-ff). merge-to-master already covered integration into the default branch;
  this is the feature→feature sibling. Refuses on the default branch, on self,
  on detached HEAD, and on a non-existent branch.
- 'git-captain cherry-pick <commit>...': apply commit(s) onto the current feature
  branch (with --continue/--abort). The isolate-good-commits-off-a-mixed-branch
  case (hit this session lifting the worktree-create fix off devex). Validates
  each ref up front, refuses on the default branch / detached HEAD.

10 new bats (71 total, all green). Both --no-ff for visible merge commits.

#115 (detect_main_branch when main is deleted locally) is already handled by the
resolve-default-branch primitive detect_main_branch delegates to (unions local +
origin/HEAD + origin/{main,master})."
in_reply_to: null
---

# Committed e67b0c2a on git-captain-enhance: feat(git-captain): add cherry-pick + feature-merge subcommands (flag #120/#109) — v1.1.0

Two gaps in the captain's safe-git surface that forced raw git (hookify-blocked):
- 'git-captain merge <branch>': merge a branch INTO the current feature branch
  (--no-ff). merge-to-master already covered integration into the default branch;
  this is the feature→feature sibling. Refuses on the default branch, on self,
  on detached HEAD, and on a non-existent branch.
- 'git-captain cherry-pick <commit>...': apply commit(s) onto the current feature
  branch (with --continue/--abort). The isolate-good-commits-off-a-mixed-branch
  case (hit this session lifting the worktree-create fix off devex). Validates
  each ref up front, refuses on the default branch / detached HEAD.

10 new bats (71 total, all green). Both --no-ff for visible merge commits.

#115 (detect_main_branch when main is deleted locally) is already handled by the
resolve-default-branch primitive detect_main_branch delegates to (unions local +
origin/HEAD + origin/{main,master}).

## Commit: e67b0c2a

**Branch:** git-captain-enhance
**Agent:** the-agency/jordan/git-captain-enhance
**Message:** housekeeping/captain: feat(git-captain): add cherry-pick + feature-merge subcommands (flag #120/#109) — v1.1.0

Two gaps in the captain's safe-git surface that forced raw git (hookify-blocked):
- 'git-captain merge <branch>': merge a branch INTO the current feature branch
  (--no-ff). merge-to-master already covered integration into the default branch;
  this is the feature→feature sibling. Refuses on the default branch, on self,
  on detached HEAD, and on a non-existent branch.
- 'git-captain cherry-pick <commit>...': apply commit(s) onto the current feature
  branch (with --continue/--abort). The isolate-good-commits-off-a-mixed-branch
  case (hit this session lifting the worktree-create fix off devex). Validates
  each ref up front, refuses on the default branch / detached HEAD.

10 new bats (71 total, all green). Both --no-ff for visible merge commits.

#115 (detect_main_branch when main is deleted locally) is already handled by the
resolve-default-branch primitive detect_main_branch delegates to (unions local +
origin/HEAD + origin/{main,master}).

### Metadata
- commit_hash: e67b0c2a
- branch: git-captain-enhance
- files_changed: 3
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/tools/git-captain
src/agency/tools/git-captain
src/tests/tools/git-captain.bats
```
