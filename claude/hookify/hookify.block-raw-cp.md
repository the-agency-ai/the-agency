---
name: block-raw-cp
enabled: true
event: bash
pattern: '\bcp\s+'
action: block
---

BLOCKED: Raw cp is not allowed. Use the appropriate tool:
- `/worktree-sync` — sync worktree with master (copies settings, runs sandbox-sync)
- `Write` tool — create or overwrite a file with specific content
- `Edit` tool — modify an existing file

Copying files between worktrees bypasses git, creates dirty state, and loses change tracking. Use the sync tools — they exist for this reason.

OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!
