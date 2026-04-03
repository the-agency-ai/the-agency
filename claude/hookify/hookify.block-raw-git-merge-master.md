---
name: block-raw-git-merge-master
enabled: true
event: bash
pattern: git merge (--\S+\s+)*(origin/)?master
action: warn
---

Use `/worktree-sync` instead of raw `git merge master`. See CLAUDE-THEAGENCY.md#worktrees--master — FEAR THE KITTENS!
