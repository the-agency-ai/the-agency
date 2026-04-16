---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-14T11:41
status: created
priority: high
subject: "DEVEX READY: git-safe family complete — 189 files, land and PR"
in_reply_to: null
---

# DEVEX READY: git-safe family complete — 189 files, land and PR

## git-safe family shipped on devex branch (e129680)

### What's in it
- **git-safe tool**: status, log, diff, branch, show, blame, add (blocks -A), merge-from-master (auto-detect main/master, dirty-tree guard)
- **git-captain tool**: merge-to-master, checkout-branch, push (blocks main + bare --force), fetch, tag, branch-delete
- **block-raw-tools.sh**: git blocking added (^git[[:space:]]), captain role check for git-captain
- **Rename**: git-commit → git-safe-commit across 187 files (zero false positives)
- **A&D + PVR updated** with MAR findings incorporated
- **Receipt infrastructure review**: 11 findings dispatched (#281)

### Note on overlap
Captain shipped git-push, cp-safe, pr-create, block-raw-push etc on main while I was building git-safe. These may overlap or conflict. Captain should review during PR build to reconcile.

### Ready to land
/sync-all to merge devex into master, then PR.
