---
type: commit
from: the-agency/jordan/fix-qg-hash-order
to: the-agency/jordan/captain
date: 2026-08-13T09:23
status: created
priority: normal
subject: "Committed 5cad4b14 on fix-qg-hash-order: fix(diff-hash): add --working mode so the QG can hash uncommitted work (flag #207)

The QG signs its receipt BEFORE the caller commits, but diff-hash compared
BASE..HEAD (committed tip only) — blind to the uncommitted fixes. So Hash E
collapsed onto Hash A (the mdslidepal QG hit exactly this: first receipt came
back E==A). Agents worked around it by committing first, then hashing.

Fix: 'diff-hash --working' hashes BASE vs the WORKING TREE (staged + unstaged),
so it sees uncommitted work. It is safe for the five-hash chain: once the work
is committed and the tree is clean, 'git diff BASE' == 'git diff BASE..HEAD', so
receipt-verify (which runs default, on the committed tree) still matches the
--working hash the QG recorded. Proven by a cross-boundary bats test.

quality-gate SKILL.md now captures Hash A (Step 0) and Hash E (Step 10) with
--working. REFERENCE-RECEIPT-INFRASTRUCTURE documents the mode. 4 new diff-hash
bats (18 total): sees-uncommitted, cross-boundary consistency (#207), new staged
file, --help. Zero regressions in receipt-sign/verify."
in_reply_to: null
---

# Committed 5cad4b14 on fix-qg-hash-order: fix(diff-hash): add --working mode so the QG can hash uncommitted work (flag #207)

The QG signs its receipt BEFORE the caller commits, but diff-hash compared
BASE..HEAD (committed tip only) — blind to the uncommitted fixes. So Hash E
collapsed onto Hash A (the mdslidepal QG hit exactly this: first receipt came
back E==A). Agents worked around it by committing first, then hashing.

Fix: 'diff-hash --working' hashes BASE vs the WORKING TREE (staged + unstaged),
so it sees uncommitted work. It is safe for the five-hash chain: once the work
is committed and the tree is clean, 'git diff BASE' == 'git diff BASE..HEAD', so
receipt-verify (which runs default, on the committed tree) still matches the
--working hash the QG recorded. Proven by a cross-boundary bats test.

quality-gate SKILL.md now captures Hash A (Step 0) and Hash E (Step 10) with
--working. REFERENCE-RECEIPT-INFRASTRUCTURE documents the mode. 4 new diff-hash
bats (18 total): sees-uncommitted, cross-boundary consistency (#207), new staged
file, --help. Zero regressions in receipt-sign/verify.

## Commit: 5cad4b14

**Branch:** fix-qg-hash-order
**Agent:** the-agency/jordan/fix-qg-hash-order
**Message:** housekeeping/captain: fix(diff-hash): add --working mode so the QG can hash uncommitted work (flag #207)

The QG signs its receipt BEFORE the caller commits, but diff-hash compared
BASE..HEAD (committed tip only) — blind to the uncommitted fixes. So Hash E
collapsed onto Hash A (the mdslidepal QG hit exactly this: first receipt came
back E==A). Agents worked around it by committing first, then hashing.

Fix: 'diff-hash --working' hashes BASE vs the WORKING TREE (staged + unstaged),
so it sees uncommitted work. It is safe for the five-hash chain: once the work
is committed and the tree is clean, 'git diff BASE' == 'git diff BASE..HEAD', so
receipt-verify (which runs default, on the committed tree) still matches the
--working hash the QG recorded. Proven by a cross-boundary bats test.

quality-gate SKILL.md now captures Hash A (Step 0) and Hash E (Step 10) with
--working. REFERENCE-RECEIPT-INFRASTRUCTURE documents the mode. 4 new diff-hash
bats (18 total): sees-uncommitted, cross-boundary consistency (#207), new staged
file, --help. Zero regressions in receipt-sign/verify.

### Metadata
- commit_hash: 5cad4b14
- branch: fix-qg-hash-order
- files_changed: 7
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/quality-gate/SKILL.md
agency/REFERENCE/REFERENCE-RECEIPT-INFRASTRUCTURE.md
agency/tools/diff-hash
src/agency/REFERENCE/REFERENCE-RECEIPT-INFRASTRUCTURE.md
src/agency/tools/diff-hash
src/claude/skills/quality-gate/SKILL.md
src/tests/tools/diff-hash.bats
```
