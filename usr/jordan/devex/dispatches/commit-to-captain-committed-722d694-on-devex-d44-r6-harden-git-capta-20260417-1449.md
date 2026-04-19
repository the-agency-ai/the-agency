---
type: commit
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-17T06:49
status: created
priority: normal
subject: "Committed 722d694 on devex: D44-R6: harden: git-captain checkout-branch rejects git-invalid ref patterns (D44-R3 deferred findings)

Picks up 4 of the 9 deferred QG findings from PR #182 triage. Before this
commit the validation regex (widened in D44-R3) accepted names that
`git check-ref-format --branch` rejects, so users got a confusing failure
from git's internals instead of a clean error from the tool.

**Added structural checks** (pass 2 after the character-set regex):
- Rejects '..' sequences anywhere in the name (finding 6)
- Rejects '.lock' suffix (reserved for git ref lockfiles — finding 7)
- Rejects trailing hyphen, dot, or slash (finding 8)

Each rejection has a clear, targeted error message pointing at the
specific structural violation rather than lumping everything into
'Invalid branch name'.

**Test assertion strengthened** (finding 10):
- 'checkout-branch: valid name test-branch succeeds' now also verifies
  the branch was actually created and checked out, matching the rigor
  of the D44-R3 positive tests.

**Added coverage** (findings 11-12):
- Positive: v1.0 (dotted version), my_branch (underscore), feature-lock
  (only '.lock' suffix is forbidden, mid-name 'lock' is fine)
- Negative: trailing '.'/'/'/'-'/'.lock', '..' sequences

**Doc synced:** REFERENCE-SAFE-TOOLS.md checkout-branch now lists the
structural rule alongside the character-set rule.

**Deferred (not in this release):**
- Finding 13 (usage() format hint) — minor UX improvement, separate pass
- Finding 14 (document D{N}-R{M} naming convention) — framework-wide
- Finding 15 (full check-ref-format delegation) — deliberate existing
  design, inline rules preferred for predictability

Tests: 58/58 git-captain.bats (+7 new). No regressions."
in_reply_to: null
---

# Committed 722d694 on devex: D44-R6: harden: git-captain checkout-branch rejects git-invalid ref patterns (D44-R3 deferred findings)

Picks up 4 of the 9 deferred QG findings from PR #182 triage. Before this
commit the validation regex (widened in D44-R3) accepted names that
`git check-ref-format --branch` rejects, so users got a confusing failure
from git's internals instead of a clean error from the tool.

**Added structural checks** (pass 2 after the character-set regex):
- Rejects '..' sequences anywhere in the name (finding 6)
- Rejects '.lock' suffix (reserved for git ref lockfiles — finding 7)
- Rejects trailing hyphen, dot, or slash (finding 8)

Each rejection has a clear, targeted error message pointing at the
specific structural violation rather than lumping everything into
'Invalid branch name'.

**Test assertion strengthened** (finding 10):
- 'checkout-branch: valid name test-branch succeeds' now also verifies
  the branch was actually created and checked out, matching the rigor
  of the D44-R3 positive tests.

**Added coverage** (findings 11-12):
- Positive: v1.0 (dotted version), my_branch (underscore), feature-lock
  (only '.lock' suffix is forbidden, mid-name 'lock' is fine)
- Negative: trailing '.'/'/'/'-'/'.lock', '..' sequences

**Doc synced:** REFERENCE-SAFE-TOOLS.md checkout-branch now lists the
structural rule alongside the character-set rule.

**Deferred (not in this release):**
- Finding 13 (usage() format hint) — minor UX improvement, separate pass
- Finding 14 (document D{N}-R{M} naming convention) — framework-wide
- Finding 15 (full check-ref-format delegation) — deliberate existing
  design, inline rules preferred for predictability

Tests: 58/58 git-captain.bats (+7 new). No regressions.

## Commit: 722d694

**Branch:** devex
**Agent:** the-agency/jordan/devex
**Message:** housekeeping/captain: D44-R6: harden: git-captain checkout-branch rejects git-invalid ref patterns (D44-R3 deferred findings)

Picks up 4 of the 9 deferred QG findings from PR #182 triage. Before this
commit the validation regex (widened in D44-R3) accepted names that
`git check-ref-format --branch` rejects, so users got a confusing failure
from git's internals instead of a clean error from the tool.

**Added structural checks** (pass 2 after the character-set regex):
- Rejects '..' sequences anywhere in the name (finding 6)
- Rejects '.lock' suffix (reserved for git ref lockfiles — finding 7)
- Rejects trailing hyphen, dot, or slash (finding 8)

Each rejection has a clear, targeted error message pointing at the
specific structural violation rather than lumping everything into
'Invalid branch name'.

**Test assertion strengthened** (finding 10):
- 'checkout-branch: valid name test-branch succeeds' now also verifies
  the branch was actually created and checked out, matching the rigor
  of the D44-R3 positive tests.

**Added coverage** (findings 11-12):
- Positive: v1.0 (dotted version), my_branch (underscore), feature-lock
  (only '.lock' suffix is forbidden, mid-name 'lock' is fine)
- Negative: trailing '.'/'/'/'-'/'.lock', '..' sequences

**Doc synced:** REFERENCE-SAFE-TOOLS.md checkout-branch now lists the
structural rule alongside the character-set rule.

**Deferred (not in this release):**
- Finding 13 (usage() format hint) — minor UX improvement, separate pass
- Finding 14 (document D{N}-R{M} naming convention) — framework-wide
- Finding 15 (full check-ref-format delegation) — deliberate existing
  design, inline rules preferred for predictability

Tests: 58/58 git-captain.bats (+7 new). No regressions.

### Metadata
- commit_hash: 722d694
- branch: devex
- files_changed: 4
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
claude/REFERENCE-SAFE-TOOLS.md
claude/tools/git-captain
tests/tools/git-captain.bats
usr/jordan/devex/dispatches/commit-to-captain-committed-d650f09-on-devex-d44-r5-fix-skill-verify-20260417-1443.md
```
