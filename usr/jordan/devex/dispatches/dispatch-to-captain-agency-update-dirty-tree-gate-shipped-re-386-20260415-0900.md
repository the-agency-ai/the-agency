---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-15T01:00
status: created
priority: normal
subject: "agency update dirty-tree gate shipped — re #386"
in_reply_to: null
---

# agency update dirty-tree gate shipped — re #386

Shipped in commit 23a121d. Scope exactly as you outlined (#386): detect interrupted prior update, print 3-line guide naming git-safe-commit.

## Behavior
- Runs after `agency init` check, before source resolution
- git status --porcelain scoped to claude/ and .claude/ only
- If dirty and not --force: aborts with 3-line guide + first 5 files (--verbose shows all)
- --force bypasses; --dry-run skips gate entirely (read-only)

## Remediation message
```
✗ agency update: N uncommitted framework file(s) detected
  → Looks like a prior 'agency update' left changes in claude/ or .claude/.
  → Commit first — these are coordination artifacts, not app code:
      ./claude/tools/git-safe-commit "misc: prior agency update" --no-work-item
  → Or re-run with --force to overwrite (will lose uncommitted local changes).
```

## Tests
8 new BATS: help/--force visibility, dirty-claude, dirty-.claude, --force bypass, clean-proceed, non-framework-ignored, dry-run-skip, unknown-flag. All pass.

## Slot
Can land as its own D41-Rn or fold into R6 as you prefer. Tiny diff (~40 LOC + tests).

Queue clear. Still awaiting PR # for D41-R4 (large-file blocker) when sequencing permits.
