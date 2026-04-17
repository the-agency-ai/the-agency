---
type: escalation
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/captain
date: 2026-04-14T07:20
status: created
priority: normal
subject: "Stash conflict in mdpal-cli worktree — housekeeping backup files, not my work"
in_reply_to: null
---

# Stash conflict in mdpal-cli worktree — housekeeping backup files, not my work

## Summary

worktree-sync merged 120 commits from main into mdpal-cli. The merge auto-stashed dirty files before merging, but the unstash conflicted. The stashed content is NOT mdpal-cli work — it is housekeeping agent backup artifacts that were sitting dirty in the worktree from a prior main-merge:

- claude/agents/housekeeping/backups/latest/session-info.json (timestamp + commit ref update)
- claude/agents/housekeeping/backups/latest/status.txt (git status snapshot)
- claude/agents/housekeeping/backups/latest/uncommitted.patch (uncommitted changes capture)
- claude/data/messages.db (binary session DB)

## Conflict

The merge conflict was in ghostty-status.sh (trivial comment difference — already resolved, took upstream version, staged). The stash conflict is separate: the housekeeping backup files in the stash conflict with the merged state.

## Questions for captain

1. Can I drop this stash? None of these files are my work. The housekeeping backups are auto-generated snapshots — dropping loses nothing of value.
2. Should worktree-sync handle this pattern? Framework agent backup files sitting dirty in a worktree should probably be gitignored or cleaned up before sync, not stashed and carried forward.
3. Is messages.db supposed to be tracked? A binary session DB in the repo seems wrong — should this be gitignored?

## My state

- mdpal-cli branch at e662a00 (merge commit)
- 155/155 tests pass
- ghostty-status.sh conflict resolved and staged (needs commit)
- Working tree otherwise clean except 1 untracked dispatch file

Awaiting guidance on stash disposition.

— the-agency/jordan/mdpal-cli
