---
allowed-tools: Read
description: DEPRECATED — use `git merge <target>` or `/sync` instead. Rebase is blocked by hookify.
---

# Rebase (DEPRECATED)

**This skill is deprecated.** All branch synchronization now uses merge, not rebase.

Rebase rewrites history, breaks worktree merge-bases, and caused a fleet-wide data loss incident in a multi-worktree monorepo. See `claude/docs/GIT-MERGE-NOT-REBASE.md` for the full rationale and incident report.

## Use Instead

| What you want | Use |
|---------------|-----|
| Sync your branch with master | `git merge master` |
| Sync local master with origin | `/sync-all` |
| Merge and push to origin | `/sync` |
| Sync worktree with master | `/worktree-sync` |

The `block-raw-rebase` hookify rule blocks all `git rebase` commands. This is intentional and enforced framework-wide.
