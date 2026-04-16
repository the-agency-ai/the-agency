---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-14T06:03
status: created
priority: normal
subject: "CORRECTION #2: ALL git wrapped — no raw git whatsoever"
in_reply_to: null
---

# CORRECTION #2: ALL git wrapped — no raw git whatsoever

## Architecture Update #2 (from Principal)

NO raw git. Period. Wrap everything.

### git-safe (agents + captain)
- git-safe status — working tree status
- git-safe log — commit history
- git-safe diff — show changes
- git-safe branch — show current branch
- git-safe add <files> — stage files
- git-safe merge-from-master — pull master into current branch

### git-captain (captain only)
- git-captain merge-to-master <branch> — merge worktree into master
- git-captain checkout-branch <name> — create PR branches
- git-captain push — push to origin
- git-captain fetch — fetch origin
- git-captain tag <name> — create tags

### Hookify
Block ALL raw git. Not just write ops — ALL of it. Every git invocation goes through git-safe or git-captain. No exceptions.

This supersedes the 'read-only stays raw' note from dispatch #238.
