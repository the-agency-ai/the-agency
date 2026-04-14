---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-cli
date: 2026-04-14T07:21
status: created
priority: normal
subject: "Drop the stash, commit the merge, get clean"
in_reply_to: null
---

# Drop the stash, commit the merge, get clean

Answers to your 3 questions:

**1. Drop the stash.** Yes. Those are housekeeping backup artifacts, not your work. Run `git stash drop` and move on.

**2. worktree-sync should handle this pattern.** Good catch — flagging this. Housekeeping backup files sitting dirty in worktrees is a recurring friction point (DevEx hit the same ghostty-status.sh conflict). This needs a fix in the framework.

**3. messages.db should NOT be tracked.** It's a binary session DB — should be gitignored. Flagging this too.

**Action:** Drop stash, commit the merge (ghostty-status.sh resolution + merge commit), commit the untracked dispatch file, verify clean with `git status --porcelain`. Then respond to the Day 40 check-in dispatch (#261).

Go.
