---
type: commit
from: the-agency/jordan/fix-qg-hash-order
to: the-agency/jordan/captain
date: 2026-08-13T09:33
status: created
priority: normal
subject: "Committed 3144c225 on fix-qg-hash-order: fix(diff-hash): --working now includes untracked new files (QG review)

Both QG reviewers found a real hole: 'git diff <ref>' ignores UNTRACKED files,
but git-safe-commit runs 'git add -A' — so a QG's new test/fix files get
committed while --working (pre-commit) omitted them. Hash E would undercount and
receipt-verify would then BLOCK the legitimate commit (receipt churn, opposite
direction).

Fix: in --working mode, mark untracked files intent-to-add ('git add -N') so
they surface as new-file diffs matching the post-commit BASE..HEAD hash — done
in a THROWAWAY copy of the index (GIT_INDEX_FILE) so the caller's real staging
state is never mutated. Teardown runs before any exit.

Proven: --working with an untracked new file == default post-commit hash, and
the real index is left untouched (file stays '??'). +3 tests (untracked
consistency, index-untouched, --file/--working guard) → 20 diff-hash tests green,
receipt-sign/verify unaffected."
in_reply_to: null
---

# Committed 3144c225 on fix-qg-hash-order: fix(diff-hash): --working now includes untracked new files (QG review)

Both QG reviewers found a real hole: 'git diff <ref>' ignores UNTRACKED files,
but git-safe-commit runs 'git add -A' — so a QG's new test/fix files get
committed while --working (pre-commit) omitted them. Hash E would undercount and
receipt-verify would then BLOCK the legitimate commit (receipt churn, opposite
direction).

Fix: in --working mode, mark untracked files intent-to-add ('git add -N') so
they surface as new-file diffs matching the post-commit BASE..HEAD hash — done
in a THROWAWAY copy of the index (GIT_INDEX_FILE) so the caller's real staging
state is never mutated. Teardown runs before any exit.

Proven: --working with an untracked new file == default post-commit hash, and
the real index is left untouched (file stays '??'). +3 tests (untracked
consistency, index-untouched, --file/--working guard) → 20 diff-hash tests green,
receipt-sign/verify unaffected.

## Commit: 3144c225

**Branch:** fix-qg-hash-order
**Agent:** the-agency/jordan/fix-qg-hash-order
**Message:** housekeeping/captain: fix(diff-hash): --working now includes untracked new files (QG review)

Both QG reviewers found a real hole: 'git diff <ref>' ignores UNTRACKED files,
but git-safe-commit runs 'git add -A' — so a QG's new test/fix files get
committed while --working (pre-commit) omitted them. Hash E would undercount and
receipt-verify would then BLOCK the legitimate commit (receipt churn, opposite
direction).

Fix: in --working mode, mark untracked files intent-to-add ('git add -N') so
they surface as new-file diffs matching the post-commit BASE..HEAD hash — done
in a THROWAWAY copy of the index (GIT_INDEX_FILE) so the caller's real staging
state is never mutated. Teardown runs before any exit.

Proven: --working with an untracked new file == default post-commit hash, and
the real index is left untouched (file stays '??'). +3 tests (untracked
consistency, index-untouched, --file/--working guard) → 20 diff-hash tests green,
receipt-sign/verify unaffected.

### Metadata
- commit_hash: 3144c225
- branch: fix-qg-hash-order
- files_changed: 4
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/tools/diff-hash
src/agency/tools/diff-hash
src/tests/tools/diff-hash.bats
usr/jordan/fix-qg-hash-order/dispatches/commit-to-captain-committed-5cad4b14-on-fix-qg-hash-order-fix-diff-h-20260813-1723.md
```
