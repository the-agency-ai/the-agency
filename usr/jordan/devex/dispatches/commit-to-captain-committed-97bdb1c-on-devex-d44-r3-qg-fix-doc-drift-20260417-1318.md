---
type: commit
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-17T05:18
status: created
priority: normal
subject: "Committed 97bdb1c on devex: D44-R3 QG: fix doc drift, self-ref comment, consolidate tests

QG findings fixed in this commit:
1. REFERENCE-SAFE-TOOLS.md line 123 — update documented regex to match widened tool behavior
2. git-captain:117 comment — rename 'D42-R1-regex-fix' example to 'D44-R3-regex-fix' (self-ref drift after release rename)
3. tests/tools/git-captain.bats — remove redundant leading-hyphen test (kept pre-existing 'name starting with hyphen fails')
4. tests/tools/git-captain.bats — add digits-only positive test (20260417)
5. tests/tools/git-captain.bats — add non-ASCII rejection test (café)

9 deferred findings tracked for follow-up (regex gaps: .., .lock, trailing hyphen; pre-existing test-coverage gaps; documentation improvements).
1 rejected: TOCTOU in single-user CLI context — non-concern.

Tests: 50/50 git-captain.bats, 121/121 adjacent suites."
in_reply_to: null
---

# Committed 97bdb1c on devex: D44-R3 QG: fix doc drift, self-ref comment, consolidate tests

QG findings fixed in this commit:
1. REFERENCE-SAFE-TOOLS.md line 123 — update documented regex to match widened tool behavior
2. git-captain:117 comment — rename 'D42-R1-regex-fix' example to 'D44-R3-regex-fix' (self-ref drift after release rename)
3. tests/tools/git-captain.bats — remove redundant leading-hyphen test (kept pre-existing 'name starting with hyphen fails')
4. tests/tools/git-captain.bats — add digits-only positive test (20260417)
5. tests/tools/git-captain.bats — add non-ASCII rejection test (café)

9 deferred findings tracked for follow-up (regex gaps: .., .lock, trailing hyphen; pre-existing test-coverage gaps; documentation improvements).
1 rejected: TOCTOU in single-user CLI context — non-concern.

Tests: 50/50 git-captain.bats, 121/121 adjacent suites.

## Commit: 97bdb1c

**Branch:** devex
**Agent:** the-agency/jordan/devex
**Message:** housekeeping/captain: D44-R3 QG: fix doc drift, self-ref comment, consolidate tests

QG findings fixed in this commit:
1. REFERENCE-SAFE-TOOLS.md line 123 — update documented regex to match widened tool behavior
2. git-captain:117 comment — rename 'D42-R1-regex-fix' example to 'D44-R3-regex-fix' (self-ref drift after release rename)
3. tests/tools/git-captain.bats — remove redundant leading-hyphen test (kept pre-existing 'name starting with hyphen fails')
4. tests/tools/git-captain.bats — add digits-only positive test (20260417)
5. tests/tools/git-captain.bats — add non-ASCII rejection test (café)

9 deferred findings tracked for follow-up (regex gaps: .., .lock, trailing hyphen; pre-existing test-coverage gaps; documentation improvements).
1 rejected: TOCTOU in single-user CLI context — non-concern.

Tests: 50/50 git-captain.bats, 121/121 adjacent suites.

### Metadata
- commit_hash: 97bdb1c
- branch: devex
- files_changed: 4
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/REFERENCE-SAFE-TOOLS.md
agency/tools/git-captain
tests/tools/git-captain.bats
usr/jordan/devex/dispatches/commit-to-captain-committed-51211ed-on-devex-d44-r3-feat-git-captain-20260417-1254.md
```
