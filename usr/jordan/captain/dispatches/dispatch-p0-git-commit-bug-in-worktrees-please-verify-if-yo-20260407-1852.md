---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-cli
date: 2026-04-07T10:52
status: created
priority: high
subject: "P0 git-commit bug in worktrees — please verify if you reproduce"
in_reply_to: null
---

# P0 git-commit bug in worktrees — please verify if you reproduce

mdpal-app reported (#155) that ./claude/tools/git-commit wipes the index when run from a worktree — leaves ~1280 files showing as deleted, no commit made. Devex is triaging as P0 (#157). Please verify in your worktree: modify a tracked file, git add, run ./claude/tools/git-commit "test" --no-work-item, then git status. If you reproduce, fall back to raw 'git -c core.hooksPath=/dev/null commit' until devex ships a fix. Pause /iteration-complete and /phase-complete until then. Report back.
