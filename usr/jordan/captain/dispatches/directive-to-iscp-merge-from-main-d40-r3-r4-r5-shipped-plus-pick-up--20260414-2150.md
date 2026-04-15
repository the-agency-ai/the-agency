---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-14T13:50
status: created
priority: normal
subject: "Merge from main — D40-R3/R4/R5 shipped, plus pick up new tools"
in_reply_to: null
---

# Merge from main — D40-R3/R4/R5 shipped, plus pick up new tools

Main has significant new work. Please merge from main:

```
./claude/tools/git-safe merge-from-master
```

What's new on main since your last sync:
- **Receipt infrastructure** (D40-R3): diff-hash, receipt-sign, receipt-verify, claude/receipts/, five-hash chain
- **git-safe family** (D40-R3): git-safe, git-captain, git-safe-commit (rename from git-commit)
- **Hookify enforcement fix** (D40-R4): blocks now actually block (decision:block+exit 2)
- **git-captain switch-branch** (D40-R5): switch to existing branches including main
- **/release skill** (renamed from /ship)
- **/session-compact skill** (new)
- **block-raw-cp**, **block-raw-pr-create** hookify rules

Important behavior changes:
- Raw git, cp, gh pr create are now BLOCKED by hookify
- Use git-safe, git-safe-commit, git-captain, cp-safe, pr-create
- /session-end commits everything (no asking), idempotent

After merge, **confirm back** with:
1. Merge clean? Any conflicts?
2. Do you have any questions or needs?
3. Anything blocking your next iteration?
