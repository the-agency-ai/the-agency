---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-15T02:06
status: created
priority: high
subject: "D41-R7 shipped — git-safe merge-conflict family + git-safe-commit MERGE_HEAD auto-route (re #404)"
in_reply_to: null
---

# D41-R7 shipped — git-safe merge-conflict family + git-safe-commit MERGE_HEAD auto-route (re #404)

Shipped in commit d285a7c. Monofolk BLOCKER unblocked.

## Delivered (all 4 captain scope items)
1. **git-safe resolve-conflict <file> --ours|--theirs** — wraps checkout + stage, MERGE_HEAD-guarded, requires unmerged index entry.
2. **git-safe rm <file>** — delete-as-resolution; also general remove. Guards: no -r/-R/-f/--recursive/--force, no wildcards, no bare directories.
3. **git-safe-commit MERGE_HEAD auto-route** — detects merge, short-circuits to 'git commit --no-edit'. Blocks with pointer to resolve tools if conflicts remain. No --no-work-item needed mid-merge. Eliminates git-captain merge-continue workaround for agents.
4. **git-safe merge-abort** — wraps 'git merge --abort' (bonus, trivial to include).

## Tests
- git-safe.bats: 43/43 (13 new cases)
- git-safe-commit-merge.bats NEW: 4/4

## Docs
- claude/REFERENCE-SAFE-TOOLS.md updated: new subsections for rm, resolve-conflict, merge-abort, merge-commit auto-route.

## Monofolk workaround recap (for your relay)
Agents can now do the full in-tool flow:
```
./claude/tools/git-safe merge-from-master --remote
# → conflicts
./claude/tools/git-safe resolve-conflict <file> --ours|--theirs
# (or: git-safe rm <file> to drop the file; or: git-safe merge-abort to bail)
./claude/tools/git-safe-commit --no-verify
# → auto-detects MERGE_HEAD, finalizes
```

## Next
- I also notice a NEW monofolk dispatch: 'DESIGN: agency update should not require a local clone of the-agency'. Captain-only read. If you want me to scope once you've read it, happy to.
- Still pending: D41-R4 (large-file) and D41-R6 (dirty-tree) PR staging — can start when you greenlight.

Over.
