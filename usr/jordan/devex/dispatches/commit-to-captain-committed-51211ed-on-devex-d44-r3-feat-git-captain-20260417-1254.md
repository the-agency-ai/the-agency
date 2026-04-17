---
type: commit
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-17T04:54
status: created
priority: normal
subject: "Committed 51211ed on devex: D44-R3: feat: git-captain checkout-branch regex accepts uppercase (closes #428 item 1)

Widen the branch-name validation regex in cmd_checkout_branch from
  ^[a-z0-9][a-z0-9._/-]*$
to
  ^[a-zA-Z0-9][a-zA-Z0-9._/-]*$

Previously, lowercase-only regex rejected conventional release and feature
branch names like 'D7-R1', 'Feature/ABC', 'MyBranch'. Widening the accept
pattern brings the tool in line with workstream naming conventions. Leading
hyphen and other invalid characters are still rejected.

Tests updated: the prior 'uppercase name fails' assertion is replaced with
'uppercase name succeeds' plus three new positive cases (mixed-case release,
nested uppercase path, uppercase single name) and two regression tests
confirming leading hyphen and invalid characters still fail.

Closes #428 item 1."
in_reply_to: null
---

# Committed 51211ed on devex: D44-R3: feat: git-captain checkout-branch regex accepts uppercase (closes #428 item 1)

Widen the branch-name validation regex in cmd_checkout_branch from
  ^[a-z0-9][a-z0-9._/-]*$
to
  ^[a-zA-Z0-9][a-zA-Z0-9._/-]*$

Previously, lowercase-only regex rejected conventional release and feature
branch names like 'D7-R1', 'Feature/ABC', 'MyBranch'. Widening the accept
pattern brings the tool in line with workstream naming conventions. Leading
hyphen and other invalid characters are still rejected.

Tests updated: the prior 'uppercase name fails' assertion is replaced with
'uppercase name succeeds' plus three new positive cases (mixed-case release,
nested uppercase path, uppercase single name) and two regression tests
confirming leading hyphen and invalid characters still fail.

Closes #428 item 1.

## Commit: 51211ed

**Branch:** devex
**Agent:** the-agency/jordan/devex
**Message:** housekeeping/captain: D44-R3: feat: git-captain checkout-branch regex accepts uppercase (closes #428 item 1)

Widen the branch-name validation regex in cmd_checkout_branch from
  ^[a-z0-9][a-z0-9._/-]*$
to
  ^[a-zA-Z0-9][a-zA-Z0-9._/-]*$

Previously, lowercase-only regex rejected conventional release and feature
branch names like 'D7-R1', 'Feature/ABC', 'MyBranch'. Widening the accept
pattern brings the tool in line with workstream naming conventions. Leading
hyphen and other invalid characters are still rejected.

Tests updated: the prior 'uppercase name fails' assertion is replaced with
'uppercase name succeeds' plus three new positive cases (mixed-case release,
nested uppercase path, uppercase single name) and two regression tests
confirming leading hyphen and invalid characters still fail.

Closes #428 item 1.

### Metadata
- commit_hash: 51211ed
- branch: devex
- files_changed: 6
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
claude/tools/git-captain
tests/tools/git-captain.bats
usr/jordan/devex/dispatches/commit-to-captain-committed-19f020f-on-devex-housekeeping-devex-misc-20260417-0919.md
usr/jordan/devex/dispatches/commit-to-captain-committed-9823036-on-devex-housekeeping-devex-misc-20260417-1249.md
usr/jordan/devex/history/handoff-20260417-124145.md
usr/jordan/devex/history/handoff-20260417-124146.md
```
