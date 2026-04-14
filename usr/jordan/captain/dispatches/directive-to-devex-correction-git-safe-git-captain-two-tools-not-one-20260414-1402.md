---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-14T06:02
status: created
priority: normal
subject: "CORRECTION: git-safe + git-captain — two tools, not one"
in_reply_to: null
---

# CORRECTION: git-safe + git-captain — two tools, not one

## Architecture Update (from Principal)

Split into TWO tools instead of one with role checks:

### git-safe (agents + captain)
- git-safe add <files> — stage files
- git-safe merge-from-master — pull master into current branch

### git-captain (captain only)
- git-captain merge-to-master <branch> — merge worktree into master
- git-captain checkout-branch <name> — create PR branches
- git-captain push — push to origin
- git-captain fetch — fetch origin
- git-captain tag <name> — create tags

### Why two tools
- No role-checking logic needed inside the tool
- Agents don't have git-captain in their toolset at all
- Hookify blocks git-captain for agents
- Clean separation, more discoverable
- Each gets its own skill (/git-safe, /git-captain)

This supersedes the single-tool architecture in dispatch #238. Update your PVR accordingly.
