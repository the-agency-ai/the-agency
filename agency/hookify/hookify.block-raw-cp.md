---
name: block-raw-cp
enabled: true
event: bash
pattern: '\bcp\s+'
action: block
---

BLOCKED: Raw cp is not allowed. Use `./claude/tools/cp-safe` instead:
- `cp-safe <source> <dest>` — copies within the same worktree (blocks cross-worktree)
- `/worktree-sync` — sync worktree with master
- `Write` tool — create a file with specific content

Cross-worktree copying bypasses git, creates dirty state, and loses change tracking.

OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!
