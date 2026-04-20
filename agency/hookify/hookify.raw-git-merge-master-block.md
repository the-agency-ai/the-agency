---
name: raw-git-merge-master-block
enabled: true
event: bash
pattern: git merge (--\S+\s+)*(origin/)?master
action: warn
---

Use `/worktree-sync` instead of raw `git merge master`. See claude/REFERENCE-WORKTREE-DISCIPLINE.md — FEAR THE KITTENS!
