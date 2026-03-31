---
name: block-commit-main
enabled: true
event: bash
pattern: git commit
action: warn
---

**Use `./claude/tools/git-commit` instead of bare `git commit`.**

The commit tool enforces conventions (message format, work-item linking, stage tagging).

Also verify you are NOT on `main` or `master` — all changes go through PR branches. If you are on main/master, create a branch first:
```bash
git checkout -b {workstream}/{description}
```
