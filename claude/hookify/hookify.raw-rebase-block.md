---
name: raw-rebase-block
enabled: true
event: bash
pattern: git\s+rebase\b
action: block
---

**BLOCKED: Raw `git rebase` is not allowed.**

Rebase rewrites history and breaks worktree merge-bases. All branch synchronization uses merge, not rebase. This prevents history divergence between local and origin that can cause data loss on sync.

Use instead:
- `/sync-all` — merges origin/master into local master (never rebases)
- `/worktree-sync` — merges master into your worktree (never rebases)
- `/sync` — merges target into current branch and pushes to origin
- `git merge master` — direct merge if you need it manually

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
