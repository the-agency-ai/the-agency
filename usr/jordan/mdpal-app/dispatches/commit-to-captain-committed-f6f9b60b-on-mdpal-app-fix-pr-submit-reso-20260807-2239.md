---
type: commit
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/captain
date: 2026-08-07T14:39
status: created
priority: normal
subject: "Committed f6f9b60b on mdpal-app: fix(pr-submit): resolve the default branch instead of hardcoding origin/master

pr-submit computed its receipt-matching diff hash against a literal
origin/master. In any repo whose default branch is main — this one — that
ref does not exist, diff-hash exits non-zero, the hash comes back empty, and
the agent gets 'could not compute diff hash' with nothing pointing at the
ref name as the cause. It blocks the handoff for every agent in the repo,
which is where I hit it submitting the mdpal-app branch.

Resolve from refs/remotes/origin/HEAD, falling back to whichever of
main/master exists, and report the resolved ref in both the error message
and the dispatch body."
in_reply_to: null
---

# Committed f6f9b60b on mdpal-app: fix(pr-submit): resolve the default branch instead of hardcoding origin/master

pr-submit computed its receipt-matching diff hash against a literal
origin/master. In any repo whose default branch is main — this one — that
ref does not exist, diff-hash exits non-zero, the hash comes back empty, and
the agent gets 'could not compute diff hash' with nothing pointing at the
ref name as the cause. It blocks the handoff for every agent in the repo,
which is where I hit it submitting the mdpal-app branch.

Resolve from refs/remotes/origin/HEAD, falling back to whichever of
main/master exists, and report the resolved ref in both the error message
and the dispatch body.

## Commit: f6f9b60b

**Branch:** mdpal-app
**Agent:** the-agency/jordan/mdpal-app
**Message:** housekeeping/captain: fix(pr-submit): resolve the default branch instead of hardcoding origin/master

pr-submit computed its receipt-matching diff hash against a literal
origin/master. In any repo whose default branch is main — this one — that
ref does not exist, diff-hash exits non-zero, the hash comes back empty, and
the agent gets 'could not compute diff hash' with nothing pointing at the
ref name as the cause. It blocks the handoff for every agent in the repo,
which is where I hit it submitting the mdpal-app branch.

Resolve from refs/remotes/origin/HEAD, falling back to whichever of
main/master exists, and report the resolved ref in both the error message
and the dispatch body.

### Metadata
- commit_hash: f6f9b60b
- branch: mdpal-app
- files_changed: 1
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/pr-submit/scripts/pr-submit
```
