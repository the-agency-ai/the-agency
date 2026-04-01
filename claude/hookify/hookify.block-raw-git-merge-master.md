---
name: block-raw-git-merge-master
enabled: true
event: bash
pattern: git merge (--\S+\s+)*(origin/)?master
action: warn
---

**Use `/worktree-sync` instead of raw `git merge master`.**

The worktree-sync tool handles the full sync: merge master, copy settings.json, run sandbox-sync, and report what changed. Raw `git merge master` skips all of that.

```
/worktree-sync
```

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
